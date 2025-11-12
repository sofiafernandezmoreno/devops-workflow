output "vpc_id" {
  value = module.network.vpc_id
}

output "subnet_ids" {
  value = module.network.subnet_ids
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "aws_account_id" {
  value = module.iam.aws_account_id
}

output "azdo_access_key_id" {
  value     = module.iam.azdo_access_key_id
  sensitive = true
}

output "azdo_secret_access_key" {
  value     = module.iam.azdo_secret_access_key
  sensitive = true
}
