output "repository_url" {
  value       = aws_ecr_repository.springboot.repository_url
  description = "ECR repository URL"
}
