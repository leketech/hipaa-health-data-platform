# Threat Model for HIPAA-Compliant Health Data Platform

## Overview
This document outlines the threat model for the HIPAA-compliant health data platform, identifying potential threats, vulnerabilities, and countermeasures to protect Protected Health Information (PHI).

## Assets Classification

### High Sensitivity Assets
- **PHI Data**: All patient health information stored in RDS and S3
- **Authentication Credentials**: Cognito user credentials and API keys
- **Encryption Keys**: KMS master keys for data encryption
- **System Configuration**: Infrastructure as code and system settings

### Medium Sensitivity Assets
- **System Logs**: CloudTrail, VPC Flow Logs, EKS audit logs
- **Access Patterns**: User access logs and behavioral analytics
- **System Metadata**: Resource identifiers and configurations

## Threat Agents

### External Threats
- **Advanced Persistent Threats (APTs)**: Nation-state actors targeting healthcare data
- **Cyber Criminals**: Organized crime groups seeking financial gain
- **Script Kiddies**: Opportunistic attackers using automated tools
- **Competitors**: Healthcare organizations seeking competitive advantage

### Internal Threats
- **Malicious Insiders**: Disgruntled employees with authorized access
- **Negligent Users**: Employees who accidentally expose data
- **Compromised Accounts**: Legitimate accounts taken over by attackers

## Attack Vectors

### Network-Based Attacks
- **Man-in-the-Middle (MITM)**: Intercepting data in transit
- **Denial of Service (DoS)**: Overwhelming system resources
- **Network Sniffing**: Capturing unencrypted network traffic
- **DNS Hijacking**: Redirecting traffic to malicious endpoints

### Application-Level Attacks
- **SQL Injection**: Exploiting database query vulnerabilities
- **Cross-Site Scripting (XSS)**: Injecting malicious scripts
- **API Abuse**: Exploiting insecure API endpoints
- **OAuth Misuse**: Exploiting authentication vulnerabilities

### Data-Level Attacks
- **Unauthorized Access**: Accessing PHI without proper authorization
- **Data Exfiltration**: Moving PHI outside authorized systems
- **Data Modification**: Changing PHI without authorization
- **Credential Theft**: Stealing authentication credentials

## Threat Scenarios

### Scenario 1: EKS Cluster Compromise
**Threat**: An attacker gains access to the EKS cluster and can access PHI data
**Impact**: High - Potential exposure of all PHI data
**Likelihood**: Low - Mitigated by strong access controls
**Countermeasures**:
- Implement IAM Roles for Service Accounts (IRSA)
- Use network policies to restrict pod communication
- Enable EKS audit logging
- Implement least-privilege access

### Scenario 2: RDS Data Breach
**Threat**: Unauthorized access to the PostgreSQL database containing PHI
**Impact**: High - Direct access to patient health records
**Likelihood**: Low - Mitigated by encryption and access controls
**Countermeasures**:
- KMS encryption at rest
- TLS 1.2+ encryption in transit
- Network isolation in private subnets
- Database activity monitoring

### Scenario 3: S3 Bucket Compromise
**Threat**: Unauthorized access to S3 bucket containing PHI
**Impact**: High - Potential exposure of all stored PHI data
**Likelihood**: Low - Mitigated by encryption and access policies
**Countermeasures**:
- Server-side encryption with KMS keys
- S3 Object Lock for immutable audit logging
- Bucket policies restricting access
- Access logging and monitoring

### Scenario 4: Cognito Credential Compromise
**Threat**: Stolen credentials allowing unauthorized access to system
**Impact**: Medium-High - Potential access to PHI based on user permissions
**Likelihood**: Medium - Possible through phishing or social engineering
**Countermeasures**:
- Mandatory MFA for all users
- Session timeout and re-authentication
- Account lockout policies
- Continuous monitoring of authentication events

## Security Controls Mapping

### Preventive Controls
- **Network Segmentation**: VPC private subnets with no internet access
- **Encryption**: End-to-end encryption using KMS CMKs
- **Access Control**: Cognito-based authentication with RBAC
- **Input Validation**: WAF protection against injection attacks

### Detective Controls
- **Logging**: Comprehensive audit logging across all services
- **Monitoring**: Real-time monitoring with CloudWatch and Security Hub
- **Anomaly Detection**: GuardDuty for threat detection
- **Vulnerability Scanning**: Regular Trivy scans

### Corrective Controls
- **Incident Response**: Automated response to security events
- **Backup and Recovery**: AWS Backup for disaster recovery
- **Access Revocation**: Automated de-provisioning
- **Forensic Capability**: Immutable log storage

## Risk Assessment

### High-Risk Areas
1. **Identity Management**: Single point of failure for authentication
2. **Data Encryption**: Key management and rotation processes
3. **Network Perimeter**: Securing access to private resources
4. **Compliance Monitoring**: Ensuring ongoing HIPAA compliance

### Medium-Risk Areas
1. **Configuration Management**: Infrastructure as code vulnerabilities
2. **Dependency Management**: Third-party component security
3. **Staff Training**: Human factor in security posture
4. **Vendor Management**: Third-party service security

### Low-Risk Areas
1. **Physical Security**: AWS data center security
2. **Environmental Controls**: Power and cooling at AWS facilities
3. **Hardware Security**: AWS hardware security measures

## Recommendations

### Immediate Actions
1. Implement additional monitoring for anomalous access patterns
2. Conduct regular penetration testing
3. Enhance staff security awareness training
4. Establish incident response procedures

### Long-term Improvements
1. Implement zero-trust network architecture
2. Deploy advanced threat hunting capabilities
3. Establish comprehensive privacy controls
4. Integrate with existing healthcare security tools

## Review Schedule
This threat model should be reviewed and updated:
- Annually or after significant infrastructure changes
- Following any security incidents
- When new threats emerge in the healthcare sector
- After regulatory guidance updates