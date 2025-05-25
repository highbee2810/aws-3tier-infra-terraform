# 3-tier-infra-aws/variables.tf
variable "aws_region" {
  description = "The AWS region where resources will be deployed."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "A tag value for the project name."
  type        = string
  default     = "3-Tier-App"
}

# VPC variables
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"] # Example for 2 AZs
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"] # Example for 2 AZs
}

variable "database_subnet_cidrs" { # For RDS or dedicated DB subnets
  description = "List of CIDR blocks for database subnets."
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24"] # Example for 2 AZs
}

# EC2 variables (common across tiers)
variable "ami_id" {
  description = "AMI ID for EC2 instances."
  type        = string
  default     = "ami-084568db4383264d4" 
}

variable "instance_type_web" {
  description = "EC2 instance type for the web tier."
  type        = string
  default     = "t2.micro"
}

variable "instance_type_app" {
  description = "EC2 instance type for the application tier."
  type        = string
  default     = "t2.micro"
}

variable "instance_type_db" {
  description = "EC2 instance type for the database tier (if using EC2)."
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Name of the EC2 Key Pair for SSH access."
  type        = string
  default     = "Aremu" 
}