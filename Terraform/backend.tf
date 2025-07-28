terraform {
  backend "s3" {
    bucket         = var.backend_bucket
    key            = "acqua-${var.environment}/terraform.tfstate"
    region         = var.backend_region
    dynamodb_table = var.backend_dynamodb_table
    encrypt        = true
    versioning     = true
  }
} 