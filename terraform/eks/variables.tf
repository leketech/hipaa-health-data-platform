# Variables for EKS module

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "hipaa-eks-cluster"
}

variable "eks_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.28"
}

variable "eks_worker_instance_type" {
  description = "Instance type for EKS worker nodes"
  type        = string
  default     = "m5.large"
}

variable "eks_min_size" {
  description = "Minimum size of EKS node group"
  type        = number
  default     = 3
}

variable "eks_max_size" {
  description = "Maximum size of EKS node group"
  type        = number
  default     = 10
}

variable "eks_desired_size" {
  description = "Desired size of EKS node group"
  type        = number
  default     = 3
}

variable "organization_name" {
  description = "Name of the organization"
  type        = string
  default     = "hipaa-health-data-platform"
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "kms_eks_secrets_key_arn" {
  description = "ARN of the KMS key to use for EKS secrets encryption"
  type        = string
}

variable "kms_ebs_key_arn" {
  description = "ARN of the KMS key to use for EBS encryption"
  type        = string
}

variable "ec2_ssh_key_name" {
  description = "Name of the SSH key pair to use for EKS nodes"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "hipaa-health-data-platform"
    Environment = "prod"
    Compliance  = "HIPAA"
    Owner       = "Healthcare Team"
  }
}