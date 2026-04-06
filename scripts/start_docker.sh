#!/bin/bash
set -e

# Retrieve metadata dynamically via IMDSv2 (Required for AL2023)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//')
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PROJECT_NAME="${PROJECT_NAME:-titan-prod}" # Should match prod.tfvars
REPO_NAME="${PROJECT_NAME}-app"
IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:latest"

echo "Logging into ECR in region ${REGION}..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

echo "Pulling latest image..."
docker pull $IMAGE_URI

echo "Stopping existing containers..."
if [ "$(docker ps -q -f name=titan-app)" ]; then
    docker stop titan-app
    docker rm titan-app
fi

echo "Starting new container..."
docker run -d --name titan-app \
    --restart always \
    -p 8000:8000 \
    -p 8001:8001 \
    -e AWS_REGION=$REGION \
    -e DB_SECRET_NAME="${PROJECT_NAME}-db-secret" \
    $IMAGE_URI

echo "Deployment successful."
