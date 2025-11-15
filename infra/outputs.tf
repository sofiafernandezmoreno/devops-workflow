output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "URL of the ECR repository where images are pushed."
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "Name of the EKS cluster."
}

output "vpc_id" {
  value       = module.network.vpc_id
  description = "VPC ID used by the EKS cluster."
}

output "subnet_ids" {
  value       = module.network.subnet_ids
  description = "Subnet IDs used by the EKS cluster."
}
