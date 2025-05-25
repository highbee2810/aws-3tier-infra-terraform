# 3-tier-infra-aws/outputs.tf
output "vpc_id" {
  description = "The ID of the created VPC."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.network.public_subnet_ids
}

output "web_tier_public_ips" {
  description = "Public IPs of the web tier instances."
  value       = aws_instance.web_tier[*].public_ip 
}