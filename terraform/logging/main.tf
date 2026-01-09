# Logging module for HIPAA-compliant health data platform
# Sets up comprehensive logging and monitoring

# CloudTrail for API activity logging (organization-wide)
resource "aws_cloudtrail" "org_trail" {
  name                          = "${var.organization_name}-org-trail"
  s3_bucket_name                = var.log_bucket_name
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch_role.arn
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.cloudtrail.arn

  # HIPAA requirement - don't log management events to exclude sensitive data
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${var.log_bucket_name}/"]
    }

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }

  tags = merge(var.tags, {
    Name = "${var.organization_name}-org-trail"
  })
}

# CloudTrail for EKS audit logging
resource "aws_cloudtrail" "eks_trail" {
  name                          = "${var.organization_name}-eks-trail"
  s3_bucket_name                = var.log_bucket_name
  s3_key_prefix                 = "cloudtrail/eks"
  include_global_service_events = false
  is_multi_region_trail         = false
  enable_log_file_validation    = true
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch_role.arn
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.eks_audit.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${var.log_bucket_name}/cloudtrail/eks/"]
    }
  }

  tags = merge(var.tags, {
    Name = "${var.organization_name}-eks-trail"
  })
}

# CloudWatch log group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.organization_name}"
  retention_in_days = 365  # HIPAA requirement for audit logs

  tags = merge(var.tags, {
    Name = "${var.organization_name}-cloudtrail-log-group"
  })
}

# CloudWatch log group for EKS audit logs
resource "aws_cloudwatch_log_group" "eks_audit" {
  name              = "/aws/eks/${var.eks_cluster_name}/audit"
  retention_in_days = 365  # HIPAA requirement for audit logs

  tags = merge(var.tags, {
    Name = "${var.organization_name}-eks-audit-log-group"
  })
}

# CloudWatch log group for application logs
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/eks/${var.eks_cluster_name}/application"
  retention_in_days = 365  # HIPAA requirement for audit logs

  tags = merge(var.tags, {
    Name = "${var.organization_name}-application-log-group"
  })
}

# CloudWatch log group for security events
resource "aws_cloudwatch_log_group" "security" {
  name              = "/aws/security/${var.organization_name}"
  retention_in_days = 365  # HIPAA requirement for audit logs

  tags = merge(var.tags, {
    Name = "${var.organization_name}-security-log-group"
  })
}

# IAM role for CloudTrail to publish to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  name = "${var.organization_name}-cloudtrail-cwl-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudTrailAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_policy" {
  name = "${var.organization_name}-cloudtrail-cwl-policy"
  role = aws_iam_role.cloudtrail_cloudwatch_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailCreateLogStream",
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:PutLogEventsBatch"
        ]
        Resource = [
          aws_cloudwatch_log_group.cloudtrail.arn,
          aws_cloudwatch_log_group.eks_audit.arn
        ]
      }
    ]
  })
}

# GuardDuty detector for threat detection
resource "aws_guardduty_detector" "main" {
  enable                          = true
  finding_publishing_frequency    = "SIX_HOURS"
  data_sources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.organization_name}-guardduty-detector"
  })
}

# GuardDuty S3 protection for the log bucket
resource "aws_guardduty_member" "log_bucket_protection" {
  count           = var.enable_guardduty_members ? 1 : 0
  detector_id     = aws_guardduty_detector.main.id
  account_id      = var.log_bucket_account_id
  email           = var.log_bucket_owner_email
  invite          = true
  invitation_message = "Auto-invitation for HIPAA compliance"

  depends_on = [
    aws_s3_bucket.lifecycle_configuration
  ]
}

# Security Hub for centralized security findings
resource "aws_securityhub_account" "main" {
  tags = merge(var.tags, {
    Name = "${var.organization_name}-securityhub"
  })
}

# Enable Security Hub standards
resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:${var.primary_region}::standards/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on    = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "pci" {
  standards_arn = "arn:aws:securityhub:${var.primary_region}::standards/pci-dss/v/3.2.1"
  depends_on    = [aws_securityhub_account.main]
}

# EventBridge rule to send GuardDuty findings to Security Hub
resource "aws_cloudwatch_event_rule" "guardduty_to_securityhub" {
  name        = "${var.organization_name}-gd-to-sh-rule"
  description = "Route GuardDuty findings to SecurityHub"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "guardduty_to_securityhub_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_to_securityhub.name
  arn       = "arn:aws:securityhub:${var.primary_region}:${data.aws_caller_identity.current.account_id}:action/custom/guardduty-finding-handler"
  target_id = "SendToSecurityHub"
}

# Config recorder for configuration changes
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.organization_name}-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.organization_name}-config-delivery-channel"
  s3_bucket_name = var.config_bucket_name
  sns_topic_arn  = var.config_sns_topic_arn

  depends_on = [
    aws_s3_bucket.config_bucket,
    aws_config_configuration_recorder.main
  ]
}

# Config bucket for storing configuration history
resource "aws_s3_bucket" "config_bucket" {
  bucket = "${var.organization_name}-config-bucket"

  tags = merge(var.tags, {
    Name = "${var.organization_name}-config-bucket"
  })
}

# Enable versioning for config bucket
resource "aws_s3_bucket_versioning" "config_bucket" {
  bucket = aws_s3_bucket.config_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for config bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "config_bucket" {
  bucket = aws_s3_bucket.config_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM role for AWS Config
resource "aws_iam_role" "config_role" {
  name = "${var.organization_name}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config_role_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

# Custom Config rule for EKS private endpoint
resource "aws_config_config_rule" "eks_private_endpoint" {
  name        = "${var.organization_name}-eks-private-endpoint-check"
  description = "Ensure EKS clusters have private endpoint only"

  source {
    owner             = "AWS"
    source_identifier = "EKS_ENDPOINT_NO_PUBLIC_ACCESS"
  }

  scope {
    compliance_resource_types = ["AWS::EKS::Cluster"]
  }

  input_parameters = jsonencode({
    endpointPublicAccess = "false"
  })

  maximum_execution_frequency = "TwentyFour_Hours"
}

# CloudWatch alarm for unauthorized API access
resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "${var.organization_name}-unauthorized-api-calls"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "UnauthorizedOperation"
  namespace          = "AWS/Usage"
  period             = "300"
  statistic          = "Sum"
  threshold          = "1"
  alarm_description  = "This metric monitors unauthorized API calls"
  alarm_actions      = [var.alert_sns_topic_arn]

  tags = merge(var.tags, {
    Name = "${var.organization_name}-unauthorized-api-calls-alarm"
  })
}

# CloudWatch alarm for high API error rate
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.organization_name}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "APIErrorRate"
  namespace          = "AWS/Usage"
  period             = "300"
  statistic          = "Average"
  threshold          = "5"
  alarm_description  = "This metric monitors API error rates"
  alarm_actions      = [var.alert_sns_topic_arn]

  tags = merge(var.tags, {
    Name = "${var.organization_name}-high-error-rate-alarm"
  })
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}