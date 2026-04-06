# To enable Remote State (S3 + DynamoDB Locking), uncomment and configure below:
# This is a Senior/Lead DevOps standard to prevent state corruption.

/*
terraform {
  backend "s3" {
    bucket         = "project-titan-tfstate"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
*/
