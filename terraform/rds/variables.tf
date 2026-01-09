# Variables for RDS module

variable "organization_name" {
  description = "Name of the organization"
  type        = string
  default     = "hipaa-health-data-platform"
}

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

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "hipaa_health_db"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "healthadmin"
}

variable "db_password" {
  description = "Master password for the database (should be provided via secure method)"
  type        = string
  sensitive   = true
}

variable "kms_rds_key_arn" {
  description = "ARN of the KMS key to use for RDS encryption"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the RDS instance will be deployed"
  type        = string
}

variable "eks_security_group_id" {
  description = "Security group ID of the EKS cluster"
  type        = string
}

variable "alert_sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  type        = string
}

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