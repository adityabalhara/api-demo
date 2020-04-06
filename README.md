# api-demo

Pre-requisites
Below packages must be configured to execute this project:
- Terraform
- Ansible

Execution Process
Update VPC and subnet details in vars.tf file respective to your aws environment and run below commands:
terraform init
terraform plan
terraform apply

Once Infrastructre is created, use ALB URL to make an api request as below:
curl http://<ALB_URL>/timestamp.php

This will return the Timestamp and insert same to mysql database.
