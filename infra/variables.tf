variable "project" {
  type        = string
  description = "Project name for tagging and naming"
  default     = "nn-devops-challenge"
}

variable "aws_region" {
  type        = string
  description = "AWS region for the deployment"
  default     = "eu-west-1"
}

variable "use_default_vpc" {
  type        = bool
  description = "Use AWS default VPC instead of creating a new one"
  default     = true
}

variable "ecr_repo" {
  type        = string
  description = "Name of the ECR repository"
  default     = "nn-devops-challenge"
}

variable "admin_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to access the EKS public endpoint."
}