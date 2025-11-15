# If use_default_vpc = true → fetch default VPC
data "aws_vpc" "default" {
  default = true
  count   = var.use_default_vpc ? 1 : 0
}

data "aws_subnets" "default" {
  count = var.use_default_vpc ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

# If use_default_vpc = false → create a new VPC
resource "aws_vpc" "new" {
  count                = var.use_default_vpc ? 0 : 1
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Project = var.project }
}

resource "aws_subnet" "new" {
  count      = var.use_default_vpc ? 0 : 2
  vpc_id     = aws_vpc.new[0].id
  cidr_block = cidrsubnet(aws_vpc.new[0].cidr_block, 4, count.index)
  tags       = { Project = var.project }
}
