# -------------------------
# MODULE: NETWORK
# -------------------------
module "network" {
  source          = "./modules/network"
  project         = var.project
  aws_region      = var.aws_region
  use_default_vpc = var.use_default_vpc
}

# -------------------------
# MODULE: EKS
# -------------------------
module "eks" {
  source      = "./modules/eks"
  project     = var.project
  aws_region  = var.aws_region
  vpc_id      = module.network.vpc_id
  subnet_ids  = module.network.subnet_ids
  admin_cidrs = var.admin_cidrs
}

# -------------------------
# MODULE: ECR
# -------------------------
module "ecr" {
  source   = "./modules/ecr"
  project  = var.project
  ecr_repo = var.ecr_repo
}

# -------------------------
# MODULE: IAM
# -------------------------
module "iam" {
  source  = "./modules/iam"
  project = var.project
}
