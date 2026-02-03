#outputs
output "vpc_id" {
  value = aws_vpc.three_tier_vpc.id
}
output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "aws_subnet_db" {
  value = aws_subnet.db_subnets[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}

output "db_subnet_ids" {
  value = aws_subnet.db_subnets[*].id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.vpc_gateway.id
}
