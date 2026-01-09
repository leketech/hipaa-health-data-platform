# Variables for S3 module

variable "s3_phidata_bucket_name" {
  description = "Name for the S3 bucket storing PHI data"
  type        = string
  default     = "hipaa-phidata-storage"
}

variable "organization_name" {
  description = "Name of the organization"
  type        = string
  default     = "hipaa-health-data-platform"
}

variable "kms_s3_key_arn" {
  description = "ARN of the KMS key to use for S3 encryption"
  type        = string
}

variable "enable_cross_region_replication" {
  description = "Enable cross-region replication for disaster recovery"
  type        = bool
  default     = true
}

variable "secondary_region" {
  description = "Secondary AWS region for disaster recovery"
  type        = string
  default     = "us-west-2"
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