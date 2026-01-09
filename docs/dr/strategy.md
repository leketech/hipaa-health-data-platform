# Disaster Recovery Strategy for HIPAA-Compliant Health Platform

## Overview
This document outlines the disaster recovery strategy for the HIPAA-compliant health data platform, ensuring business continuity with RTO < 1 hour and RPO < 15 minutes.

## Recovery Objectives
- **RTO (Recovery Time Objective)**: < 1 hour
- **RPO (Recovery Point Objective)**: < 15 minutes
- **Recovery Priority**: Patient care systems first, administrative systems second

## Backup Strategy

### AWS Backup Configuration
```hcl
# RDS automated backups
resource "aws_db_instance" "main" {
  # ... other configuration ...
  backup_retention_period = 35  # 35 days backup retention
  backup_window           = "03:00-04:00"  # Off-peak backup window
  backup_start_time       = "03:30"        # Consistent daily backup time
}

# S3 versioning for data protection
resource "aws_s3_bucket_versioning" "phidata" {
  bucket = aws_s3_bucket.phidata.id
  versioning_configuration {
    status = "Enabled"
  }
}

# EBS volume backups
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
  }
}

resource "aws_backup_selection" "rds_selection" {
  name         = "rds-backup-selection"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup_role.arn

  resources = [
    aws_db_instance.main.arn,
  ]
}
```

### Cross-Region Replication

#### RDS Read Replica
```hcl
# Cross-region read replica for RDS PostgreSQL
resource "aws_db_instance" "read_replica" {
  identifier           = "${var.organization_name}-read-replica-dr"
  replicate_source_db  = aws_db_instance.main.identifier
  availability_zone    = "${var.secondary_region}a"
  db_subnet_group_name = data.aws_db_subnet_group.dr-subnet-group.name
  kms_key_id          = var.kms_rds_key_arn
  
  tags = merge(var.tags, {
    Name = "${var.organization_name}-read-replica-dr"
    DisasterRecovery = "enabled"
  })
}
```

#### S3 Cross-Region Replication
```hcl
# S3 Cross-Region Replication
resource "aws_s3_bucket_replication_configuration" "phidata_dr" {
  bucket = aws_s3_bucket.phidata.id

  role = aws_iam_role.replication_role.arn

  rule {
    id     = "replicate-to-dr"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.dr_backup.arn
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
}

# DR backup bucket
resource "aws_s3_bucket" "dr_backup" {
  bucket = "${var.organization_name}-phidata-dr-backup"

  tags = merge(var.tags, {
    Name = "${var.organization_name}-phidata-dr-backup"
  })
}
```

## Failure Drills

### 1. Kill EKS Nodes Drill
**Objective**: Verify EKS cluster self-healing capabilities

**Procedure**:
```bash
# Drain and delete a node
kubectl drain <node-name> --ignore-daemonsets --delete-local-data
kubectl delete node <node-name>

# Verify cluster recovers
kubectl get nodes
kubectl get pods --all-namespaces
```

**Success Criteria**:
- Pods rescheduled within 5 minutes
- No data loss
- Services remain available

### 2. Simulate AZ Outage Drill
**Objective**: Test application resilience to availability zone failures

**Procedure**:
```bash
# Block traffic to one AZ (simulate failure)
# Verify application continues to operate
kubectl get nodes --show-labels | grep failure-domain.beta.kubernetes.io/zone

# Verify load balancing to healthy AZs
kubectl top nodes
kubectl top pods
```

**Success Criteria**:
- Applications continue to serve requests
- No data inconsistency
- Performance remains acceptable

### 3. Restore from Backup Drill
**Objective**: Verify backup restoration process

**Procedure**:
```bash
# Test RDS restore
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier test-restore \
  --db-snapshot-identifier latest-backup-snapshot

# Test S3 data restoration
aws s3 sync s3://backup-bucket/restore-test/ ./temp-restore/

# Verify data integrity
# Cleanup test resources
aws rds delete-db-instance --db-instance-identifier test-restore --skip-final-snapshot
```

**Success Criteria**:
- Data restored within RTO
- Data integrity verified
- No PHI exposure during restore

### 4. Rotate KMS Keys Drill
**Objective**: Test KMS key rotation without service interruption

**Procedure**:
```bash
# Schedule KMS key deletion (with 30-day waiting period)
aws kms schedule-key-deletion --key-id <key-id> --pending-window-in-days 7

# Create new key and update resources
terraform apply -var="kms_key_rotation=true"

# Verify services continue to operate
# Update key aliases to point to new key
aws kms update-alias --alias-name alias/hipaa-health-data-platform --target-key-id <new-key-id>

# Cancel deletion of old key
aws kms cancel-key-deletion --key-id <old-key-id>
```

**Success Criteria**:
- Services continue without interruption
- All encrypted data remains accessible
- New key becomes active within expected timeframe

## DR Playbook

### Activation Criteria
- Primary region completely unavailable
- Extended service outage (> 30 minutes)
- Compromised security incident

### Activation Process
1. **Assessment Phase (0-15 min)**
   - Confirm primary region unavailability
   - Activate incident response team
   - Notify stakeholders

2. **Failover Phase (15-45 min)**
   - Promote RDS read replica to primary
   - Update DNS to point to DR region
   - Start applications in DR region
   - Verify service availability

3. **Recovery Phase (45+ min)**
   - Monitor service performance
   - Conduct data integrity checks
   - Update documentation

### Rollback Process
If primary region becomes available:
1. Perform data sync from DR to primary
2. Cut over traffic back to primary
3. Verify service integrity
4. Clean up DR resources

## Testing Schedule

### Monthly Tests
- Backup restoration verification
- Cross-region replication verification
- KMS key rotation test

### Quarterly Tests
- Full disaster recovery simulation
- RTO/RPO measurements
- Documentation updates

### Annual Tests
- Complete site failover
- Third-party audit of DR procedures
- Update of RTO/RPO targets

## Monitoring & Alerting

### DR-Specific Metrics
- Replication lag time
- Backup success rate
- Cross-region connectivity
- Storage capacity in DR region

### DR-Specific Alerts
- Replication failure
- Backup failure
- Storage threshold exceeded
- Network connectivity issues

## Compliance Considerations

### HIPAA Requirements
- All PHI data encrypted during DR procedures
- Access logging maintained during failover
- No PHI exposure during backup/restore
- Audit trail preserved across regions

### Documentation Requirements
- DR test reports maintained for 6 years
- Incident response procedures documented
- Staff training records maintained
- Vendor agreements updated for DR sites