# Backup and Disaster Recovery Module for HIPAA-Compliant Health Platform

resource "aws_backup_vault" "main" {
  name        = "${var.organization_name}-backup-vault"
  kms_key_id  = var.kms_backup_key_arn

  tags = merge(var.tags, {
    Name = "${var.organization_name}-backup-vault"
    Backup = "enabled"
  })
}

resource "aws_backup_plan" "main" {
  name = "${var.organization_name}-backup-plan"

  rule {
    rule_name         = "daily-backup-rule"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 ? * * *)"  # Daily at 5 AM UTC
    start_window      = 60     # 60 minute window
    completion_window = 120    # 120 minute completion window
    
    lifecycle {
      cold_storage_after = 30  # Move to cold storage after 30 days
      delete_after       = 365  # Delete after 365 days
    }

    recovery_point_tags = merge(var.tags, {
      BackupRule = "daily"
    })
  }

  rule {
    rule_name         = "weekly-full-backup-rule"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 3 ? * 1 *)"  # Weekly at 3 AM UTC on Sundays
    start_window      = 120    # 120 minute window
    completion_window = 240    # 240 minute completion window
    
    lifecycle {
      cold_storage_after = 7   # Move to cold storage after 7 days for weekly backups
      delete_after       = 1825 # Delete after 5 years for weekly backups
    }

    recovery_point_tags = merge(var.tags, {
      BackupRule = "weekly-full"
    })
  }
}

resource "aws_backup_selection" "rds_selection" {
  name         = "rds-backup-selection"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = var.backup_role_arn

  resources = [
    var.rds_instance_arn,
  ]
}

resource "aws_backup_selection" "ebs_selection" {
  name         = "ebs-backup-selection"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = var.backup_role_arn

  resources = var.ebs_volume_arns
}

resource "aws_backup_selection" "efs_selection" {
  name         = "efs-backup-selection"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = var.backup_role_arn

  resources = [
    var.efs_file_system_arn,
  ]
}

# S3 Cross-Region Replication Configuration
resource "aws_s3_bucket_replication_configuration" "phidata_dr" {
  count  = var.enable_cross_region_replication ? 1 : 0
  bucket = var.source_bucket_id

  role = var.replication_role_arn

  rule {
    id     = "replicate-to-dr"
    status = "Enabled"

    destination {
      bucket        = var.dr_bucket_arn
      storage_class = "STANDARD_IA"

      replication_metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }

      encryption_configuration {
        replica_kms_key_id = var.kms_s3_key_arn
      }
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.source_versioning,
    aws_s3_bucket_versioning.dr_versioning
  ]
}

# RDS Read Replica for Disaster Recovery
resource "aws_db_instance" "read_replica" {
  count = var.create_read_replica ? 1 : 0

  identifier           = "${var.organization_name}-read-replica-dr"
  replicate_source_db  = var.primary_rds_instance_id
  availability_zone    = "${var.secondary_region}a"
  db_subnet_group_name = var.dr_db_subnet_group_name
  kms_key_id          = var.kms_rds_key_arn
  backup_retention_period = 7  # 7 days retention for replica
  backup_window       = "03:00-04:00"  # Off-peak backup window
  backup_start_time   = "03:30"        # Consistent daily backup time
  
  tags = merge(var.tags, {
    Name = "${var.organization_name}-read-replica-dr"
    DisasterRecovery = "enabled"
  })
}

# DR S3 Bucket
resource "aws_s3_bucket" "dr_backup" {
  count = var.create_dr_bucket ? 1 : 0

  bucket = "${var.organization_name}-phidata-dr-backup-${var.secondary_region}"

  tags = merge(var.tags, {
    Name = "${var.organization_name}-phidata-dr-backup"
    DisasterRecovery = "enabled"
  })
}

resource "aws_s3_bucket_versioning" "dr_versioning" {
  count  = var.create_dr_bucket ? 1 : 0
  bucket = aws_s3_bucket.dr_backup[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dr_encryption" {
  count  = var.create_dr_bucket ? 1 : 0
  bucket = aws_s3_bucket.dr_backup[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_s3_key_arn
    }
  }
}

resource "aws_s3_bucket_object_lock_configuration" "dr_phidata" {
  count = var.create_dr_bucket ? 1 : 0

  bucket = aws_s3_bucket.dr_backup[0].id

  object_lock_enabled = "Enabled"

  rule {
    default_retention {
      mode = "COMPLIANCE"  # Compliance mode for PHI data protection
      days = 30            # Retention period - adjustable based on compliance needs
    }
  }
}

# S3 Lifecycle Policy for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "dr_lifecycle" {
  count  = var.create_dr_bucket ? 1 : 0
  bucket = aws_s3_bucket.dr_backup[0].id

  rule {
    id     = "glacier-transition"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555  # 7 years for HIPAA compliance
    }
  }
}

# CloudWatch Alarms for Backup Monitoring
resource "aws_cloudwatch_metric_alarm" "backup_job_failures" {
  alarm_name          = "${var.organization_name}-backup-job-failures"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedJobs"
  namespace           = "AWS/Backup"
  period              = "3600"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors backup job failures"

  alarm_actions = [
    var.alert_sns_topic_arn
  ]

  dimensions = {
    BackupVaultName = aws_backup_vault.main.name
  }
}

resource "aws_cloudwatch_metric_alarm" "replication_lag" {
  count               = var.enable_cross_region_replication ? 1 : 0
  alarm_name          = "${var.organization_name}-replication-lag"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReplicationLatency"
  namespace           = "AWS/S3"
  period              = "300"
  statistic           = "Average"
  threshold           = "900"  # 15 minutes threshold
  alarm_description   = "This metric monitors S3 cross-region replication latency"

  alarm_actions = [
    var.alert_sns_topic_arn
  ]

  dimensions = {
    BucketName = var.source_bucket_id
  }
}

# Backup Compliance Rules
resource "aws_backup_compliance_rule" "hipaa_compliance" {
  name                        = "${var.organization_name}-hipaa-compliance-rule"
  backup_vault_name           = aws_backup_vault.main.name
  target_backup_plan_arn      = aws_backup_plan.main.arn

  condition {
    string_equals {
      key   = "resourceType"
      value = "EC2"
    }
  }

  status = "ACTIVE"
}