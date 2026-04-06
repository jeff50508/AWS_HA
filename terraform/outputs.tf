output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.compute.alb_dns_name
}

output "vpc_id" {
  description = "VPC ID for this project"
  value       = module.vpc.vpc_id
}

output "repository_url" {
  description = "ECR Repository URL"
  value       = module.ecr.repository_url
}
