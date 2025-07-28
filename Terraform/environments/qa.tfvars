environment = "qa"
project     = "acqua"
owner       = "your-qa-owner"
aws_region  = "us-east-1"
vpc_cidr    = "10.10.0.0/16"
public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
private_subnet_cidrs = ["10.10.101.0/24", "10.10.102.0/24"]
ec2_instance_type    = "t3.micro"
rds_instance_class   = "db.t3.micro"
rds_allocated_storage = 20
rds_backup_retention_period = 7
ssh_key_path = "../keys/qa-key.pem"
backend_bucket = "acqua-tfstate-bucket"
backend_region = "us-east-1"
backend_dynamodb_table = "acqua-tfstate-lock"

db_password = "your-qa-db-password-here"

// ... other QA-specific settings ... 