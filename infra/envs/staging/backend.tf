terraform {
  backend "s3" {
    bucket         = "nn-devops-terraform-state-sofia"
    key            = "infra/envs/staging/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "nn-devops-terraform-lock-sofia"
  }
}
