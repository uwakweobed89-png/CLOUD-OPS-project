# environments/prod/terraform.tfvars

project_name = "myapp"
environment  = "prod"
aws_region   = "us-east-1"
vpc_cidr     = "10.1.0.0/16"

# Different CIDR from dev (10.0.x.x)
# so both VPCs can be peered later
# without IP conflicts
