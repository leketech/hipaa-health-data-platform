# 🏥 HIPAA-Ready Health Data Platform on AWS

![HIPAA Health Data Platform Architecture](https://github.com/leketech/hipaa-health-data-platform/blob/96044c9da58e339fe693d243a089bbb17356338f/ChatGPT%20Image%20Jan%208%2C%202026%2C%2002_48_15%20PM.png)

A production-grade, compliance-first healthcare data platform designed with security, observability, and operational maturity as non-negotiable requirements.

## 📌 Project Overview

This project demonstrates how to design, build, and operate a HIPAA-ready health data platform on AWS using modern DevOps and cloud-native best practices.

The platform securely handles Protected Health Information (PHI) while enforcing:

- Strong identity and access controls
- Encryption at rest and in transit
- Immutable audit logging
- Continuous observability
- Disaster recovery and backup validation

This repository is intentionally structured to reflect real enterprise environments in regulated industries such as healthcare and fintech.

## 🎯 What This Project Proves

✅ Senior-level DevOps & Platform Engineering mindset
✅ Healthcare compliance awareness (HIPAA safeguards)
✅ Security-by-design architecture
✅ Production-ready CI/CD pipelines
✅ Operational maturity (monitoring, DR, auditability)

## 🧱 High-Level Architecture

### Request Flow

Users → Cognito → API Gateway + WAF → ALB → EKS → RDS / S3


### Control Planes

- 🔐 Security & Compliance Plane
- 📊 Observability Plane
- 💾 Backup & Disaster Recovery Plane

Full architecture diagrams are available in the /architecture directory.

## 🛠 Technology Stack

### Cloud & Infrastructure

- Amazon EKS (private cluster)
- Amazon RDS (PostgreSQL) – Multi-AZ, KMS-encrypted
- Amazon S3 – PHI storage, SSE-KMS, Object Lock
- Amazon Cognito – MFA, OAuth2, RBAC
- AWS KMS – Customer-managed keys
- AWS Backup – Cross-region DR

### Security & Compliance

- AWS CloudTrail (org-wide)
- EKS Audit Logs
- VPC Flow Logs
- AWS GuardDuty & Security Hub
- IAM Roles for Service Accounts (IRSA)
- OPA (policy-as-code)

### Observability

- Amazon CloudWatch (metrics & logs)
- Amazon Managed Prometheus
- Amazon Managed Grafana
- AWS X-Ray (distributed tracing)
- Alerts via SNS / PagerDuty

### DevOps & IaC

- Terraform (modular, multi-environment)
- GitHub Actions (secure CI/CD)
- Trivy (IaC + container scanning)
- GitOps deployment model

## 🔐 Security & HIPAA Considerations

This platform is designed to align with HIPAA Administrative, Physical, and Technical Safeguards.

### Key Controls Implemented

**Least-Privilege Access**

- IAM + IRSA per service
- No shared credentials

**Encryption Everywhere**

- KMS-encrypted RDS, S3, EBS, secrets
- TLS 1.2+ enforced

**Auditability**

- Immutable logs (S3 Object Lock)
- Centralized logging

**Data Access Governance**

- Cognito RBAC
- OPA authorization for PHI access

Compliance is treated as a system property, not a documentation exercise.

## 📊 Observability Strategy

The platform provides full visibility across metrics, logs, and traces.

### Metrics

- API latency & error rates
- EKS pod and node health
- RDS performance
- Authentication failures

### Logs

- Application logs
- EKS audit logs
- API Gateway access logs
- CloudTrail events

### Traces

- End-to-end request tracing via AWS X-Ray

### Alerting

- Security anomalies
- Unauthorized access attempts
- Infrastructure degradation
- Backup failures

## 💾 Backup & Disaster Recovery

- Automated backups using AWS Backup
- Cross-region replication
- Regular restore testing

Defined recovery objectives:

- RTO: < 1 hour
- RPO: < 15 minutes

Disaster recovery is tested, not assumed.

### Backup Strategy
- RDS automated backups with 35-day retention
- S3 versioning for data protection
- EBS volume backups with lifecycle policies
- Automated restore testing (monthly)

### Disaster Recovery Components
- RDS read replicas in secondary region
- S3 cross-region replication
- Automated failover procedures
- DR testing playbook with monthly drills

## 🚀 CI/CD Pipeline Overview

### Security-First Pipeline Stages

- Terraform format & validation
- Trivy IaC scanning (fail on HIGH)
- Container image scanning
- Policy-as-code validation
- Manual approval for production
- GitOps-based deployment to EKS

A deployment that fails security checks is considered a successful pipeline outcome.

### Pipeline Security Gates

The CI/CD pipeline implements multiple security gates to prevent misconfigurations:

- **terraform-validate**: Validates Terraform configuration syntax and structure
- **trivy-iac**: Scans infrastructure code for security vulnerabilities
- **opa-policy**: Enforces policy-as-code compliance using Open Policy Agent
- **signed-artifacts**: Verifies cryptographic signatures on deployment artifacts

## 📂 Repository Structure

```
.
├── architecture/        # Architecture diagrams & threat models
│   ├── architecture-diagram.md  # Visual architecture representations
│   └── threat-model.md  # Security threat modeling documentation
├── terraform/           # Modular Terraform infrastructure
│   ├── backup/         # Backup and disaster recovery configuration
│   ├── account-setup/  # AWS Organization and account setup
│   ├── kms/            # KMS key management
│   ├── networking/     # VPC and networking configuration
│   ├── identity/       # Cognito and identity management
│   ├── s3/             # S3 bucket configuration
│   ├── rds/            # RDS database configuration
│   ├── eks/            # EKS cluster configuration
│   ├── logging/        # Logging and monitoring configuration
│   ├── security/       # Security controls configuration
│   ├── variables.tf    # Global variables
│   ├── main.tf         # Main orchestration
│   └── outputs.tf      # Infrastructure outputs
├── k8s/                 # Kubernetes manifests & policies
├── ci-cd/               # CI/CD pipeline documentation
│   └── README.md        # Documentation for GitHub Actions workflows
├── security/            # HIPAA mappings & audit evidence
│   ├── README.md        # Security documentation overview
│   ├── hipaa-mappings.md # Mapping of controls to HIPAA requirements
│   └── audit-evidence.md # Evidence of compliance and security measures
├── docs/                # DR, observability & ops docs
│   ├── observability/   # Observability and monitoring documentation
│   │   ├── index.md     # Overview of observability strategy
│   │   ├── security-alerts.md  # Security alerting configuration
│   │   └── secrets-management.md  # Secrets management guidelines
│   ├── dr/             # Disaster recovery documentation
│   │   ├── strategy.md # DR strategy and procedures
│   │   ├── dr-testing-playbook.md  # DR testing procedures
│   │   └── backup-restore-test.sh  # Automated backup/restore testing
│   ├── compliance/     # Compliance evidence documentation
│   │   └── evidence.md # Compliance evidence and audit artifacts
│   ├── deployment-guide.md
│   ├── security.md
│   └── architecture.md
├── policy/              # OPA policies for infrastructure validation
└── README.md
```

## 🛡️ Security Best Practices & Secret Management

This project follows security best practices for handling sensitive information:

### No Hardcoded Secrets
- All sensitive values (passwords, API keys, etc.) are handled as variables
- Variables are marked as `sensitive = true` where appropriate
- Secrets are stored in AWS Secrets Manager or Parameter Store when deployed

### Recommended Secret Configuration
Create a separate `terraform.tfvars` file (not committed to version control) with sensitive values:

```hcl
# terraform/terraform.tfvars (do not commit to git)
db_password = "your-secure-password-here"
security_account_email = "security@your-organization.com"
shared_services_account_email = "shared@your-organization.com"
prod_account_email = "prod@your-organization.com"
```

### .gitignore Configuration
The project includes a comprehensive `.gitignore` file that prevents:
- Terraform state files
- Variable files containing secrets
- Local configuration files
- Certificate and key files
- Log files

### Secure Deployment Process
1. Configure AWS credentials using AWS CLI or IAM roles
2. Create `terraform.tfvars` file with your sensitive values
3. Run `terraform plan` and `terraform apply` from a secure environment
4. Store Terraform state in a secure, encrypted remote backend (S3 with KMS encryption)

## 🚀 Getting Started

### Prerequisites
- AWS account with appropriate permissions
- Terraform v1.0+
- AWS CLI configured

### Initial Setup
1. Clone the repository
2. Navigate to the `terraform/` directory
3. Create a `terraform.tfvars` file with your sensitive values (see above)
4. Run `terraform init` to initialize providers
5. Run `terraform plan` to review the planned infrastructure
6. Run `terraform apply` to deploy the infrastructure