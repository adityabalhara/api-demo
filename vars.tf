variable "AWS_ACCESS_KEY"  {
}
variable "AWS_SECRET_KEY"  {
}
variable "AWS_REGION"  {
        default = "us-west-2"
}
variable "WEB_INSTANCE_KEY" {
        default = "test"
}
variable "AMI_ID" {
        default = "ami-087c2c50437d0b80d"
}
variable "WEB_INSTANCE_TYPE" {
        default = "t2.micro"
}
variable "AVAILABILITY_ZONE" {
        default = "us-west-2b"
}
variable "APPLICATION_NAME" {
        default = "Demo"
}
variable "ASG_MINSIZE" {
        default = "1"
}
variable "ASG_MAXSIZE" {
        default = "1"
}
variable "ASG_DESIRED_CAPACITY" {
        default = "1"
}
variable "INTERNAL" {
        default = "false"
}
variable "VPC_SUBNETS" {
        default = "subnet-0bfc2c50,subnet-49dfe92e,subnet-825811cb"
}
variable "VPC_ID" {
        default = "vpc-2bef0a4d"
}
variable "DB_USERNAME" {
}
variable "DB_PASSWORD" {
}
variable "DB_DBNAME" {
}