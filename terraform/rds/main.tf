# RDS module for HIPAA-compliant health data platform
# Creates KMS-encrypted PostgreSQL database

# Database subnet group for RDS
resource "aws_db_subnet_group" "main" {
  name       = "${var.organization_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.organization_name}-db-subnet-group"
  })
}

# Database parameter group for PostgreSQL
resource "aws_db_parameter_group" "postgres" {
  name   = "${var.organization_name}-postgres-parameter-group"
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = merge(var.tags, {
    Name = "${var.organization_name}-postgres-parameter-group"
  })
}

# RDS instance with KMS encryption
resource "aws_db_instance" "postgres" {
  identifier = "${var.organization_name}-postgres-db"

  allocated_storage      = var.rds_allocated_storage
  max_allocated_storage  = var.rds_allocated_storage * 2
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "14.9"
  instance_class         = var.rds_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = aws_db_parameter_group.postgres.name
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  storage_encrypted      = true
  kms_key_id             = var.kms_rds_key_arn

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  skip_final_snapshot          = false
  final_snapshot_identifier    = "${var.organization_name}-final-snapshot-${formatdate("YYYYMMDD", timestamp())}"
  deletion_protection          = true
  copy_tags_to_snapshot        = true

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = merge(var.tags, {
    Name = "${var.organization_name}-postgres-db"
  })
}

# Security group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.organization_name}-rds-sg"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.organization_name}-rds-security-group"
  })
}

# Ingress rule for RDS from EKS nodes
resource "aws_security_group_rule" "rds_ingress_from_eks" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.eks_security_group_id
  description              = "Allow PostgreSQL connections from EKS nodes"
  security_group_id        = aws_security_group.rds.id
}

# CloudWatch log group for RDS logs
resource "aws_cloudwatch_log_group" "rds_logs" {
  name              = "/aws/rds/instance/${var.organization_name}-postgres-db/postgresql"
  retention_in_days = 365  # HIPAA requirement for audit logs

  tags = merge(var.tags, {
    Name = "${var.organization_name}-rds-postgresql-log-group"
  })
}

# RDS event subscription for critical events
resource "aws_db_event_subscription" "critical_events" {
  name          = "${var.organization_name}-rds-critical-events"
  sns_topic     = var.alert_sns_topic_arn
  source_type   = "db-instance"
  
  event_categories = [
    "deletion",
    "failover",
    "failure",
    "low storage",
    "maintenance",
    "notification",
    "recovery"
  ]

  source_ids = [aws_db_instance.postgres.identifier]

  tags = merge(var.tags, {
    Name = "${var.organization_name}-rds-event-subscription"
  })

  depends_on = [aws_db_instance.postgres]
}

# Option group for additional features (if needed)
resource "aws_db_option_group" "postgres_options" {
  name                    = "${var.organization_name}-postgres-option-group"
  option_group_description = "Option group for PostgreSQL"
  engine_name             = "postgres"
  major_engine_version    = "14"

  tags = merge(var.tags, {
    Name = "${var.organization_name}-postgres-option-group"
  })
}