resource "aws_eks_access_policy_association" "terraform_admin_cluster_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = var.admin_user_arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
