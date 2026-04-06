# --- Production Environment Variables ---
# Senior DevOps practice: Separate state and config per environment

aws_region   = "us-east-1"
project_name = "titan-prod"
vpc_cidr     = "10.1.0.0/16"

# In production, we might use larger instances or different Spot prices
# instance_type = "t3.medium"
