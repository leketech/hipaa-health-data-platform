package terraform.analysis

# Example policy to check for required tags
deny[msg] {
  input.resource_changes[_].change.after.tags
  not input.resource_changes[_].change.after.tags.Project
  msg := "Required Project tag is missing"
}

# Example policy to check for encryption
deny[msg] {
  input.resource_changes[_].type == "aws_s3_bucket"
  not input.resource_changes[_].change.after.server_side_encryption_configuration
  msg := "S3 bucket must have server-side encryption enabled"
}

# HIPAA compliance policy: Ensure KMS encryption for RDS
deny[msg] {
  input.resource_changes[_].type == "aws_db_instance"
  not input.resource_changes[_].change.after.kms_key_id
  msg := "RDS instances must use KMS encryption for HIPAA compliance"
}

# HIPAA compliance policy: Ensure CloudTrail is enabled
deny[msg] {
  input.resource_changes[_].type == "aws_cloudtrail"
  input.resource_changes[_].change.after.enabled == false
  msg := "CloudTrail must be enabled for audit logging and HIPAA compliance"
}

# Ensure VPC flow logs are enabled for network monitoring
deny[msg] {
  input.resource_changes[_].type == "aws_flow_log"
  not input.resource_changes[_].change.after.log_destination
  msg := "VPC flow logs must be enabled for network monitoring"
}

# Ensure S3 Object Lock is enabled for PHI storage
deny[msg] {
  input.resource_changes[_].type == "aws_s3_bucket_object_lock_configuration"
  input.resource_changes[_].change.after.object_lock_enabled != "Enabled"
  msg := "S3 Object Lock must be enabled for immutable audit logging"
}

# Ensure SSL/TLS is enforced for RDS
deny[msg] {
  input.resource_changes[_].type == "aws_db_instance"
  input.resource_changes[_].change.after.engine != "aurora-postgresql"
  input.resource_changes[_].change.after.engine != "aurora-mysql"
  input.resource_changes[_].change.after.ca_cert_identifier == ""
  msg := "RDS instances must use proper CA certificate for SSL/TLS encryption"
}