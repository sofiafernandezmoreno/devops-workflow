module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = "${var.project}-cluster"
  cluster_version = "1.30"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      desired_size  = 2
      min_size      = 1
      max_size      = 3
      instance_types = ["t3.small"]
    }
  }

  tags = {
    Project = var.project
  }
}
