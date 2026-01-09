# Networking module for HIPAA-compliant health data platform
# Creates private VPC with endpoints and no public access

# VPC for the HIPAA-compliant infrastructure
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.organization_name}-vpc"
  })
}

# Internet gateway (will not be used - VPC is private)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.organization_name}-igw"
  })

  # Prevent attachment for HIPAA compliance - no public access
  count = 0
}

# Private subnets for the HIPAA infrastructure
resource "aws_subnet" "private" {
  count                   = length(var.private_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.organization_name}-private-subnet-${count.index + 1}"
    # Required for EKS private subnets
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  })
}

# NAT Gateway setup (for outbound internet access for updates, etc.)
# In a true HIPAA environment, this would also be disabled
# Using NAT instances in private subnets instead for compliance
# NAT Gateway setup (for outbound internet access for updates, etc.)
# In a true HIPAA environment, this would also be disabled
# Using NAT instances in private subnets instead for compliance
resource "aws_eip" "nat" {
  count      = 0  # Disable NAT for HIPAA compliance - no outbound access
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.tags, {
    Name = "${var.organization_name}-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "main" {
  count         = 0  # Disable NAT for HIPAA compliance - no outbound access
  subnet_id     = aws_subnet.private[0].id  # Only in public subnet if needed
  allocation_id = aws_eip.nat[0].id

  tags = merge(var.tags, {
    Name = "${var.organization_name}-nat-gateway-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# Route tables for private subnets (no internet access)
resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.organization_name}-private-rt-${count.index + 1}"
  })
}

# Associate private subnets with route tables
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# VPC endpoints for private access to AWS services
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.primary_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = aws_route_table.private[*].id

  tags = merge(var.tags, {
    Name = "${var.organization_name}-s3-vpce"
  })
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.primary_region}.sts"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpce_sts.id]

  tags = merge(var.tags, {
    Name = "${var.organization_name}-sts-vpce"
  })
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.primary_region}.kms"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpce_kms.id]

  tags = merge(var.tags, {
    Name = "${var.organization_name}-kms-vpce"
  })
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.primary_region}.ec2"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpce_ec2.id]

  tags = merge(var.tags, {
    Name = "${var.organization_name}-ec2-vpce"
  })
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.primary_region}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpce_ecr.id]

  tags = merge(var.tags, {
    Name = "${var.organization_name}-ecr-api-vpce"
  })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.primary_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpce_ecr.id]

  tags = merge(var.tags, {
    Name = "${var.organization_name}-ecr-dkr-vpce"
  })
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.primary_region}.logs"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpce_logs.id]

  tags = merge(var.tags, {
    Name = "${var.organization_name}-logs-vpce"
  })
}

resource "aws_vpc_endpoint" "monitoring" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.primary_region}.monitoring"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpce_monitoring.id]

  tags = merge(var.tags, {
    Name = "${var.organization_name}-monitoring-vpce"
  })
}

# Security groups for VPC endpoints
resource "aws_security_group" "vpce_sts" {
  name        = "${var.organization_name}-vpce-sts"
  description = "Security group for STS VPC endpoint"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.organization_name}-vpce-sts-sg"
  })
}

resource "aws_security_group" "vpce_kms" {
  name        = "${var.organization_name}-vpce-kms"
  description = "Security group for KMS VPC endpoint"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.organization_name}-vpce-kms-sg"
  })
}

resource "aws_security_group" "vpce_ec2" {
  name        = "${var.organization_name}-vpce-ec2"
  description = "Security group for EC2 VPC endpoint"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.organization_name}-vpce-ec2-sg"
  })
}

resource "aws_security_group" "vpce_ecr" {
  name        = "${var.organization_name}-vpce-ecr"
  description = "Security group for ECR VPC endpoints"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.organization_name}-vpce-ecr-sg"
  })
}

resource "aws_security_group" "vpce_logs" {
  name        = "${var.organization_name}-vpce-logs"
  description = "Security group for CloudWatch Logs VPC endpoint"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.organization_name}-vpce-logs-sg"
  })
}

resource "aws_security_group" "vpce_monitoring" {
  name        = "${var.organization_name}-vpce-monitoring"
  description = "Security group for CloudWatch Monitoring VPC endpoint"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.organization_name}-vpce-monitoring-sg"
  })
}

# VPC flow logs for audit and compliance
resource "aws_flow_log" "vpc_flow_logs" {
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_group_name  = aws_cloudwatch_log_group.vpc_flow_logs.name
  resource_id     = aws_vpc.main.id
  resource_type   = "VPC"
  traffic_type    = "ALL"
  max_aggregation_interval = 60

  tags = merge(var.tags, {
    Name = "${var.organization_name}-vpc-flow-logs"
  })
}

# CloudWatch log group for VPC flow logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs/${var.organization_name}"
  retention_in_days = 365  # HIPAA requirement for audit logs

  tags = merge(var.tags, {
    Name = "${var.organization_name}-vpc-flow-logs-group"
  })
}