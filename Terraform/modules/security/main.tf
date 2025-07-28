resource "aws_security_group" "ec2" {
  name_prefix = "acqua-ec2-sg-${var.environment}"
  vpc_id      = var.vpc_id

  # Allow HTTP traffic from ALB
  ingress {
    protocol                 = "tcp"
    from_port                = 80
    to_port                  = 80
    security_group_ids       = [var.alb_security_group_id]
  }

  # Allow HTTPS traffic from ALB
  ingress {
    protocol                 = "tcp"
    from_port                = 443
    to_port                  = 443
    security_group_ids       = [var.alb_security_group_id]
  }

  # Allow additional ports from ALB (3000-3010)
  dynamic "ingress" {
    for_each = var.additional_ports
    content {
      protocol                 = "tcp"
      from_port                = ingress.value
      to_port                  = ingress.value
      security_group_ids       = [var.alb_security_group_id]
    }
  }

  # Allow SSH from VPC (always allowed)
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.vpc_cidr]
  }

  # Conditionally allow public SSH access
  dynamic "ingress" {
    for_each = var.enable_public_ssh ? [1] : []
    content {
      protocol    = "tcp"
      from_port   = 22
      to_port     = 22
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Allow all outbound traffic
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name        = "acqua-ec2-sg-${var.environment}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }, var.tags)
}

resource "aws_security_group" "rds" {
  name_prefix = "acqua-rds-sg-${var.environment}"
  vpc_id      = var.vpc_id

  # Allow PostgreSQL traffic from EC2 only
  ingress {
    protocol                 = "tcp"
    from_port                = 5432
    to_port                  = 5432
    security_group_ids       = [aws_security_group.ec2.id]
  }

  # No outbound rules (RDS doesn't need to initiate connections)

  tags = merge({
    Name        = "acqua-rds-sg-${var.environment}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }, var.tags)
} 