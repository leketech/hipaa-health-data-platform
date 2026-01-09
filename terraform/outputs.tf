# Outputs for HIPAA-compliant health data platform

# Account Setup Outputs
output "organization_id" {
  description = "ID of the AWS organization"
  value       = module.account_setup.organization_id
}

output "security_account_id" {
  description = "ID of the security account"
  value       = module.account_setup.security_account_id
}

output "shared_services_account_id" {
  description = "ID of the shared services account"
  value       = module.account_setup.shared_services_account_id
}

output "prod_account_id" {
  description = "ID of the production account"
  value       = module.account_setup.prod_account_id
}

# KMS Outputs
output "kms_rds_key_arn" {
  description = "ARN of the KMS key for RDS encryption"
  value       = module.kms.rds_key_arn
}

output "kms_s3_key_arn" {
  description = "ARN of the KMS key for S3 encryption"
  value       = module.kms.s3_key_arn
}

output "kms_ebs_key_arn" {
  description = "ARN of the KMS key for EBS encryption"
  value       = module.kms.ebs_key_arn
}

output "kms_secrets_key_arn" {
  description = "ARN of the KMS key for Secrets Manager encryption"
  value       = module.kms.secrets_key_arn
}

output "kms_backup_key_arn" {
  description = "ARN of the KMS key for backup encryption"
  value       = module.kms.backup_key_arn
}

# Networking Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "vpc_security_group_id" {
  description = "ID of the VPC security group"
  value       = module.networking.default_security_group_id
}

output "vpc_endpoint_sg_id" {
  description = "ID of the VPC endpoint security group"
  value       = module.networking.vpc_endpoint_sg_id
}

# Identity Outputs
output "cognito_user_pool_id" {
  description = "ID of the Cognito user pool"
  value       = module.identity.user_pool_id
}

output "cognito_user_pool_arn" {
  description = "ARN of the Cognito user pool"
  value       = module.identity.user_pool_arn
}

output "cognito_app_client_id" {
  description = "ID of the Cognito app client"
  value       = module.identity.app_client_id
}

output "cognito_app_client_secret" {
  description = "Secret of the Cognito app client"
  value       = module.identity.app_client_secret
  sensitive   = true
}

# S3 Outputs
output "phidata_bucket_id" {
  description = "ID of the PHI data S3 bucket"
  value       = module.s3.phidata_bucket_id
}

output "phidata_bucket_arn" {
  description = "ARN of the PHI data S3 bucket"
  value       = module.s3.phidata_bucket_arn
}

output "phidata_bucket_domain" {
  description = "Domain of the PHI data S3 bucket"
  value       = module.s3.phidata_bucket_domain
}

output "access_logs_bucket_id" {
  description = "ID of the access logs S3 bucket"
  value       = module.s3.access_logs_bucket_id
}

output "access_logs_bucket_arn" {
  description = "ARN of the access logs S3 bucket"
  value       = module.s3.access_logs_bucket_arn
}

# RDS Outputs
output "db_instance_address" {
  description = "Address of the RDS instance"
  value       = module.rds.db_instance_address
}

output "db_instance_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.rds.db_instance_endpoint
}

output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = module.rds.db_instance_id
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = module.rds.db_instance_arn
}

output "db_instance_name" {
  description = "Name of the RDS database"
  value       = module.rds.db_instance_name
}

output "db_instance_username" {
  description = "Username for the RDS database"
  value       = module.rds.db_instance_username
}

# EKS Outputs
output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_ca_certificate" {
  description = "CA certificate of the EKS cluster"
  value       = module.eks.cluster_ca_certificate
}

output "cluster_security_group_id" {
  description = "ID of the EKS cluster security group"
  value       = module.eks.cluster_security_group_id
}

output "node_instance_role_arn" {
  description = "ARN of the EKS node instance role"
  value       = module.eks.node_instance_role_arn
}

output "node_instance_role_name" {
  description = "Name of the EKS node instance role"
  value       = module.eks.node_instance_role_name
}

# Logging Outputs
output "cloudwatch_log_groups" {
  description = "Names of the CloudWatch log groups"
  value       = module.logging.cloudwatch_log_group_names
}

output "cloudwatch_log_group_arns" {
  description = "ARNs of the CloudWatch log groups"
  value       = module.logging.cloudwatch_log_group_arns
}

output "alert_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = module.logging.alert_topic_arn
}

output "alert_topic_name" {
  description = "Name of the SNS topic for alerts"
  value       = module.logging.alert_topic_name
}

# Backup Outputs
output "backup_vault_arn" {
  description = "ARN of the backup vault"
  value       = module.backup.backup_vault_arn
}

output "backup_vault_name" {
  description = "Name of the backup vault"
  value       = module.backup.backup_vault_name
}

output "backup_plan_id" {
  description = "ID of the backup plan"
  value       = module.backup.backup_plan_id
}

output "read_replica_endpoint" {
  description = "Endpoint of the RDS read replica"
  value       = module.backup.read_replica_endpoint
}

output "dr_bucket_id" {
  description = "ID of the DR S3 bucket"
  value       = module.backup.dr_bucket_id
}

output "replication_configuration_id" {
  description = "ID of the S3 replication configuration"
  value       = module.backup.replication_configuration_id
}

output "backup_job_failures_alarm_arn" {
  description = "ARN of the backup job failures alarm"
  value       = module.backup.backup_job_failures_alarm_arn
}

output "replication_lag_alarm_arn" {
  description = "ARN of the replication lag alarm"
  value       = module.backup.replication_lag_alarm_arn
}