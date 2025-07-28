// Root outputs.tf for helpful outputs
output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = module.load_balancer.alb_dns_name
}

output "rds_endpoint" {
  description = "The endpoint of the RDS instance."
  value       = module.database.rds_endpoint
}

output "ec2_ssh_command" {
  description = "SSH command to connect to the EC2 instance."
  value       = "ssh -i ${var.ssh_key_path} ubuntu@${module.compute.ec2_public_ip}"
} 