variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "project-titan"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
