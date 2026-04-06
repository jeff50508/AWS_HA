# CodeDeploy Service Role
resource "aws_iam_role" "codedeploy_service" {
  name = "${var.project_name}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_service" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy_service.name
}

# CodeDeploy Application
resource "aws_codedeploy_app" "main" {
  compute_platform = "Server"
  name             = "${var.project_name}-app"
}

# CodeDeploy Deployment Group targeting the ASG
resource "aws_codedeploy_deployment_group" "main" {
  app_name              = aws_codedeploy_app.main.name
  deployment_group_name = "${var.project_name}-dg"
  service_role_arn      = aws_iam_role.codedeploy_service.arn

  autoscaling_groups = [var.asg_name]

  # Configuration for typical rolling update / in-place deployment on EC2
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  # We could do Blue/Green here but sticking to In-Place with ASG for simpler demonstration of Advanced Deployment
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  load_balancer_info {
    target_group_info {
      name = var.target_group_name
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}
