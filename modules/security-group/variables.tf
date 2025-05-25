# modules/security-group/variables.tf
variable "name" {
  description = "The name of the security group."
  type        = string
}
variable "description" {
  description = "A description for the security group."
  type        = string
  default     = "Managed by Terraform"
}
variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}
variable "ingress_rules" {
  description = "List of ingress rules."
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
  }))
  default = []
}
variable "egress_rules" {
  description = "List of egress rules."
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string))
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
variable "project_name" {
  description = "Project name for tagging."
  type        = string
}