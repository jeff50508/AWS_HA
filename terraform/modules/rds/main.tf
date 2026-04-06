# DB Subnet Group (Private placement)
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# Generate a strong random password
resource "random_password" "master" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project_name}-db-secret" # Convention-based name for app access
  description             = "Master password for RDS instance"
  recovery_window_in_days = 0 # Force delete for demo purposes
}

resource "aws_secretsmanager_secret_version" "db_password_val" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.master.result
    host     = aws_db_instance.main.endpoint
  })
}

# RDS Instance (MySQL)
resource "aws_db_instance" "main" {
  identifier           = "${var.project_name}-db"
  allocated_storage    = 20
  storage_type         = "gp3"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_name              = "titandb"
  username             = "admin"
  password             = random_password.master.result
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true # Set to false in production

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]

  # Make it private
  publicly_accessible = false
  multi_az            = false # Set to true for production, false to save costs for demo

  tags = {
    Name = "${var.project_name}-rds"
  }
}
