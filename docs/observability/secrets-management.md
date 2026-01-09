# Secrets & Configuration Management for HIPAA-Compliant Platform

## Overview
This document outlines the secure management of secrets and configuration for the HIPAA-compliant health data platform, ensuring that sensitive information is properly protected and never exposed in code or logs.

## Security Principles

### No Secrets in Code
- All secrets must be stored in AWS Secrets Manager or Parameter Store
- Environment variables must not contain sensitive values
- Configuration files must not include hardcoded credentials
- Secrets must never be committed to version control

### Automatic Rotation
- Database passwords automatically rotated every 30 days
- API keys rotated based on business requirements (typically 90 days)
- Access keys rotated every 90 days
- TLS certificates renewed automatically before expiration

## Implementation

### AWS Secrets Manager
Primary storage for all sensitive information:

```hcl
# Example Terraform configuration for secrets storage
resource "aws_secretsmanager_secret" "database_credentials" {
  name = "${var.organization_name}/database/credentials"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "database_credentials_version" {
  secret_id     = aws_secretsmanager_secret.database_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}
```

### Application Configuration
Applications retrieve secrets at runtime:

```python
import boto3
import json

def get_secret(secret_name):
    """Retrieve secret from AWS Secrets Manager"""
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name='us-east-1'
    )
    
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

# Usage in application
db_creds = get_secret('hipaa-health-data-platform/database/credentials')
```

### Kubernetes Integration
Using AWS Secrets and Configuration Provider:

```yaml
apiVersion: v1
kind: SecretProviderClass
metadata:
  name: secrets-provider-class
  namespace: health-app
spec:
  provider: aws
  parameters:
    objects: |
        - objectName: "hipaa-health-data-platform/database/credentials"
          objectType: "secretsmanager"
          jmesPath:
            - path: "username"
              objectAlias: "db_username"
            - path: "password"
              objectAlias: "db_password"
  secretObjects:
    - data:
      - key: username
        objectName: db_username
      - key: password
        objectName: db_password
      secretName: database-credentials
      type: Opaque
```

## Security Gates

### Pre-deployment Validation
- Verify no secrets in configuration files
- Validate secret references exist in Secrets Manager
- Check proper IAM permissions for secret access
- Confirm automatic rotation is enabled

### Runtime Validation
- Monitor for secrets in application logs
- Alert on unauthorized secret access attempts
- Verify secret rotation is occurring as scheduled
- Check for proper encryption in transit and at rest

## Compliance Considerations

### HIPAA Requirements
- All PHI-related secrets encrypted with customer-managed KMS keys
- Detailed logging of all secret access for audit purposes
- Automatic rotation to reduce exposure risk
- Access limited to authorized personnel only

### Audit Trail
- All secret access logged to CloudTrail
- Access patterns monitored for anomalies
- Regular compliance reporting on secret management
- Integration with SIEM for security analysis

## Best Practices

### Secret Lifecycle
1. Secrets created through approved processes only
2. Automatic rotation configured at creation time
3. Regular review of access permissions
4. Secure deletion when no longer needed

### Access Control
- Principle of least privilege for secret access
- MFA required for secret management operations
- Role-based access control for different secret types
- Regular access reviews and cleanups

### Monitoring
- Alerts for unusual secret access patterns
- Notifications for rotation failures
- Dashboard for secret health monitoring
- Integration with security incident response