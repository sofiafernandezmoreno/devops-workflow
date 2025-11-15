variable "project" {
  type        = string
  description = "Base project name."
}

variable "aws_region" {
  type        = string
  description = "AWS region."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs."
}

variable "admin_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to access the EKS public endpoint."
}
