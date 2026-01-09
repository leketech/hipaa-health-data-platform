# EKS module for HIPAA-compliant health data platform
# Creates private EKS cluster with security controls

# EKS cluster (private endpoint only)
resource "aws_eks_cluster" "main" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true  # Private access only for HIPAA compliance
    endpoint_public_access  = false # No public access for HIPAA compliance
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  encryption_config {
    provider {
      key_arn = var.kms_eks_secrets_key_arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = merge(var.tags, {
    Name = "${var.organization_name}-eks-cluster"
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]
}

# EKS node group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.eks_cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.subnet_ids

  ami_type       = "AL2_x86_64"
  disk_size      = 50
  instance_types = [var.eks_worker_instance_type]

  remote_access {
    ec2_ssh_key = var.ec2_ssh_key_name
  }

  scaling_config {
    desired_size = var.eks_desired_size
    max_size     = var.eks_max_size
    min_size     = var.eks_min_size
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure all EKS nodes are encrypted with KMS
  launch_template {
    name    = aws_launch_template.eks_node.id
    version = "$Latest"
  }

  tags = merge(var.tags, {
    Name = "${var.organization_name}-eks-node-group"
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_registry_policy,
  ]
}

# Launch template for EKS nodes with KMS encryption
resource "aws_launch_template" "eks_node" {
  name_prefix   = "${var.eks_cluster_name}-node-template"
  image_id      = data.aws_ami.eks_worker.id
  instance_type = var.eks_worker_instance_type

  vpc_security_group_ids = [aws_security_group.eks_nodes.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.eks_node_profile.name
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.organization_name}-eks-node"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name = "${var.organization_name}-eks-node-volume"
    })
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    
    ebs {
      volume_size           = 50
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = var.kms_ebs_key_arn
    }
  }

  tags = merge(var.tags, {
    Name = "${var.organization_name}-eks-launch-template"
  })
}

# Get latest EKS-optimized AMI
data "aws_ami" "eks_worker" {
  most_recent = true
  owners      = ["602401143452"]  # AWS EKS AMI owner

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.eks_version}-v*"]
  }
}

# IAM role for EKS cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.organization_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

# IAM role for EKS node group
resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.organization_name}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_logging_policy" {
  policy_arn = aws_cloudwatch_eks_policy.arn
  role       = aws_iam_role.eks_node_group_role.name
}

# IAM instance profile for EKS nodes
resource "aws_iam_instance_profile" "eks_node_profile" {
  name = "${var.organization_name}-eks-node-profile"
  role = aws_iam_role.eks_node_group_role.name
}

# Security group for EKS cluster control plane
resource "aws_security_group" "eks_cluster" {
  name        = "${var.organization_name}-eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.organization_name}-eks-cluster-sg"
  })
}

# Security group for EKS worker nodes
resource "aws_security_group" "eks_nodes" {
  name        = "${var.organization_name}-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.organization_name}-eks-nodes-sg"
  })
}

# Allow nodes to communicate with the cluster API server
resource "aws_security_group_rule" "eks_cluster_to_nodes" {
  security_group_id = aws_security_group.eks_cluster.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  source_security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow pods to communicate with the cluster API server"
}

resource "aws_security_group_rule" "nodes_to_cluster" {
  security_group_id = aws_security_group.eks_nodes.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  source_security_group_id = aws_security_group.eks_cluster.id
  description       = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
}

# Allow nodes to communicate with each other (for pod networking)
resource "aws_security_group_rule" "nodes_to_nodes" {
  security_group_id = aws_security_group.eks_nodes.id
  type              = "ingress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  source_security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow nodes to communicate with each other"
}

# CloudWatch log group for EKS logs
resource "aws_cloudwatch_log_group" "eks_cluster_logs" {
  name              = "/aws/eks/${var.eks_cluster_name}/cluster"
  retention_in_days = 365  # HIPAA requirement for audit logs

  tags = merge(var.tags, {
    Name = "${var.organization_name}-eks-cluster-log-group"
  })
}

# CloudWatch log group for EKS nodes
resource "aws_cloudwatch_log_group" "eks_node_logs" {
  name              = "/aws/eks/${var.eks_cluster_name}/nodes"
  retention_in_days = 365  # HIPAA requirement for audit logs

  tags = merge(var.tags, {
    Name = "${var.organization_name}-eks-node-log-group"
  })
}

# CloudWatch policy for EKS logging
resource "aws_iam_policy" "cloudwatch_eks_policy" {
  name        = "${var.organization_name}-cloudwatch-eks-policy"
  description = "Policy for EKS to send logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          aws_cloudwatch_log_group.eks_cluster_logs.arn,
          aws_cloudwatch_log_group.eks_node_logs.arn
        ]
      }
    ]
  })
}

# Add the cluster creator to the aws-auth configmap
resource "aws_eks_addon" "aws_lb_controller" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-load-balancer-controller"
  
  tags = merge(var.tags, {
    Name = "${var.organization_name}-lb-controller-addon"
  })
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
  
  tags = merge(var.tags, {
    Name = "${var.organization_name}-vpc-cni-addon"
  })
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
  
  tags = merge(var.tags, {
    Name = "${var.organization_name}-coredns-addon"
  })
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
  
  tags = merge(var.tags, {
    Name = "${var.organization_name}-kube-proxy-addon"
  })
}