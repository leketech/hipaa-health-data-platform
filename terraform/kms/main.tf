# KMS module for HIPAA-compliant health data platform
# Creates customer managed keys for encryption of all PHI data

# KMS key for RDS encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption - HIPAA compliant"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  policy = data.aws_iam_policy_document.kms_rds.json

  tags = merge(var.tags, {
    Name = "${var.organization_name}-rds-kms-key"
  })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.organization_name}-rds-key"
  target_key_id = aws_kms_key.rds.key_id
}

# KMS key for S3 encryption
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 encryption - HIPAA compliant"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  policy = data.aws_iam_policy_document.kms_s3.json

  tags = merge(var.tags, {
    Name = "${var.organization_name}-s3-kms-key"
  })
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.organization_name}-s3-key"
  target_key_id = aws_kms_key.s3.key_id
}

# KMS key for EBS volumes (EKS nodes)
resource "aws_kms_key" "ebs" {
  description             = "KMS key for EBS encryption - HIPAA compliant"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  policy = data.aws_iam_policy_document.kms_ebs.json

  tags = merge(var.tags, {
    Name = "${var.organization_name}-ebs-kms-key"
  })
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.organization_name}-ebs-key"
  target_key_id = aws_kms_key.ebs.key_id
}

# KMS key for Secrets Manager
resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager encryption - HIPAA compliant"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  policy = data.aws_iam_policy_document.kms_secrets.json

  tags = merge(var.tags, {
    Name = "${var.organization_name}-secrets-kms-key"
  })
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.organization_name}-secrets-key"
  target_key_id = aws_kms_key.secrets.key_id
}

# KMS key for EKS secrets
resource "aws_kms_key" "eks_secrets" {
  description             = "KMS key for EKS secrets encryption - HIPAA compliant"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  policy = data.aws_iam_policy_document.kms_eks_secrets.json

  tags = merge(var.tags, {
    Name = "${var.organization_name}-eks-secrets-kms-key"
  })
}

resource "aws_kms_alias" "eks_secrets" {
  name          = "alias/${var.organization_name}-eks-secrets-key"
  target_key_id = aws_kms_key.eks_secrets.key_id
}

# KMS key policy for RDS
data "aws_iam_policy_document" "kms_rds" {
  statement {
    sid = "Enable IAM User Permissions"
    effect = "Allow"
    
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    
    actions = [
      "kms:*"
    ]
    
    resources = ["*"]
  }

  statement {
    sid = "Allow RDS service to use the key"
    effect = "Allow"
    
    principals {
      type = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
    
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]
    
    resources = ["*"]
  }

  statement {
    sid = "Allow VPC endpoints to use the key"
    effect = "Allow"
    
    principals {
      type = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    
    resources = ["*"]
  }
}

# KMS key policy for S3
data "aws_iam_policy_document" "kms_s3" {
  statement {
    sid = "Enable IAM User Permissions"
    effect = "Allow"
    
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    
    actions = [
      "kms:*"
    ]
    
    resources = ["*"]
  }

  statement {
    sid = "Allow S3 service to use the key"
    effect = "Allow"
    
    principals {
      type = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]
    
    resources = ["*"]
  }

  statement {
    sid = "Allow VPC endpoints to use the key"
    effect = "Allow"
    
    principals {
      type = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    
    resources = ["*"]
  }
}

# KMS key policy for EBS
data "aws_iam_policy_document" "kms_ebs" {
  statement {
    sid = "Enable IAM User Permissions"
    effect = "Allow"
    
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    
    actions = [
      "kms:*"
    ]
    
    resources = ["*"]
  }

  statement {
    sid = "Allow EC2 service to use the key"
    effect = "Allow"
    
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    
    actions = [
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]
    
    resources = ["*"]
  }
}

# KMS key policy for Secrets Manager
data "aws_iam_policy_document" "kms_secrets" {
  statement {
    sid = "Enable IAM User Permissions"
    effect = "Allow"
    
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    
    actions = [
      "kms:*"
    ]
    
    resources = ["*"]
  }

  statement {
    sid = "Allow Secrets Manager service to use the key"
    effect = "Allow"
    
    principals {
      type = "Service"
      identifiers = ["secretsmanager.amazonaws.com"]
    }
    
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]
    
    resources = ["*"]
  }
}

# KMS key policy for EKS secrets
data "aws_iam_policy_document" "kms_eks_secrets" {
  statement {
    sid = "Enable IAM User Permissions"
    effect = "Allow"
    
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    
    actions = [
      "kms:*"
    ]
    
    resources = ["*"]
  }

  statement {
    sid = "Allow EKS service to use the key"
    effect = "Allow"
    
    principals {
      type = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]
    
    resources = ["*"]
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}