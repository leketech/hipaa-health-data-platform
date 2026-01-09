# Variables for logging module

variable "organization_name" {
  description = "Name of the organization"
  type        = string
  default     = "hipaa-health-data-platform"
}

variable "log_bucket_name" {
  description = "Name of the S3 bucket for logs"
  type        = string
}

variable "config_bucket_name" {
  description = "Name of the S3 bucket for AWS Config logs"
  type        = string
}

variable "config_sns_topic_arn" {
  description = "ARN of the SNS topic for AWS Config notifications"
  type        = string
}

variable "alert_sns_topic_arn" {
  description = "ARN of the SNS topic for alert notifications"
  type        = string
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "hipaa-eks-cluster"
}

variable "enable_guardduty_members" {
  description = "Enable GuardDuty member accounts"
  type        = bool
  default     = true
}

variable "log_bucket_account_id" {
  description = "Account ID of the log bucket"
  type        = string
}

variable "log_bucket_owner_email" {
  description = "Email of the log bucket owner"
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