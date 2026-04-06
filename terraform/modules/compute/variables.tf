variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ASG"
  type        = list(string)
}

variable "app_sg_id" {
  description = "Security group ID for the application instances"
  type        = string
}

variable "alb_sg_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "instance_type" {
  description = "Instance type (t3.micro for free tier)"
  type        = string
  default     = "t3.micro"
}

variable "image_id" {
  description = "AMI ID (Amazon Linux 2023)"
  type        = string
}

variable "app_port" {
  description = "App port"
  type        = number
  default     = 8000
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
}
