# Main module for HIPAA-compliant health data platform
# Orchestrates all modules in the correct order

module "account_setup" {
  source = "./account-setup"

  organization_name          = var.organization_name
  security_account_email    = var.security_account_email
  shared_services_account_email = var.shared_services_account_email
  prod_account_email        = var.prod_account_email
  tags                      = var.tags
}

module "kms" {
  source = "./kms"

  organization_name = var.organization_name
  tags              = var.tags
}

module "networking" {
  source = "./networking"

  vpc_cidr           = var.vpc_cidr
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
  organization_name  = var.organization_name
  primary_region     = var.primary_region
  eks_cluster_name   = var.eks_cluster_name
  tags               = var.tags
}

module "identity" {
  source = "./identity"

  cognito_user_pool_name  = var.cognito_user_pool_name
  cognito_app_client_name = var.cognito_app_client_name
  organization_name       = var.organization_name
  callback_urls           = var.callback_urls
  logout_urls             = var.logout_urls
  tags                    = var.tags

  depends_on = [
    module.networking,
    module.kms
  ]
}

module "s3" {
  source = "./s3"

  s3_phidata_bucket_name            = var.s3_phidata_bucket_name
  organization_name                 = var.organization_name
  kms_s3_key_arn                  = module.kms.s3_key_arn
  enable_cross_region_replication   = var.enable_cross_region_replication
  tags                            = var.tags

  depends_on = [
    module.kms
  ]
}

module "eks" {
  source = "./eks"

  eks_cluster_name          = var.eks_cluster_name
  eks_version              = var.eks_version
  eks_worker_instance_type = var.eks_worker_instance_type
  eks_min_size             = var.eks_min_size
  eks_max_size             = var.eks_max_size
  eks_desired_size         = var.eks_desired_size
  organization_name        = var.organization_name
  subnet_ids               = module.networking.private_subnet_ids
  vpc_id                   = module.networking.vpc_id
  kms_eks_secrets_key_arn  = module.kms.eks_secrets_key_arn
  kms_ebs_key_arn          = module.kms.ebs_key_arn
  ec2_ssh_key_name         = var.ec2_ssh_key_name
  tags                     = var.tags

  depends_on = [
    module.networking,
    module.kms
  ]
}

module "rds" {
  source = "./rds"

  organization_name       = var.organization_name
  rds_instance_class    = var.rds_instance_class
  rds_allocated_storage = var.rds_allocated_storage
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  kms_rds_key_arn       = module.kms.rds_key_arn
  subnet_ids            = module.networking.private_subnet_ids
  vpc_id                = module.networking.vpc_id
  eks_security_group_id = module.eks.node_security_group_id
  alert_sns_topic_arn   = var.alert_sns_topic_arn
  tags                  = var.tags

  depends_on = [
    module.networking,
    module.kms,
    module.eks
  ]
}

module "logging" {
  source = "./logging"

  organization_name         = var.organization_name
  log_bucket_name           = module.s3.phidata_bucket_id
  config_bucket_name        = "${var.organization_name}-config-bucket"
  config_sns_topic_arn      = var.config_sns_topic_arn
  alert_sns_topic_arn       = var.alert_sns_topic_arn
  primary_region            = var.primary_region
  eks_cluster_name          = var.eks_cluster_name
  log_bucket_account_id     = data.aws_caller_identity.current.account_id
  log_bucket_owner_email    = var.security_account_email
  tags                      = var.tags

  depends_on = [
    module.s3,
    module.eks
  ]
}

module "security" {
  source = "./security"

  organization_name              = var.organization_name
  domain_name                  = var.domain_name
  subject_alternative_names    = var.subject_alternative_names
  kms_backup_key_arn           = module.kms.kms_key_arn  # Using general KMS key for backup
  kms_secrets_key_arn          = module.kms.secrets_key_arn
  kms_ssm_key_arn              = module.kms.kms_key_arn  # Using general KMS key for SSM
  rds_instance_arn             = module.rds.db_instance_arn
  eks_node_ebs_arns            = []  # Would be populated with actual ARNs
  primary_region               = var.primary_region
  eks_cluster_name             = var.eks_cluster_name
  install_gatekeeper           = var.install_gatekeeper
  vpc_id                       = module.networking.vpc_id
  eks_node_security_group_id   = module.eks.node_security_group_id
  db_username                  = var.db_username
  db_password                  = var.db_password
  environment_config           = var.environment_config
  tags                         = var.tags

  depends_on = [
    module.kms,
    module.eks,
    module.rds,
    module.s3
  ]
}

# Data sources
data "aws_caller_identity" "current" {}