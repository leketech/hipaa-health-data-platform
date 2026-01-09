# Security module for HIPAA-compliant health data platform
# Implements additional security controls and policies

# WAF Web ACL for application-level protection
resource "aws_wafv2_web_acl" "main" {
  name  = "${var.organization_name}-waf-acl"
  scope = "REGIONAL"  # Change to CLOUDFRONT if protecting CloudFront distribution

  default_action {
    allow {}
  }

  description = "WAF ACL for HIPAA-compliant health platform"

  rule {
    name     = "rate-limiting"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.organization_name}-rate-limit-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "common-rule"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.organization_name}-common-rule-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "sql-injection"
    priority = 3

    action {
      block {}
    }

    statement {
      sqli_match_statement {
        field_to_match {
          query_string {}
        }

        text_transformation {
          priority = 1
          type     = "URL_DECODE"
        }

        text_transformation {
          priority = 2
          type     = "HTML_ENTITY_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.organization_name}-sql-injection-metric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.organization_name}-waf-metric"
    sampled_requests_enabled   = true
  }

  tags = merge(var.tags, {
    Name = "${var.organization_name}-waf-acl"
  })
}

# AWS Backup vault for automated backups
resource "aws_backup_vault" "main" {
  name        = "${var.organization_name}-backup-vault"
  kms_key_arn = var.kms_backup_key_arn

  tags = merge(var.tags, {
    Name = "${var.organization_name}-backup-vault"
  })
}

# AWS Backup plan for HIPAA compliance
resource "aws_backup_plan" "hipaa_compliant" {
  name = "${var.organization_name}-hipaa-backup-plan"

  rule {
    rule_name         = "${var.organization_name}-daily-backup-rule"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 ? * * *)"  # Daily at 5 AM UTC

    lifecycle {
      cold_storage_after   = 30   # Move to cold storage after 30 days
      delete_after         = 2555  # Delete after 7 years (HIPAA requirement)
    }
  }

  tags = merge(var.tags, {
    Name = "${var.organization_name}-hipaa-backup-plan"
  })
}

# AWS Backup selection for RDS
resource "aws_backup_selection" "rds_backup" {
  name         = "${var.organization_name}-rds-backup-selection"
  plan_id      = aws_backup_plan.hipaa_compliant.id
  iam_role_arn = aws_iam_role.backup_role.arn

  resources = [
    var.rds_instance_arn
  ]
}

# AWS Backup selection for EBS volumes
resource "aws_backup_selection" "ebs_backup" {
  name         = "${var.organization_name}-ebs-backup-selection"
  plan_id      = aws_backup_plan.hipaa_compliant.id
  iam_role_arn = aws_iam_role.backup_role.arn

  resources = [
    var.eks_node_ebs_arns
  ]
}

# IAM role for AWS Backup
resource "aws_iam_role" "backup_role" {
  name = "${var.organization_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_service_role" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Secrets Manager for storing sensitive data
resource "aws_secretsmanager_secret" "database_credentials" {
  name                    = "${var.organization_name}/database-credentials"
  description             = "Database credentials for HIPAA-compliant application"
  kms_key_id              = var.kms_secrets_key_arn
  recovery_window_in_days = 30  # HIPAA requirement for recovery window

  tags = merge(var.tags, {
    Name = "${var.organization_name}-database-credentials-secret"
  })
}

resource "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id     = aws_secretsmanager_secret.database_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

resource "aws_secretsmanager_secret" "api_keys" {
  name                    = "${var.organization_name}/api-keys"
  description             = "API keys for HIPAA-compliant application"
  kms_key_id              = var.kms_secrets_key_arn
  recovery_window_in_days = 30  # HIPAA requirement for recovery window

  tags = merge(var.tags, {
    Name = "${var.organization_name}-api-keys-secret"
  })
}

# Route53 hosted zone for the application
resource "aws_route53_zone" "primary" {
  name = var.domain_name

  tags = merge(var.tags, {
    Name = "${var.organization_name}-route53-zone"
  })
}

# ACM certificate for SSL/TLS
resource "aws_acm_certificate" "main" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = var.subject_alternative_names

  tags = merge(var.tags, {
    Name = "${var.organization_name}-ssl-certificate"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 records for certificate validation
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.primary.zone_id
}

# ACM certificate validation
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# OPA/Rego policy for fine-grained authorization
resource "aws_eks_addon" "gatekeeper" {
  count        = var.install_gatekeeper ? 1 : 0
  cluster_name = var.eks_cluster_name
  addon_name   = "gatekeeper"

  tags = merge(var.tags, {
    Name = "${var.organization_name}-gatekeeper-addon"
  })
}

# Security group for load balancers
resource "aws_security_group" "alb" {
  name        = "${var.organization_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.organization_name}-alb-security-group"
  })
}

# Security group rules to connect ALB to EKS
resource "aws_security_group_rule" "alb_to_eks" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow ALB to connect to EKS nodes"
  security_group_id        = var.eks_node_security_group_id
}

# AWS Systems Manager Parameter Store for configuration
resource "aws_ssm_parameter" "environment_config" {
  name        = "/${var.organization_name}/env-config"
  description = "Environment configuration for HIPAA-compliant application"
  type        = "SecureString"
  value       = jsonencode(var.environment_config)
  key_id      = var.kms_ssm_key_arn

  tags = merge(var.tags, {
    Name = "${var.organization_name}-env-config-parameter"
  })
}

# CloudWatch dashboard for security metrics
resource "aws_cloudwatch_dashboard" "security_dashboard" {
  dashboard_name = "${var.organization_name}-security-dashboard"

  dashboard_body = jsonencode({
    "widgets": [
      {
        "type": "metric",
        "x": 0,
        "y": 0,
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
            ["AWS/CloudTrail", "EventCount", "Trail", aws_cloudtrail.org_trail.name]
          ],
          "period": 300,
          "stat": "Sum",
          "region": var.primary_region,
          "title": "CloudTrail API Events"
        }
      },
      {
        "type": "metric",
        "x": 12,
        "y": 0,
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
            ["AWS/GuardDuty", "Findings", "detectorId", aws_guardduty_detector.main.id]
          ],
          "period": 300,
          "stat": "Sum",
          "region": var.primary_region,
          "title": "GuardDuty Findings"
        }
      },
      {
        "type": "metric",
        "x": 0,
        "y": 6,
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
            ["AWS/Usage", "CallCount", "ServiceName", "s3.amazonaws.com", "Resource", aws_s3_bucket.phidata.bucket_domain_name]
          ],
          "period": 300,
          "stat": "Sum",
          "region": var.primary_region,
          "title": "S3 Bucket Access"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.organization_name}-security-dashboard"
  })
}