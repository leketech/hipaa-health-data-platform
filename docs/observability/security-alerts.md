# Security Alerts for HIPAA-Compliant Health Platform

## Critical Security Alerts Requiring Immediate Response

### Unauthorized PHI Access
- **Description**: Detection of access attempts to protected health information from unauthorized sources
- **Severity**: Critical (P1)
- **Response Time**: Within 15 minutes
- **Alert Channels**: SNS, Slack, PagerDuty
- **Triggers**: 
  - Access attempts from unexpected IP ranges
  - Access during unusual hours
  - Access by users without proper authorization
  - Bulk data access patterns

### IAM Permission Changes
- **Description**: Modifications to identity and access management permissions
- **Severity**: High (P2)
- **Response Time**: Within 1 hour
- **Alert Channels**: SNS, Email
- **Triggers**:
  - New admin privileges granted
  - Changes to critical IAM roles/policies
  - User access to sensitive resources
  - Service role modifications

### KMS Key Disable Attempts
- **Description**: Attempts to disable or delete encryption keys
- **Severity**: Critical (P1)
- **Response Time**: Within 15 minutes
- **Alert Channels**: SNS, Slack, PagerDuty
- **Triggers**:
  - KMS key deletion
  - KMS key disablement
  - Changes to KMS key policies affecting access

### Unusual Authentication Patterns
- **Description**: Abnormal login patterns that may indicate compromised credentials
- **Severity**: High (P2)
- **Response Time**: Within 1 hour
- **Alert Channels**: SNS, Email
- **Triggers**:
  - Multiple failed login attempts
  - Logins from geographically distant locations in short timeframes
  - New device registrations
  - Unusual access times

### Network Intrusion Detection
- **Description**: Detection of potential network-based attacks
- **Severity**: High (P2)
- **Response Time**: Within 1 hour
- **Alert Channels**: SNS, Security Team
- **Triggers**:
  - Suspicious traffic patterns
  - Port scanning activity
  - DDoS attack indicators
  - Malicious IP address detection

## Alert Configuration Examples

### CloudWatch Alarm for Unauthorized PHI Access
```json
{
  "AlarmName": "UnauthorizedPHIAccessAlarm",
  "ComparisonOperator": "GreaterThanThreshold",
  "EvaluationPeriods": 1,
  "MetricName": "UnauthorizedAccess",
  "Namespace": "HIPAA/PHI",
  "Period": 300,
  "Statistic": "Sum",
  "Threshold": 0,
  "ActionsEnabled": true,
  "AlarmActions": [
    "arn:aws:sns:us-east-1:123456789012:security-alarms"
  ],
  "AlarmDescription": "Alert when unauthorized access to PHI is detected",
  "Dimensions": [
    {
      "Name": "Service",
      "Value": "S3"
    }
  ]
}
```

### GuardDuty Finding Detection
```yaml
# EventBridge rule to trigger on GuardDuty findings
Resources:
  SecurityAlertRule:
    Type: AWS::Events::Rule
    Properties:
      Description: Trigger security alert on GuardDuty findings
      EventPattern:
        source:
          - "aws.guardduty"
        detail-type:
          - "GuardDuty Finding"
        detail:
          severity:
            - 7
            - 8
            - 9
            - 10
      State: ENABLED
      Targets:
        - Arn: !GetAtt SecurityAlertFunction.Arn
          Id: "SecurityAlertFunction"
```

## Alert Escalation Procedures

### Level 1 (P4/P5) - Informational
- Automated logging
- Daily summary reports
- No immediate response required

### Level 2 (P3) - Low Priority
- Email notification to on-call team
- Response within 4 hours
- Standard ticket creation

### Level 3 (P2) - High Priority
- Email and SMS notification
- Response within 1 hour
- Incident ticket creation
- Manager notification

### Level 4 (P1) - Critical
- Immediate SMS and phone call
- Response within 15 minutes
- Incident commander notification
- Executive notification
- Emergency response procedures

## False Positive Handling
- Each alert includes confidence scoring
- Allow-list for known good patterns
- Automatic suppression of repeated false positives
- Regular review and tuning process