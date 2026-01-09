# Variables for Backup and Disaster Recovery Module

variable "organization_name" {
  description = "Name of the organization"
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

variable "kms_backup_key_arn" {
  description = "ARN of the KMS key for backup encryption"
  type        = string
}

variable "backup_role_arn" {
  description = "ARN of the IAM role for backup operations"
  type        = string
}

variable "rds_instance_arn" {
  description = "ARN of the RDS instance to backup"
  type        = string
}

variable "ebs_volume_arns" {
  description = "List of ARNs for EBS volumes to backup"
  type        = list(string)
  default     = []
}

variable "efs_file_system_arn" {
  description = "ARN of the EFS file system to backup"
  type        = string
}

variable "enable_cross_region_replication" {
  description = "Enable cross-region replication for S3 buckets"
  type        = bool
  default     = false
}

variable "source_bucket_id" {
  description = "ID of the source S3 bucket"
  type        = string
}

variable "dr_bucket_arn" {
  description = "ARN of the DR S3 bucket"
  type        = string
}

variable "replication_role_arn" {
  description = "ARN of the IAM role for S3 replication"
  type        = string
}

variable "create_read_replica" {
  description = "Whether to create RDS read replica for DR"
  type        = bool
  default     = false
}

variable "primary_rds_instance_id" {
  description = "Identifier of the primary RDS instance"
  type        = string
}

variable "secondary_region" {
  description = "Secondary region for disaster recovery"
  type        = string
  default     = "us-west-2"
}

variable "dr_db_subnet_group_name" {
  description = "Name of the DB subnet group in the DR region"
  type        = string
}

variable "create_dr_bucket" {
  description = "Whether to create DR S3 bucket"
  type        = bool
  default     = false
}

variable "kms_s3_key_arn" {
  description = "ARN of the KMS key for S3 encryption"
  type        = string
}

variable "alert_sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  type        = string
}