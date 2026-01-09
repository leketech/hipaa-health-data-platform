# Variables for security module

variable "organization_name" {
  description = "Name of the organization"
  type        = string
  default     = "hipaa-health-data-platform"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "hipaa-health.example.com"
}

variable "subject_alternative_names" {
  description = "Subject alternative names for the SSL certificate"
  type        = list(string)
  default     = []
}

variable "kms_backup_key_arn" {
  description = "ARN of the KMS key to use for AWS Backup encryption"
  type        = string
}

variable "kms_secrets_key_arn" {
  description = "ARN of the KMS key to use for Secrets Manager encryption"
  type        = string
}

variable "kms_ssm_key_arn" {
  description = "ARN of the KMS key to use for SSM Parameter Store encryption"
  type        = string
}

variable "rds_instance_arn" {
  description = "ARN of the RDS instance to backup"
  type        = string
}

variable "eks_node_ebs_arns" {
  description = "ARNs of the EBS volumes for EKS nodes to backup"
  type        = list(string)
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

variable "install_gatekeeper" {
  description = "Install Gatekeeper for OPA policies"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID where security resources will be deployed"
  type        = string
}

variable "eks_node_security_group_id" {
  description = "Security group ID of the EKS nodes"
  type        = string
}

variable "db_username" {
  description = "Database username for secrets manager"
  type        = string
  default     = "healthadmin"
}

variable "db_password" {
  description = "Database password for secrets manager"
  type        = string
  sensitive   = true
}

variable "environment_config" {
  description = "Environment configuration map"
  type        = map(string)
  default     = {}
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