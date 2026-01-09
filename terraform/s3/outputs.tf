# Output values for the S3 module

output "phidata_bucket_id" {
  description = "ID of the S3 bucket for PHI data"
  value       = aws_s3_bucket.phidata.id
}

output "phidata_bucket_arn" {
  description = "ARN of the S3 bucket for PHI data"
  value       = aws_s3_bucket.phidata.arn
}

output "access_logs_bucket_id" {
  description = "ID of the S3 bucket for access logs"
  value       = aws_s3_bucket.access_logs.id
}

output "access_logs_bucket_arn" {
  description = "ARN of the S3 bucket for access logs"
  value       = aws_s3_bucket.access_logs.arn
}

output "audit_logs_bucket_id" {
  description = "ID of the S3 bucket for audit logs"
  value       = aws_s3_bucket.audit_logs.id
}

output "audit_logs_bucket_arn" {
  description = "ARN of the S3 bucket for audit logs"
  value       = aws_s3_bucket.audit_logs.arn
}