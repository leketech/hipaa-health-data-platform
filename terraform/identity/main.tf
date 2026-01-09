# Identity module for HIPAA-compliant health data platform
# Creates Cognito user pool with MFA and user groups

# Cognito user pool with security configurations
resource "aws_cognito_user_pool" "main" {
  name = var.cognito_user_pool_name

  # Security configurations
  auto_verified_attributes  = ["email"]
  mfa_configuration         = "ON"  # MFA enforcement for HIPAA compliance
  sms_authentication_message = "Your authentication code is {####}"
  sms_verification_message  = "Your verification code is {####}"

  # Device configuration
  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = true
  }

  # Email verification type
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  # Password policy
  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  # MFA configuration
  sms_configuration {
    sns_caller_arn = aws_iam_role.cognito_sms_role.arn
    external_id    = var.cognito_external_id
  }

  # Account recovery settings
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }

  # Add Lambda triggers for custom authentication flows if needed
  lambda_config {
    pre_authentication    = var.pre_auth_lambda_arn
    post_authentication   = var.post_auth_lambda_arn
    pre_sign_up           = var.pre_signup_lambda_arn
    post_confirmation     = var.post_confirmation_lambda_arn
    pre_token_generation  = var.pre_token_gen_lambda_arn
    define_auth_challenge = var.define_auth_challenge_lambda_arn
    create_auth_challenge = var.create_auth_challenge_lambda_arn
    verify_auth_challenge = var.verify_auth_challenge_lambda_arn
  }

  tags = merge(var.tags, {
    Name = "${var.organization_name}-cognito-user-pool"
  })
}

# Cognito user pool client
resource "aws_cognito_user_pool_client" "main" {
  name                                 = var.cognito_app_client_name
  user_pool_id                         = aws_cognito_user_pool.main.id
  explicit_auth_flows                  = ["ADMIN_NO_SRP_AUTH", "CUSTOM_AUTH_FLOW_ONLY", "USER_PASSWORD_AUTH"]
  generate_secret                      = true
  refresh_token_validity               = 30
  access_token_validity                = 60
  id_token_validity                    = 60
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
  supported_identity_providers         = ["COGNITO"]
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls
  allowed_oauth_flows_user_pool_client = true

  tags = merge(var.tags, {
    Name = "${var.organization_name}-cognito-app-client"
  })
}

# Cognito identity pool for federated access
resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${var.organization_name}-identity-pool"
  allow_unauthenticated_identities = false  # HIPAA requirement - no anonymous access

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.main.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = true
  }

  tags = merge(var.tags, {
    Name = "${var.organization_name}-cognito-identity-pool"
  })
}

# Identity pool roles
resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  role_mapping {
    identity_provider         = "cognito-identity.amazonaws.com"
    ambiguous_role_resolution = "AuthenticatedRole"
    
    mapping_rule {
      claim        = "isAdmin"
      match_type   = "Equals"
      role_arn     = aws_iam_role.authenticated_role.arn
      value        = "true"
    }
  }

  roles = {
    authenticated   = aws_iam_role.authenticated_role.arn
    unauthenticated = aws_iam_role.unauthenticated_role.arn  # This won't be used due to allow_unauthenticated_identities = false
  }
}

# IAM role for Cognito SMS configuration
resource "aws_iam_role" "cognito_sms_role" {
  name = "${var.organization_name}-cognito-sms-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cognito-idp.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cognito_sms_policy" {
  role       = aws_iam_role.cognito_sms_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

# IAM roles for identity pool
resource "aws_iam_role" "authenticated_role" {
  name = "${var.organization_name}-cognito-authenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud": aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr": "authenticated"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "unauthenticated_role" {
  name = "${var.organization_name}-cognito-unauthenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud": aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr": "unauthenticated"
          }
        }
      }
    ]
  })
}

# User groups for role-based access control (RBAC)
resource "aws_cognito_user_group" "admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Administrators with full access"
  precedence   = 1

  role_arn = aws_iam_role.admin_group_role.arn
}

resource "aws_cognito_user_group" "clinician" {
  name         = "clinician"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Clinicians with patient data access"
  precedence   = 2

  role_arn = aws_iam_role.clinician_group_role.arn
}

resource "aws_cognito_user_group" "patient" {
  name         = "patient"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Patients with limited self data access"
  precedence   = 3

  role_arn = aws_iam_role.patient_group_role.arn
}

# IAM roles for user groups
resource "aws_iam_role" "admin_group_role" {
  name = "${var.organization_name}-admin-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "clinician_group_role" {
  name = "${var.organization_name}-clinician-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "patient_group_role" {
  name = "${var.organization_name}-patient-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# CloudWatch log group for Cognito logs
resource "aws_cloudwatch_log_group" "cognito_logs" {
  name              = "/aws/cognito/${var.organization_name}"
  retention_in_days = 365  # HIPAA requirement for audit logs

  tags = merge(var.tags, {
    Name = "${var.organization_name}-cognito-log-group"
  })
}

# Set up CloudWatch log resource policy to allow Cognito to write logs
resource "aws_cloudwatch_log_resource_policy" "cognito_policy" {
  policy_name = "${var.organization_name}-cognito-log-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cognito-idp.amazonaws.com"
        }
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = aws_cloudwatch_log_group.cognito_logs.arn
      }
    ]
  })
}