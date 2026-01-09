# Observability & Security Documentation

This directory contains all documentation related to the observability and security features of the HIPAA-compliant health data platform.

## Files Overview

### `index.md`
Comprehensive overview of the observability strategy, including metrics collection, logging architecture, distributed tracing, alerting framework, and dashboard configurations.

### `security-alerts.md`
Detailed documentation of security alerts for the platform, including critical alerts requiring immediate response, configuration examples, and alert escalation procedures.

### `secrets-management.md`
Documentation of the secrets and configuration management approach, including security principles, implementation details, security gates, compliance considerations, and best practices.

## Key Features Implemented

### CI/CD Security Gates
- **terraform-validate**: Validates Terraform configuration syntax and structure
- **trivy-iac**: Scans infrastructure code for security vulnerabilities
- **opa-policy**: Enforces policy-as-code compliance using Open Policy Agent
- **signed-artifacts**: Verifies cryptographic signatures on deployment artifacts

### Observability Stack
- **Metrics**: Amazon Managed Prometheus for EKS and application metrics
- **Logging**: Centralized logging with CloudWatch and structured JSON logs
- **Tracing**: AWS X-Ray for distributed tracing
- **Alerting**: Comprehensive alerting system with multiple severity levels

### Security Monitoring
- Unauthorized PHI access detection
- IAM permission change monitoring
- KMS key disablement attempts
- Unusual authentication pattern detection
- Network intrusion detection

### Compliance Features
- HIPAA-compliant logging (no PHI in logs)
- Automatic secret rotation
- Audit trail for all access
- Immutable audit logging with S3 Object Lock