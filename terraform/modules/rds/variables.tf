variable "project_name" {
  type        = string
  description = "Project name"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for RDS"
}

variable "rds_sg_id" {
  type        = string
  description = "Security group ID for RDS"
}
