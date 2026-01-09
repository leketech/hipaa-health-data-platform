# Terraform configuration for HIPAA-compliant health data platform

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Backend configuration - this would typically be configured separately
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "global/s3/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.primary_region

  default_tags {
    tags = var.tags
  }

  # Ensure all resources comply with HIPAA requirements
  ignore_tags = [
    "aws:ec2:image/*",
    "aws:ecs:cluster/*",
    "aws:eks:cluster/*",
  ]
}

# Provider for secondary region (for disaster recovery)
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region

  default_tags {
    tags = var.tags
  }
}