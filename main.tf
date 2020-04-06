#SG for LB
resource "aws_security_group" "sg-http" {
        name = "SG-LB-${var.APPLICATION_NAME}"
        description = "SG to allow HTTP Traffic"

        ingress {
                        from_port = 80
                        to_port = 80
                        protocol = "tcp"
                        cidr_blocks = ["0.0.0.0/0"]
        }

        egress {
                        from_port = 0
                        to_port = 0
                        protocol = "-1"
                        cidr_blocks = ["0.0.0.0/0"]
        }
}

#SG for EC2-SSH Traffic
resource "aws_security_group" "sg-ssh" {
        name = "SG-${var.APPLICATION_NAME}"
        description = "SG to allow SSH Traffic"

        ingress {
                        from_port = 22
                        to_port = 22
                        protocol = "tcp"
                        cidr_blocks = ["0.0.0.0/0"]
        }

                ingress {
                        from_port = 80
                        to_port = 80
                        protocol = "tcp"
                        security_groups = ["${aws_security_group.sg-http.id}"]
        }

        egress {
                        from_port = 0
                        to_port = 0
                        protocol = "-1"
                        cidr_blocks = ["0.0.0.0/0"]
        }
}

#SG for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Used for DB instances"

  # SQL access from web instance security group
  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    security_groups = ["${aws_security_group.sg-ssh.id}"]
  }
}

#Create DB Instance
resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "var.DB_DBNAME"
  username             = "var.DB_USERNAME"
  password             = "var.DB_PASSWORD"
  vpc_security_group_ids = ["${aws_security_group.rds_sg.id}"]
}

#Create EC2 Instance
resource "aws_instance" "webserver" {
  ami           = "${var.AMI_ID}"
  instance_type = "${var.WEB_INSTANCE_TYPE}"
  security_groups = ["${aws_security_group.sg-ssh.name}"]
  availability_zone = "${var.AVAILABILITY_ZONE}"
  key_name = "${var.WEB_INSTANCE_KEY}"
  tags = {
                        Name = "EC2-${var.APPLICATION_NAME}"
        }

  provisioner "local-exec" {
    command = <<EOD
        cat <<EOF > aws_hosts
        [Web]
        ${aws_instance.webserver.public_ip}
        [Web:vars]
        web_ip=${aws_instance.webserver.public_ip}
        EOF
                EOD
      }

  provisioner "local-exec" {
                command = "
				sed -i s/var_endpoint/${aws_db_instance.mysql.endpoint}/g timestamp.php
				sed -i s/var_user/${var.DB_USERNAME}/g timestamp.php
				sed -i s/var_dbpass/${DB_PASSWORD}/g timestamp.php
				sed -i s/var_dbname/${DB_DBNAME}/g timestamp.php
				"
}

  provisioner "local-exec" {
                command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.webserver.id} && ansible-playbook -i aws_hosts --private-key=test.pem nginx.yml"
}
}

#AWS AMI
resource "aws_ami_from_instance" "ami" {
  name               = "ami-${var.APPLICATION_NAME}"
  source_instance_id = "${aws_instance.webserver.id}"
}

#Launch Config
resource "aws_launch_configuration" "web_lc" {
  name_prefix          = "${var.APPLICATION_NAME}-launchconfig"
  image_id             = aws_ami_from_instance.ami.id
  instance_type        = var.WEB_INSTANCE_TYPE
  key_name             = var.WEB_INSTANCE_KEY
  security_groups      = [aws_security_group.sg-ssh.id]
  lifecycle {
    create_before_destroy = true
  }
}

#Auto-Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  name                 = "${var.APPLICATION_NAME}-autoscaling"
  vpc_zone_identifier  = split(",", var.VPC_SUBNETS)
  launch_configuration = aws_launch_configuration.web_lc.name
  min_size             = var.ASG_MINSIZE
  max_size             = var.ASG_MAXSIZE
  desired_capacity     = var.ASG_DESIRED_CAPACITY
  target_group_arns    = ["${aws_lb_target_group.tg.arn}"]
  depends_on            = [null_resource.tg_exists]
  tag {
    key                 = "Name"
    value               = "ASG-${var.APPLICATION_NAME}"
    propagate_at_launch = true
  }
}

#Null Resource
resource "null_resource" "tg_exists" {
  triggers = {
    alb_name = aws_lb_target_group.tg.name
  }
}

#ALB
resource "aws_lb" "alb" {
  name            = "ALB-${var.APPLICATION_NAME}"
  internal        = var.INTERNAL
  load_balancer_type = "application"
  security_groups = [aws_security_group.sg-http.id]
  subnets         = split(",", var.VPC_SUBNETS)

  enable_deletion_protection = false
}

# ALB Listener
resource "aws_lb_listener" "alb-http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}

#Target Group
resource "aws_lb_target_group" "tg" {
  name     = "TG-${var.APPLICATION_NAME}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.VPC_ID
}

#Target Group Attachment
resource "aws_lb_target_group_attachment" "alb_tg" {
  target_group_arn = "${aws_lb_target_group.tg.arn}"
  target_id        = "${aws_instance.webserver.id}"
  port             = 80
}
