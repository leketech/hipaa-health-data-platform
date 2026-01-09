# Architecture Documentation

## System Architecture

The HIPAA-compliant health data platform is built on AWS with a focus on security, compliance, and operational excellence.

### High-Level Architecture

```
Internet
    ↓
API Gateway + WAF
    ↓
Application Load Balancer
    ↓
EKS Cluster (Private)
    ↓
RDS PostgreSQL (Encrypted)
S3 PHI Storage (Object Lock)
```

### Component Details

#### Identity & Access Management
- **Amazon Cognito**: User authentication with MFA enforcement
- **User Groups**: Admin, Clinician, Patient with role-based access control
- **OAuth 2.0**: Secure token-based authentication

#### Compute Layer
- **Amazon EKS**: Private Kubernetes cluster with no public endpoints
- **EKS Add-ons**: VPC CNI, CoreDNS, Kube-Proxy, AWS Load Balancer Controller
- **Node Groups**: Auto-scaling with KMS-encrypted EBS volumes

#### Data Layer
- **Amazon RDS**: PostgreSQL with Multi-AZ, KMS encryption
- **Amazon S3**: PHI storage with Object Lock and SSE-KMS
- **AWS Secrets Manager**: Encrypted storage for sensitive configuration

#### Network Layer
- **Private VPC**: No public subnets or internet gateways
- **VPC Endpoints**: Private connectivity to AWS services
- **Security Groups**: Least-privilege network access

#### Security & Compliance
- **AWS KMS**: Customer-managed encryption keys
- **AWS CloudTrail**: Comprehensive API logging
- **AWS GuardDuty**: Threat detection
- **AWS Security Hub**: Centralized security findings
- **AWS Config**: Configuration compliance

#### Observability
- **Amazon CloudWatch**: Metrics and logs
- **AWS X-Ray**: Distributed tracing
- **CloudWatch Dashboards**: Custom security dashboards

### Data Flow

1. Users authenticate via Cognito
2. Requests enter through API Gateway (protected by WAF)
3. Traffic routed through Application Load Balancer to EKS
4. Application pods in EKS access RDS and S3 via private VPC endpoints
5. All data encrypted at rest and in transit
6. All activities logged for audit purposes

### Compliance Considerations

- **Encryption**: All data encrypted at rest and in transit
- **Access Control**: MFA enforcement and RBAC
- **Audit Logging**: Immutable logs with Object Lock
- **Network Isolation**: Private VPC with no public access
- **Backup & DR**: Automated backups with cross-region replication