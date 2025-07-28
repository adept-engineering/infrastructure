output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance."
  value       = aws_instance.this.public_ip
}

output "ebs_volume_id" {
  description = "ID of the attached EBS volume."
  value       = aws_ebs_volume.data.id
}
