environment = "prod"
project     = "acqua"
owner       = "your-prod-owner"
aws_region  = "us-east-1"
vpc_cidr    = "10.20.0.0/16"
public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
private_subnet_cidrs = ["10.20.101.0/24", "10.20.102.0/24"]
ec2_instance_type    = "t3.large"
rds_instance_class   = "db.t3.large"
rds_allocated_storage = 100
rds_backup_retention_period = 30
ssh_key_path = "../keys/prod-key.pem"
backend_bucket = "acqua-tfstate-bucket"
backend_region = "us-east-1"
backend_dynamodb_table = "acqua-tfstate-lock"

db_password = "your-prod-db-password-here"

# SSH and Port Configuration
enable_public_ssh = false  # Disable public SSH for production security
additional_ports = [3000, 3001, 3002, 3003, 3004, 3005, 3006, 3007, 3008, 3009, 3010]

// ... other prod-specific settings ... 