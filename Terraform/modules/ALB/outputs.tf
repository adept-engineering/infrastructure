output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the Application Load Balancer."
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "The ARN of the target group."
  value       = aws_lb_target_group.this.arn
}

output "target_group_name" {
  description = "The name of the target group."
  value       = aws_lb_target_group.this.name
}

output "http_listener_arn" {
  description = "The ARN of the HTTP listener."
  value       = aws_lb_listener.http.arn
}

output "alb_security_group_id" {
  description = "ID of the ALB security group."
  value       = aws_security_group.alb.id
} 