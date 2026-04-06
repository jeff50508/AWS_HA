# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# Get available AZs in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# 1. VPC Module
module "vpc" {
  source             = "./modules/vpc"
  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}

# 2. Security Module
module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

# 3. IAM Module (Senior Practice: Instance Identity & Least Privilege)
module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
}

# 4. Compute Module (ALB + ASG with Spot)
module "compute" {
  source               = "./modules/compute"
  project_name         = var.project_name
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  private_subnet_ids   = module.vpc.private_subnet_ids
  alb_sg_id            = module.security.alb_sg_id
  app_sg_id            = module.security.app_sg_id
  image_id             = data.aws_ami.amazon_linux.id
  instance_type        = "t3.micro"
  iam_instance_profile = module.iam.instance_profile_name
}

# 5. Kubernetes (EKS) Module (Senior Practice: Modern Scalable Infra)
# Note: EKS deployment is commented out by default as it incurs significant AWS costs (~$72/mo + nodes)
# But having this module shows you can handle K8s infrastructure.

/*
module "eks" {
  source             = "./modules/eks"
  project_name       = var.project_name
  private_subnet_ids = module.vpc.private_subnet_ids
}
*/

# 6. RDS Database Module (Senior Practice: Stateful Data Layer)
module "rds" {
  source             = "./modules/rds"
  project_name       = var.project_name
  private_subnet_ids = module.vpc.private_subnet_ids
  rds_sg_id          = module.security.rds_sg_id
}

# 7. Edge Security Module (Senior Practice: WAF)
module "waf" {
  source       = "./modules/waf"
  project_name = var.project_name
  alb_arn      = module.compute.alb_arn
}

# 8. Container Registry (ECR)
module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

# 9. Advanced Deployment Strategy (CodeDeploy)
module "codedeploy" {
  source            = "./modules/codedeploy"
  project_name      = var.project_name
  asg_name          = module.compute.asg_name
  target_group_name = module.compute.app_tg_name
}
