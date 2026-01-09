# Output values for the KMS module

output "rds_key_arn" {
  description = "ARN of the KMS key for RDS encryption"
  value       = aws_kms_key.rds.arn
}

output "s3_key_arn" {
  description = "ARN of the KMS key for S3 encryption"
  value       = aws_kms_key.s3.arn
}

output "ebs_key_arn" {
  description = "ARN of the KMS key for EBS encryption"
  value       = aws_kms_key.ebs.arn
}

output "secrets_key_arn" {
  description = "ARN of the KMS key for Secrets Manager encryption"
  value       = aws_kms_key.secrets.arn
}

output "eks_secrets_key_arn" {
  description = "ARN of the KMS key for EKS secrets encryption"
  value       = aws_kms_key.eks_secrets.arn
}

output "rds_key_id" {
  description = "ID of the KMS key for RDS encryption"
  value       = aws_kms_key.rds.key_id
}

output "s3_key_id" {
  description = "ID of the KMS key for S3 encryption"
  value       = aws_kms_key.s3.key_id
}