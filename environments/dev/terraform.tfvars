# environments/dev/terraform.tfvars

project_name = "myapp"
environment  = "dev"
aws_region   = "us-east-1"
vpc_cidr     = "10.0.0.0/16"

# Never put AWS keys here!
# Set in terminal instead:
# export AWS_ACCESS_KEY_ID=xxxx
# export AWS_SECRET_ACCESS_KEY=xxxx

# RDS master password
db_password = "CloudOps2026!Secure"
