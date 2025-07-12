output "web_public_ips" {
  description = "Public IP addresses of web servers"
  value       = module.compute.web_public_ips
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "alb_dns_name" {
  value = module.loadbalancer.alb_dns_name
}
