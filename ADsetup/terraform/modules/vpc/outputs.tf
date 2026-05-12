output "id" {
  description = "The VPC ID."
  value       = aws_vpc.ad.id
}

output "public_subnet_id" {
  description = "The public subnet ID of the VPC."
  value       = aws_subnet.main.id
}

output "main_internet_gateway_id" {
  description = "The main internet gateway ID."
  value       = aws_internet_gateway.ad.id
}

