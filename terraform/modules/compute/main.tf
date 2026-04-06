resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "${var.project_name}-app-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-app-tg"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Launch Template with Spot Instance Configuration
resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = var.image_id
  instance_type = var.instance_type

  # IAM Instance Profile (Least Privilege)
  iam_instance_profile {
    name = var.iam_instance_profile
  }

  # Security Groups
  vpc_security_group_ids = [var.app_sg_id]

  # --- IMDSv2 for Docker ---
  # We must increase the hop limit to 2, otherwise containers on the docker bridge
  # cannot reach the metadata service (169.254.169.254) to assume the IAM role!
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Enforce IMDSv2
    http_put_response_hop_limit = 2          # Allow 1 hop for docker bridge
  }

  # Instance Market Options (Spot)
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = "0.01" # Set to low price for demo, or leave empty for market price
    }
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker ruby wget
              systemctl start docker
              systemctl enable docker
              
              # --- CodeDeploy Agent Installation (AL2023) ---
              # This is required for the CI/CD pipeline hooks (appspec.yml) to work.
              # We fetch the installer based on the current region.
              TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//')
              
              cd /home/ec2-user
              wget https://aws-codedeploy-$REGION.s3.$REGION.amazonaws.com/latest/install
              chmod +x ./install
              ./install auto
              systemctl start codedeploy-agent
              systemctl enable codedeploy-agent
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-instance"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.app_tg.arn]
  max_size            = 3
  min_size            = 1
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg"
    propagate_at_launch = true
  }
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "alb_arn" {
  value = aws_lb.alb.arn
}

output "asg_name" {
  value = aws_autoscaling_group.app_asg.name
}

output "app_tg_name" {
  value = aws_lb_target_group.app_tg.name
}
