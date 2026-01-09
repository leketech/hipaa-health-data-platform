# S3 module for HIPAA-compliant health data platform
# Creates S3 bucket with Object Lock for PHI storage

# Main S3 bucket for PHI data with Object Lock enabled
resource "aws_s3_bucket" "phidata" {
  bucket = var.s3_phidata_bucket_name

  tags = merge(var.tags, {
    Name = "${var.organization_name}-phidata-bucket"
  })
}

# Enable Object Lock for immutability (HIPAA requirement)
resource "aws_s3_bucket_object_lock_configuration" "phidata" {
  bucket = aws_s3_bucket.phidata.id

  object_lock_enabled = "Enabled"

  rule {
    default_retention {
      mode = "GOVERNANCE"  # Governance mode allows deletion by users with specific permissions
      days = 30            # Retention period - adjustable based on compliance needs
    }
  }
}

# S3 bucket policy to enforce encryption and secure transport
resource "aws_s3_bucket_policy" "phidata_encryption" {
  bucket = aws_s3_bucket.phidata.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureConnections"
        Effect = "Deny"
        Principal = "*"
        Action   = "s3:*"
        Resource = [
          aws_s3_bucket.phidata.arn,
          "${aws_s3_bucket.phidata.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport": "false"
          }
        }
      },
      {
        Sid    = "DenyUnencryptedObjectUploads"
        Effect = "Deny"
        Principal = "*"
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.phidata.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption": "aws:kms"
          }
        }
      },
      {
        Sid    = "RequireSpecificKMSKey"
        Effect = "Deny"
        Principal = "*"
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.phidata.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption-aws-kms-key-id": var.kms_s3_key_arn
          }
        }
      }
    ]
  })
}

# Enable versioning for data protection
resource "aws_s3_bucket_versioning" "phidata" {
  bucket = aws_s3_bucket.phidata.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server access logging configuration
resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.s3_phidata_bucket_name}-access-logs"

  tags = merge(var.tags, {
    Name = "${var.organization_name}-phidata-access-logs"
  })
}

# Enable versioning for access logs bucket
resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Set up server access logging
resource "aws_s3_bucket_logging" "phidata" {
  bucket = aws_s3_bucket.phidata.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "log/"
}

# S3 bucket for audit logs (immutable)
resource "aws_s3_bucket" "audit_logs" {
  bucket = "${var.s3_phidata_bucket_name}-audit-logs"

  tags = merge(var.tags, {
    Name = "${var.organization_name}-audit-logs-bucket"
  })
}

# Enable Object Lock for audit logs
resource "aws_s3_bucket_object_lock_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  object_lock_enabled = "Enabled"

  rule {
    default_retention {
      mode = "COMPLIANCE"  # Compliance mode prevents deletion/modification until retention period expires
      days = 365           # Longer retention for audit logs per HIPAA requirements
    }
  }
}

# Enable versioning for audit logs bucket
resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle configuration to transition older objects to cheaper storage classes
resource "aws_s3_bucket_lifecycle_configuration" "phidata" {
  bucket = aws_s3_bucket.phidata.id

  rule {
    id     = "transition_to_ia_after_30_days"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555  # 7 years - typical retention requirement for healthcare data
    }
  }
}

# Replication configuration for disaster recovery (cross-region)
resource "aws_s3_bucket_replication_configuration" "phidata_dr" {
  count  = var.enable_cross_region_replication ? 1 : 0
  role   = aws_iam_role.s3_replication.arn
  bucket = aws_s3_bucket.phidata.id

  rule {
    id     = "replicate_for_dr"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.phidata_replica[0].arn
      storage_class = "STANDARD_IA"
    }
  }
}

# Replica bucket for disaster recovery
resource "aws_s3_bucket" "phidata_replica" {
  count  = var.enable_cross_region_replication ? 1 : 0
  provider = aws.secondary
  bucket = "${var.s3_phidata_bucket_name}-replica"

  tags = merge(var.tags, {
    Name = "${var.organization_name}-phidata-replica-bucket"
  })
}

# Enable Object Lock for replica bucket
resource "aws_s3_bucket_object_lock_configuration" "phidata_replica" {
  count  = var.enable_cross_region_replication ? 1 : 0
  provider = aws.secondary
  bucket = aws_s3_bucket.phidata_replica[0].id

  object_lock_enabled = "Enabled"

  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = 30
    }
  }
}

# Enable versioning for replica bucket
resource "aws_s3_bucket_versioning" "phidata_replica" {
  count  = var.enable_cross_region_replication ? 1 : 0
  provider = aws.secondary
  bucket = aws_s3_bucket.phidata_replica[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# IAM role for S3 replication
resource "aws_iam_role" "s3_replication" {
  count = var.enable_cross_region_replication ? 1 : 0
  name  = "${var.organization_name}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_replication" {
  count = var.enable_cross_region_replication ? 1 : 0
  name  = "${var.organization_name}-s3-replication-policy"
  role  = aws_iam_role.s3_replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl"
        ]
        Resource = "${aws_s3_bucket.phidata.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetReplicationConfiguration"
        ]
        Resource = aws_s3_bucket.phidata.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.phidata_replica[0].arn}/*"
      }
    ]
  })
}