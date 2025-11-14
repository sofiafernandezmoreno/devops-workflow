terraform {
  backend "s3" {
    bucket         = "nn-devops-terraform-sofia"
    key            = "infra/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "nn-devops-terraform-lock-sofia"
  }
}
