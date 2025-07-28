terraform {
  backend "s3" {
    bucket         = "acqua-tfstate-bucket"
    key            = "acqua-{environment}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "acqua-tfstate-lock"
    encrypt        = true
  }
} 