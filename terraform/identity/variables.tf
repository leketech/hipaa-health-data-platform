# Variables for identity module

variable "cognito_user_pool_name" {
  description = "Name for the Cognito user pool"
  type        = string
  default     = "hipaa-health-user-pool"
}

variable "cognito_app_client_name" {
  description = "Name for the Cognito app client"
  type        = string
  default     = "hipaa-health-app-client"
}

variable "organization_name" {
  description = "Name of the organization"
  type        = string
  default     = "hipaa-health-data-platform"
}

variable "cognito_external_id" {
  description = "External ID for Cognito SMS role"
  type        = string
  default     = ""
}

variable "pre_auth_lambda_arn" {
  description = "ARN of the pre-authentication Lambda function"
  type        = string
  default     = ""
}

variable "post_auth_lambda_arn" {
  description = "ARN of the post-authentication Lambda function"
  type        = string
  default     = ""
}

variable "pre_signup_lambda_arn" {
  description = "ARN of the pre-signup Lambda function"
  type        = string
  default     = ""
}

variable "post_confirmation_lambda_arn" {
  description = "ARN of the post-confirmation Lambda function"
  type        = string
  default     = ""
}

variable "pre_token_gen_lambda_arn" {
  description = "ARN of the pre-token generation Lambda function"
  type        = string
  default     = ""
}

variable "define_auth_challenge_lambda_arn" {
  description = "ARN of the define auth challenge Lambda function"
  type        = string
  default     = ""
}

variable "create_auth_challenge_lambda_arn" {
  description = "ARN of the create auth challenge Lambda function"
  type        = string
  default     = ""
}

variable "verify_auth_challenge_lambda_arn" {
  description = "ARN of the verify auth challenge Lambda function"
  type        = string
  default     = ""
}

variable "callback_urls" {
  description = "Callback URLs for OAuth"
  type        = list(string)
  default     = ["https://example.com/callback"]
}

variable "logout_urls" {
  description = "Logout URLs for OAuth"
  type        = list(string)
  default     = ["https://example.com/logout"]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "hipaa-health-data-platform"
    Environment = "prod"
    Compliance  = "HIPAA"
    Owner       = "Healthcare Team"
  }
}