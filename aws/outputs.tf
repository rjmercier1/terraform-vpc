# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.prod-vpc.id
}

# CIDR blocks
output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.prod-vpc.cidr_block
}
