module "alb" {
  source                     = "./modules/alb"
  prefix                     = var.prefix
  vpc_id                     = var.vpc_id
  internal                   = var.internal
  alb_subnets                = var.alb_subnets
  enable_deletion_protection = var.enable_deletion_protection
  access_logs_bucket         = var.access_logs_bucket
  access_logs_prefix         = var.access_logs_prefix
  aws_account_id             = var.aws_account_id
  target_group_name          = var.target_group_name
  target_group_port          = var.target_group_port
  health_check_path          = var.health_check_path
}

module "endpoint" {
  source          = "./modules/endpoint"
  vpc_id          = var.vpc_id
  region          = var.region
  subnet_ids      = var.subnet_ids
  route_table_ids = var.route_table_ids
  prefix          = var.prefix
}

module "eks" {
  source                   = "./modules/eks"
  environment              = var.environment
  Account_ID               = var.Account_ID
  vpc_id                   = var.vpc_id
  prefix                   = var.prefix
  max_unavailable          = var.max_unavailable
  cluster_name             = var.cluster_name
  cluster_version          = var.cluster_version
  subnet_ids               = var.subnet_ids
  enable_cluster_log_types = var.enable_cluster_log_types
  desired_size             = var.desired_size
  max_size                 = var.max_size
  min_size                 = var.min_size
  iam_roles                = var.iam_roles
}

module "efs" {
  source               = "./modules/efs"
  environment          = var.environment
  vpc_id               = var.vpc_id
  subnet_ids           = var.subnet_ids
  efs_performance_mode = var.efs_performance_mode
  efs_throughput_mode  = var.efs_throughput_mode
}

module "nlb-alb" {
  source     = "./modules/nlb-alb"
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
}

module "ec2" {
  source        = "./modules/ec2"
  environment   = var.environment
  prefix        = var.prefix
  vpc_id        = var.vpc_id
  ec2_key_name  = var.ec2_key_name
  os_type       = var.os_type
  kms_key_id    = var.kms_key_id
  Account_ID    = var.Account_ID
  region        = var.region
  servers       = var.servers
}

module "rds" {
  source                  = "./modules/rds"
  environment             = var.environment
  vpc_id                  = var.vpc_id
  prefix                  = var.prefix
  subnet_ids              = var.subnet_ids
  db_name                 = var.db_name
  username                = var.username
  instance_class          = var.instance_class
  engine_version          = var.engine_version
  monitoring_interval     = var.monitoring_interval
  skip_final_snapshot     = var.skip_final_snapshot
  multi_az                = var.multi_az
  cloudwatch_log_types    = var.cloudwatch_log_types
  parameter_group_family  = var.parameter_group_family
  db_parameters           = var.db_parameters
  allocated_storage       = var.allocated_storage
}

module "transferfamily" {
  source = "./modules/transferfamily"
  vpc_id = var.vpc_id
  sftp_bucket = var.sftp_bucket
  subnet_ids = var.subnet_ids
  environment             = var.environment
}
