# Variables for account setup module

variable "organization_name" {
  description = "Name of the AWS organization"
  type        = string
  default     = "hipaa-health-data-platform"
}

variable "security_account_email" {
  description = "Email for the security account"
  type        = string
}

variable "shared_services_account_email" {
  description = "Email for the shared services account"
  type        = string
}

variable "prod_account_email" {
  description = "Email for the production account"
  type        = string
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