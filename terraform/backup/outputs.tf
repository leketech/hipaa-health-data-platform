# Outputs for Backup and Disaster Recovery Module

output "backup_vault_arn" {
  description = "ARN of the backup vault"
  value       = aws_backup_vault.main.arn
}

output "backup_vault_name" {
  description = "Name of the backup vault"
  value       = aws_backup_vault.main.name
}

output "backup_plan_id" {
  description = "ID of the backup plan"
  value       = aws_backup_plan.main.id
}

output "read_replica_endpoint" {
  description = "Endpoint of the RDS read replica"
  value       = join("", aws_db_instance.read_replica[*].endpoint)
}

output "dr_bucket_id" {
  description = "ID of the DR S3 bucket"
  value       = join("", aws_s3_bucket.dr_backup[*].id)
}

output "replication_configuration_id" {
  description = "ID of the S3 replication configuration"
  value       = join("", aws_s3_bucket_replication_configuration.phidata_dr[*].id)
}

output "backup_job_failures_alarm_arn" {
  description = "ARN of the backup job failures alarm"
  value       = aws_cloudwatch_metric_alarm.backup_job_failures.arn
}

output "replication_lag_alarm_arn" {
  description = "ARN of the replication lag alarm"
  value       = join("", aws_cloudwatch_metric_alarm.replication_lag[*].arn)
}