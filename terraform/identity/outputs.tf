# Output values for the identity module

output "user_pool_id" {
  description = "ID of the Cognito user pool"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito user pool"
  value       = aws_cognito_user_pool.main.arn
}

output "app_client_id" {
  description = "ID of the Cognito app client"
  value       = aws_cognito_user_pool_client.main.id
}

output "app_client_secret" {
  description = "Secret of the Cognito app client"
  value       = aws_cognito_user_pool_client.main.client_secret
  sensitive   = true
}

output "identity_pool_id" {
  description = "ID of the Cognito identity pool"
  value       = aws_cognito_identity_pool.main.id
}

output "admin_group_name" {
  description = "Name of the admin user group"
  value       = aws_cognito_user_group.admin.name
}

output "clinician_group_name" {
  description = "Name of the clinician user group"
  value       = aws_cognito_user_group.clinician.name
}

output "patient_group_name" {
  description = "Name of the patient user group"
  value       = aws_cognito_user_group.patient.name
}