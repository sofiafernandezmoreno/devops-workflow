terraform {
  backend "s3" {
    bucket         = "nn-devops-terraform-state"   # Nombre del bucket en AWS S3
    key            = "infra/terraform.tfstate"     # Ruta dentro del bucket
    region         = "eu-west-1"                   # Región del bucket
    encrypt        = true
    dynamodb_table = "nn-devops-terraform-lock"    # Para bloqueo concurrente
  }
}
