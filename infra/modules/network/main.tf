data "aws_vpc" "default" {
  count   = var.use_default_vpc ? 1 : 0
  default = true
}

data "aws_subnets" "default" {
  count = var.use_default_vpc ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

module "vpc" {
  count   = var.use_default_vpc ? 0 : 1
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.5"

  name = "${var.project}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

locals {
  vpc_id     = var.use_default_vpc ? data.aws_vpc.default[0].id : module.vpc[0].vpc_id
  subnet_ids = var.use_default_vpc ? data.aws_subnets.default[0].ids : module.vpc[0].private_subnets
}
