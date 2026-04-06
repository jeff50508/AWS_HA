variable "project_name" {
  type        = string
  description = "Project name"
}

variable "alb_arn" {
  type        = string
  description = "ARN of the Application Load Balancer to protect"
}
