variable "project_name" {
  type        = string
  description = "Project name"
}

variable "asg_name" {
  type        = string
  description = "Name of the Auto Scaling Group"
}

variable "target_group_name" {
  type        = string
  description = "Name of the Target Group"
}
