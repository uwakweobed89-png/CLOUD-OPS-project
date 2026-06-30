# modules/vpc/main.tf

terraform {
    required_providers {
    aws = {
    source  = "hashicorp/aws"
    version = "~> 5.0"
    }
}
}



resource "aws_vpc" "main" {
    cidr_block           = var.vpc_cidr
    enable_dns_support   = true
    enable_dns_hostnames = true

tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    }
}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
    Name = "${var.project_name}-igw"
    }
}

