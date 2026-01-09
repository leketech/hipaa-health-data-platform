# Backend configuration for Terraform state management
# This should be configured separately in production with proper remote backend

# Example configuration for S3 backend with DynamoDB locking
/*
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "hipaa-health-data-platform/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
    kms_key_id     = "alias/your-kms-key-for-terraform-state"
  }
}
*/

# For initial setup and testing only
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}