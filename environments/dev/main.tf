# environments/dev/main.tf
# environments/dev/main.tf

terraform {
    required_providers {
    aws = {
    source  = "hashicorp/aws"
    version = "~> 5.0"
    }
    }
}

provider "aws" {
    region = var.aws_region
}

module "vpc" {
    source       = "../../modules/vpc"
    project_name = var.project_name
    environment  = var.environment
    aws_region   = var.aws_region
    vpc_cidr     = var.vpc_cidr
} 

