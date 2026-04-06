resource "aws_iam_role" "app_role" {
  name = "${var.project_name}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# --- Custom Policy for Secrets Manager (Least Privilege) ---
resource "aws_iam_policy" "secrets_policy" {
  name        = "${var.project_name}-secrets-policy"
  description = "Allow app to read specific secrets and identify self"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = "*" # In prod, specify the exact ARN
      },
      {
        Action = [
          "sts:GetCallerIdentity"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_attach" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# --- Least Privilege for CodeDeploy Agent ---
# The agent only needs S3 read access to download the deployment bundle.
# Providing the full AmazonEC2RoleforAWSCodeDeploy here would give the EC2 instance
# overly broad permissions to manage ASGs (violating least privilege).
resource "aws_iam_role_policy_attachment" "codedeploy_agent_s3" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.app_role.name
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.app_profile.name
}
