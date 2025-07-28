# Root main.tf for orchestrating all modules

# Networking module
module "networking" {
  source = "./modules/VPC"
  
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  project              = var.project
  environment          = var.environment
  tags = {
    Owner = var.owner
  }
}

# Security groups module
module "security" {
  source = "./modules/security"
  
  project                = var.project
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  vpc_cidr              = var.vpc_cidr
  alb_security_group_id = module.load_balancer.alb_security_group_id
  enable_public_ssh     = var.enable_public_ssh
  additional_ports      = var.additional_ports
  tags = {
    Owner = var.owner
  }
}

# IAM module
module "iam" {
  source = "./modules/IAM"
  
  project       = var.project
  environment   = var.environment
  ec2_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
  tags = {
    Owner = var.owner
  }
}

# Load balancer module
module "load_balancer" {
  source = "./modules/ALB"
  
  project     = var.project
  environment = var.environment
  vpc_id      = module.networking.vpc_id
  subnet_ids  = module.networking.public_subnet_ids
  additional_ports = var.additional_ports
  tags = {
    Owner = var.owner
  }
}

# Compute module
module "compute" {
  source = "./modules/EC2"
  
  instance_type        = var.ec2_instance_type
  subnet_id            = module.networking.public_subnet_ids[0]
  key_name             = "acqua-key-${var.environment}"
  iam_instance_profile = module.iam.instance_profile_name
  security_group_id    = module.security.ec2_security_group_id
  environment          = var.environment
  project              = var.project
  owner                = var.owner
  ebs_volume_size      = 200
  user_data            = file("${path.module}/scripts/user-data.sh")
}

# Database module
module "database" {
  source = "./modules/RDS"
  
  project                = var.project
  environment           = var.environment
  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  backup_retention_period = var.rds_backup_retention_period
  db_name               = "acquadb"
  db_username           = "admin"
  db_password           = var.db_password
  db_subnet_group_name  = module.networking.db_subnet_group
  vpc_security_group_ids = [module.security.rds_security_group_id]
  deletion_protection   = var.environment == "prod" ? true : false
  tags = {
    Owner = var.owner
  }
}

# Attach EC2 to ALB target group
resource "aws_lb_target_group_attachment" "ec2" {
  target_group_arn = module.load_balancer.target_group_arn
  target_id        = module.compute.ec2_instance_id
  port             = 80
} 