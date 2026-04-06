output "rds_endpoint" {
  value       = aws_db_instance.main.endpoint
  description = "RDS instance endpoint"
}

output "db_secret_arn" {
  value       = aws_secretsmanager_secret.db_password.arn
  description = "ARN of the Secrets Manager secret for DB password"
}
