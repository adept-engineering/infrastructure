environment = "qa"
project     = "Acqua"
owner       = "Acqua-Team"
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

db_password = "AcquaAdminPwd"

# SSH and Port Configuration
enable_public_ssh = true
additional_ports = [3000, 3001, 3002, 3003, 3004, 3005, 3006, 3007, 3008, 3009, 3010]

// ... other QA-specific settings ... 