# modules/vpc/outputs.tf

output "vpc_id" {
    description = "The VPC ID"
    value       = aws_vpc.main.id
}

output "public_subnet_ids" {
    description = "List of public subnet IDs"
    value       = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]
}

output "private_subnet_ids" {
    description = "List of private subnet IDs"
    value       = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]
}

output "nat_gateway_ids" {
    description = "NAT Gateway IDs"
    value       = [aws_nat_gateway.az1.id, aws_nat_gateway.az2.id]
}

output "alb_sg_id" {
    description = "ALB security group ID"
    value       = aws_security_group.alb.id
}

output "app_sg_id" {
    description = "App security group ID"
    value       = aws_security_group.app.id
}

output "rds_sg_id" {
    description = "RDS security group ID"
    value       = aws_security_group.rds.id
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "rds_secret_arn" {
  description = "ARN of the RDS credentials secret in Secrets Manager"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}

output "read_rds_secret_policy_arn" {
  description = "ARN of the IAM policy to read RDS secret"
  value       = aws_iam_policy.read_rds_secret.arn
}

