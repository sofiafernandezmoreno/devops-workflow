terraform {
  required_version = ">= 1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

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
  source     = "./modules/eks"
  project    = var.project
  aws_region = var.aws_region
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.subnet_ids
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
