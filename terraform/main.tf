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
  tags               = var.tags

  depends_on = [
    module.account_setup
  ]
}

module "identity" {
  source = "./identity"

  cognito_user_pool_name    = var.cognito_user_pool_name
  cognito_app_client_name   = var.cognito_app_client_name
  organization_name         = var.organization_name
  external_id               = var.cognito_external_id
  tags                      = var.tags

  depends_on = [
    module.account_setup
  ]
}

module "s3" {
  source = "./s3"

  organization_name              = var.organization_name
  s3_phidata_bucket_name       = var.s3_phidata_bucket_name
  enable_cross_region_replication = var.enable_cross_region_replication
  secondary_region             = var.secondary_region
  kms_s3_key_arn               = module.kms.s3_key_arn
  replication_role_arn         = module.security.s3_replication_role_arn
  tags                         = var.tags

  depends_on = [
    module.kms,
    module.security
  ]
}

module "rds" {
  source = "./rds"

  organization_name      = var.organization_name
  db_instance_class      = var.rds_instance_class
  db_allocated_storage   = var.rds_allocated_storage
  db_storage_encrypted   = var.rds_storage_encrypted
  db_kms_key_arn         = module.kms.rds_key_arn
  db_subnet_group_name   = module.networking.db_subnet_group_name
  vpc_security_group_ids = [module.networking.default_security_group_id]
  db_password            = var.db_password
  tags                   = var.tags

  depends_on = [
    module.kms,
    module.networking
  ]
}

module "eks" {
  source = "./eks"

  cluster_name           = var.eks_cluster_name
  cluster_version        = var.eks_version
  worker_instance_type   = var.eks_worker_instance_type
  min_size              = var.eks_min_size
  max_size              = var.eks_max_size
  cluster_vpc_id         = module.networking.vpc_id
  cluster_subnet_ids     = module.networking.private_subnet_ids
  cluster_security_group = module.networking.default_security_group_id
  organization_name      = var.organization_name
  tags                   = var.tags

  depends_on = [
    module.networking
  ]
}

module "logging" {
  source = "./logging"

  vpc_id                 = module.networking.vpc_id
  cloudwatch_log_group_arns = [
    aws_cloudwatch_log_group.eks_control_plane.arn,
    aws_cloudwatch_log_group.vpc_flow_logs.arn
  ]
  tags                   = var.tags
}

module "backup" {
  source = "./backup"

  organization_name                 = var.organization_name
  tags                             = var.tags
  kms_backup_key_arn               = module.kms.backup_key_arn
  backup_role_arn                  = module.security.backup_role_arn
  rds_instance_arn                 = module.rds.db_instance_arn
  ebs_volume_arns                  = []  # Would be populated with actual EBS volumes
  efs_file_system_arn              = ""  # Would be populated if using EFS
  enable_cross_region_replication  = var.enable_cross_region_replication
  source_bucket_id                 = module.s3.phidata_bucket_id
  dr_bucket_arn                    = module.s3.dr_bucket_arn
  replication_role_arn             = module.s3.replication_role_arn
  create_read_replica              = var.enable_cross_region_replication
  primary_rds_instance_id          = module.rds.db_instance_identifier
  secondary_region                 = var.secondary_region
  dr_db_subnet_group_name          = ""  # Would be populated with actual DR subnet group
  create_dr_bucket                 = var.enable_cross_region_replication
  kms_s3_key_arn                   = module.kms.s3_key_arn
  alert_sns_topic_arn              = module.logging.alert_topic_arn

  depends_on = [
    module.kms,
    module.s3,
    module.rds,
    module.security,
    module.logging
  ]
}