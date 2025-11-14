resource "aws_ecr_repository" "springboot" {
  name = var.ecr_repo

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "IMMUTABLE"

  tags = {
    Project = var.project
  }
}
