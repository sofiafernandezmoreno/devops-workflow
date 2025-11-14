output "vpc_id" {
  value = var.use_default_vpc ? data.aws_vpc.default[0].id : aws_vpc.new[0].id
}

output "subnet_ids" {
  value = var.use_default_vpc ? data.aws_subnets.default[0].ids : aws_subnet.new[*].id
}
