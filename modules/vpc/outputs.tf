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
