# Output values for the account setup module

output "organization_id" {
  description = "ID of the AWS organization"
  value       = aws_organizations_organization.hipaa_org.id
}

output "security_account_id" {
  description = "ID of the security account"
  value       = aws_organizations_account.security.id
}

output "shared_services_account_id" {
  description = "ID of the shared services account"
  value       = aws_organizations_account.shared_services.id
}

output "prod_account_id" {
  description = "ID of the production account"
  value       = aws_organizations_account.prod.id
}