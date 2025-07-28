resource "aws_db_instance" "this" {
  identifier = "acqua-rds-${var.environment}"
  
  engine         = "postgres"
  engine_version = "14.10"
  instance_class = var.instance_class
  
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2
  storage_type          = "gp2"
  storage_encrypted     = true
  
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  
  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  deletion_protection = var.deletion_protection
  skip_final_snapshot = false
  final_snapshot_identifier = "acqua-rds-${var.environment}-final-snapshot"
  
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  
  tags = merge({
    Name        = "acqua-rds-${var.environment}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }, var.tags)
}

resource "aws_iam_role" "rds_monitoring" {
  name = "acqua-rds-monitoring-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_assume_role.json
  tags = merge({
    Name        = "acqua-rds-monitoring-role-${var.environment}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }, var.tags)
}

data "aws_iam_policy_document" "rds_monitoring_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
} 