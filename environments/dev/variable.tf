# environments/dev/variables.tf

variable "aws_region" {
    description = "AWS region"
    type        = string
    default     = "us-east-1"
}

variable "project_name" {
    description = "Prefix for all resource names"
    type        = string
}

variable "environment" {
    description = "dev | staging | prod"
    type        = string
}

variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type        = string
    default     = "10.0.0.0/16"
}
