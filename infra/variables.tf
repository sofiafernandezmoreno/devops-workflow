variable "aws_region" {
  description = "AWS region"
  default     = "eu-west-1"
}

variable "project" {
  description = "Project name prefix"
  default     = "nn-devops"
}

variable "ecr_repo" {
  description = "ECR repository name"
  default     = "springboot-app"
}

variable "use_default_vpc" {
  description = "If true, reuse AWS default VPC (recommended for free-tier)"
  type        = bool
  default     = true
}
