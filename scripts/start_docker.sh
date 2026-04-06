#!/bin/bash
set -e

# Configuration
REGION="us-east-1"
# Retrieve account ID dynamically (Requires instance profile with EC2 metadata/STS access or just parse from arbitrary ECR URL)
# For this demo, we assume the pipeline updates this script or sets an env var.
# Let's use AWS CLI to get the account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPO_NAME="titan-app"
IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:latest"

echo "Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

echo "Pulling latest image..."
docker pull $IMAGE_URI

echo "Stopping existing containers..."
if [ "$(docker ps -q -f name=titan-app)" ]; then
    docker stop titan-app
    docker rm titan-app
fi

echo "Starting new container..."
docker run -d --name titan-app --restart always -p 8000:8000 -p 8001:8001 $IMAGE_URI

echo "Deployment successful."
