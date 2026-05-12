# environments/dev/main.tf


terraform {
    backend "s3" {
    bucket         = "myapp-terraform-state-326709068429"
    key            = "dev/vpc/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile   = true
    encrypt        = true
    }
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

