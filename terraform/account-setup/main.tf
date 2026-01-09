# Account setup for HIPAA-compliant health data platform
# Creates multi-account structure: security, shared-services, prod

resource "aws_organizations_organization" "hipaa_org" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "s3.amazonaws.com",
    "ram.amazonaws.com",
    "member.org.stacksets.cloudformation.amazonaws.com",
    "fms.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "backup.amazonaws.com"
  ]

  feature_set = "ALL"

  lifecycle {
    ignore_changes = [
      aws_service_access_principals
    ]
  }
}

# Security account
resource "aws_organizations_account" "security" {
  name  = "security"
  email = var.security_account_email

  parent_id = aws_organizations_organization.hipaa_org.roots[0].id
  role_name = "OrganizationAccountAccessRole"
}

# Shared services account
resource "aws_organizations_account" "shared_services" {
  name  = "shared-services"
  email = var.shared_services_account_email

  parent_id = aws_organizations_organization.hipaa_org.roots[0].id
  role_name = "OrganizationAccountAccessRole"
}

# Production account
resource "aws_organizations_account" "prod" {
  name  = "prod"
  email = var.prod_account_email

  parent_id = aws_organizations_organization.hipaa_org.roots[0].id
  role_name = "OrganizationAccountAccessRole"
}

# Create OUs for better organization
resource "aws_organizations_organizational_unit" "security_ou" {
  name      = "Security"
  parent_id = aws_organizations_organization.hipaa_org.roots[0].id
}

resource "aws_organizations_organizational_unit" "prod_ou" {
  name      = "Production"
  parent_id = aws_organizations_organization.hipaa_org.roots[0].id
}

# Move accounts to appropriate OUs
resource "aws_organizations_account" "security_in_ou" {
  name      = "security"
  email     = var.security_account_email
  parent_id = aws_organizations_organizational_unit.security_ou.id
  count     = 0 # This will be handled by the original resource
}

resource "aws_organizations_account" "prod_in_ou" {
  name      = "prod"
  email     = var.prod_account_email
  parent_id = aws_organizations_organizational_unit.prod_ou.id
  count     = 0 # This will be handled by the original resource
}

# Service control policy to enforce security baseline
resource "aws_organizations_policy" "hipaa_baseline_policy" {
  name = "${var.organization_name}-hipaa-baseline"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyUnencryptedOperations"
        Effect = "Deny"
        Action = [
          "s3:PutObject",
          "s3:PutObjectCopy",
          "s3:ReplicateObject"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "s3:x-amz-server-side-encryption": false
          }
        }
      },
      {
        Sid    = "DenyNonHTTPS"
        Effect = "Deny"
        Action = "s3:*"
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::*/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport": false
          }
        }
      },
      {
        Sid    = "RequireKMS"
        Effect = "Deny"
        Action = [
          "kms:DisableKey",
          "kms:ScheduleKeyDeletion"
        ]
        Resource = "*"
      }
    ]
  })

  description = "HIPAA baseline policy for ${var.organization_name}"
  type        = "SERVICE_CONTROL_POLICY"
}

# Attach SCP to the organization root
resource "aws_organizations_policy_attachment" "attach_to_root" {
  policy_id = aws_organizations_policy.hipaa_baseline_policy.id
  target_id = aws_organizations_organization.hipaa_org.roots[0].id
}

# Attach SCP to production OU
resource "aws_organizations_policy_attachment" "attach_to_prod_ou" {
  policy_id = aws_organizations_policy.hipaa_baseline_policy.id
  target_id = aws_organizations_organizational_unit.prod_ou.id
}