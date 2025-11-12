resource "aws_ecr_repository" "springboot" {
  name = var.ecr_repo
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Project = var.project
  }
}
