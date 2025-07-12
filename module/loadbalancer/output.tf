
output "security_group_id" {
  value = aws_security_group.alb_sg.id
}

output "target_group_arns" {
  value = {
    homepage = aws_lb_target_group.tg_homepage.arn
  }
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}
