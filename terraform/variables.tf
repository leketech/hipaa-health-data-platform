# Global variables for HIPAA-compliant health data platform

# AWS Region configuration
variable "primary_region" {
  description = "Primary AWS region for the deployment"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region for disaster recovery"
  type        = string
  default     = "us-west-2"
}

# Account configuration
variable "organization_name" {
  description = "Name of the AWS organization"
  type        = string
  default     = "hipaa-health-data-platform"
}

variable "security_account_email" {
  description = "Email for the security account"
  type        = string
  default     = "security@hipaa-health-data-platform.com"
}

variable "shared_services_account_email" {
  description = "Email for the shared services account"
  type        = string
  default     = "shared@hipaa-health-data-platform.com"
}

variable "prod_account_email" {
  description = "Email for the production account"
  type        = string
  default     = "prod@hipaa-health-data-platform.com"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# EKS Configuration
variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "hipaa-eks-cluster"
}

variable "eks_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.28"
}

variable "eks_worker_instance_type" {
  description = "Instance type for EKS worker nodes"
  type        = string
  default     = "m5.large"
}

variable "eks_min_size" {
  description = "Minimum size of EKS node group"
  type        = number
  default     = 3
}

variable "eks_max_size" {
  description = "Maximum size of EKS node group"
  type        = number
  default     = 10
}

# RDS Configuration
variable "rds_instance_class" {
  description = "Instance class for RDS PostgreSQL"
  type        = string
  default     = "db.t3.medium"
}

variable "rds_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 100
}

variable "rds_storage_encrypted" {
  description = "Enable storage encryption for RDS"
  type        = bool
  default     = true
}

# S3 Configuration
variable "s3_phidata_bucket_name" {
  description = "Name for the S3 bucket storing PHI data"
  type        = string
  default     = "hipaa-phidata-storage"
}

variable "enable_cross_region_replication" {
  description = "Enable cross-region replication for disaster recovery"    
  type        = bool
  default     = false  # Set to false to avoid secondary provider issues in
                       # basic setup
}

# Database Password
variable "db_password" {
  description = "Password for the RDS database"
  type        = string
  sensitive   = true
}

# Cognito Configuration
variable "cognito_user_pool_name" {
  description = "Name for the Cognito user pool"
  type        = string
  default     = "hipaa-health-user-pool"
}

variable "cognito_app_client_name" {
  description = "Name for the Cognito app client"
  type        = string
  default     = "hipaa-health-app-client"
}

variable "cognito_external_id" {
  description = "External ID for Cognito identity providers"
  type        = string
  default     = "hipaa-health-external-id"
}

# Tags for resources
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "hipaa-health-data-platform"
    Environment = "prod"
    Compliance  = "HIPAA"
    Owner       = "Healthcare Team"
  }
}