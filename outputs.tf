
output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "rds" {
  value = aws_db_instance.primary.endpoint
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "private_app_subnets" {
  value = aws_subnet.app[*].id
}

output "private_db_subnets" {
  value = aws_subnet.db[*].id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.nat[*].id
}
