output "rds_endpoint" {
  description = "The endpoint of the RDS instance."
  value       = aws_db_instance.this.endpoint
}

output "rds_port" {
  description = "The port of the RDS instance."
  value       = aws_db_instance.this.port
}

output "rds_connection_string" {
  description = "PostgreSQL connection string."
  value       = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.this.endpoint}:${aws_db_instance.this.port}/${var.db_name}"
  sensitive   = true
} 