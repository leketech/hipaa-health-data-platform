# Deployment Guide

## Prerequisites

### AWS Account Requirements
- AWS account with administrator privileges
- AWS CLI installed and configured
- Terraform v1.0+ installed
- Access to required AWS services (EKS, RDS, S3, etc.)

### Local Environment Setup
```bash
# Install Terraform
choco install terraform  # Windows
# or
brew install terraform   # macOS

# Install AWS CLI
choco install awscli     # Windows
# or
brew install awscli      # macOS

# Configure AWS credentials
aws configure
```

## Deployment Steps

### 1. Clone the Repository
```bash
git clone https://github.com/your-org/hipaa-health-data-platform.git
cd hipaa-health-data-platform/terraform
```

### 2. Initialize Terraform
```bash
# Initialize Terraform
terraform init

# Verify the configuration
terraform validate
```

### 3. Create Terraform Variables File
Create a `terraform.tfvars` file with your specific values:

```hcl
# terraform.tfvars
organization_name = "my-hipaa-org"
security_account_email = "security@my-hipaa-org.com"
shared_services_account_email = "shared@my-hipaa-org.com"
prod_account_email = "prod@my-hipaa-org.com"
s3_phidata_bucket_name = "my-hipaa-phidata-storage"
domain_name = "my-hipaa-platform.com"
db_username = "healthadmin"
db_password = "your-secure-password-here"
```

### 4. Plan the Deployment
```bash
# Review the deployment plan
terraform plan -out=tfplan
```

### 5. Deploy the Infrastructure
```bash
# Apply the infrastructure
terraform apply tfplan
```

## Module Deployment Order

The infrastructure is deployed in the following order to satisfy dependencies:

1. **Account Setup**: Creates AWS Organizations structure
2. **KMS**: Creates customer-managed encryption keys
3. **Networking**: Sets up private VPC and endpoints
4. **Identity**: Configures Cognito user pools and groups
5. **S3**: Creates PHI data storage with Object Lock
6. **EKS**: Deploys private Kubernetes cluster
7. **RDS**: Creates encrypted PostgreSQL database
8. **Logging**: Sets up CloudTrail, GuardDuty, and monitoring
9. **Security**: Applies WAF, Backup, and additional controls

## Post-Deployment Tasks

### 1. Configure kubectl for EKS
```bash
# Configure kubectl to connect to your EKS cluster
aws eks --region $(aws configure get region) update-kubeconfig \
    --name $(terraform output -raw eks_cluster_name)

# Verify the connection
kubectl get nodes
```

### 2. Deploy Applications to EKS
```bash
# Deploy your healthcare application to EKS
kubectl apply -f ./k8s/manifests/
```

### 3. Set Up Monitoring
```bash
# Set up CloudWatch alarms and dashboards
# Configure notification channels
```

## Security Hardening

### 1. Enable Additional Security Features
```bash
# Enable AWS Macie for sensitive data discovery (if needed)
aws macie2 enable

# Configure AWS Systems Manager for patch management
aws ssm create-association \
    --name "AWS-GuardDutyRunBook" \
    --targets "Key=tag:Name,Values=hipaa-eks-node" \
    --schedule-expression "rate(30 minutes)"
```

### 2. Implement OPA/Gatekeeper Policies
```bash
# Apply OPA policies for fine-grained access control
kubectl apply -f ./k8s/policies/
```

## Backup and Recovery

### Backup Schedule
- **RDS**: Automated daily backups
- **S3**: Cross-region replication
- **EKS**: Weekly cluster backups using Velero
- **Configuration**: AWS Config continuous recording

### Recovery Procedures
1. Identify the recovery point
2. Execute recovery procedure for affected component
3. Validate data integrity
4. Update DNS if needed
5. Test functionality

## Monitoring and Maintenance

### Daily Checks
- Review Security Hub findings
- Check CloudWatch alarms
- Verify backup statuses

### Weekly Tasks
- Review CloudTrail logs
- Check GuardDuty findings
- Update security patches

### Monthly Activities
- Conduct security assessment
- Review access controls
- Update compliance documentation

## Troubleshooting

### Common Issues

#### VPC Endpoint Access Issues
- Verify VPC endpoint policies
- Check security group rules
- Confirm subnet associations

#### EKS Node Joining Issues
- Check node IAM role permissions
- Verify VPC and subnet configurations
- Review security group settings

#### Database Connection Problems
- Validate RDS security groups
- Check VPC routing
- Verify KMS key permissions

### Support Resources
- AWS Support for infrastructure issues
- Security team for compliance questions
- Operations team for monitoring alerts

## Decommissioning

### Pre-deletion Checklist
- [ ] Backup all critical data
- [ ] Export compliance reports
- [ ] Notify stakeholders
- [ ] Document lessons learned

### Cleanup Process
```bash
# Remove all Kubernetes resources
kubectl delete namespaces --all

# Destroy Terraform infrastructure
terraform destroy
```

> ⚠️ **Warning**: The destruction process will permanently delete all PHI data. Ensure all required backups are completed before proceeding.