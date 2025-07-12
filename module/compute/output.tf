output "instance_a_id" {
  value = aws_instance.web[*].id
}

output "web_public_ips" {
  value = aws_instance.web[*].public_ip
}
