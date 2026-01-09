# Output values for the HIPAA-compliant health data platform

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_ca_certificate" {
  description = "CA certificate of the EKS cluster"
  value       = module.eks.cluster_ca_certificate
  sensitive   = true
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "rds_instance_id" {
  description = "ID of the RDS instance"
  value       = module.rds.db_instance_id
}

output "cognito_user_pool_id" {
  description = "ID of the Cognito user pool"
  value       = module.identity.user_pool_id
}

output "cognito_app_client_id" {
  description = "ID of the Cognito app client"
  value       = module.identity.app_client_id
}

output "s3_phidata_bucket_arn" {
  description = "ARN of the S3 bucket for PHI data"
  value       = module.s3.phidata_bucket_arn
}

output "kms_rds_key_arn" {
  description = "ARN of the KMS key for RDS encryption"
  value       = module.kms.rds_key_arn
}

output "kms_s3_key_arn" {
  description = "ARN of the KMS key for S3 encryption"
  value       = module.kms.s3_key_arn
}

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