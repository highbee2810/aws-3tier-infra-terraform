# modules/security-group/outputs.tf
output "id" {
  description = "The ID of the security group."
  value       = aws_security_group.this.id
}