# modules/vpc/variables.tf
variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
}
variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
}
variable "database_subnet_cidrs" {
  description = "List of CIDR blocks for database subnets."
  type        = list(string)
}
variable "project_name" {
  description = "Project name for tagging."
  type        = string
}
variable "aws_region" {
  description = "The AWS region where resources will be deployed."
  type        = string
}