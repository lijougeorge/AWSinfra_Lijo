locals {
  environment     = var.environment
  project         = "dali"
  db_name_list    = var.db_name
  prefix          = "${local.environment}-${local.project}"

  common_tags = {
    Project     = local.project
    Owner       = "EvidenDevOpsTeam"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }

  rds_sg_name = "${local.prefix}-rds-sg"

  final_snapshot_ids = [
    for idx in range(length(local.db_name_list)) :
    lower("${local.prefix}-final-snapshot-${local.db_name_list[idx]}-${random_id.snapshot_suffix[idx].hex}")
  ]
}

resource "random_password" "rds_password" {
  length  = 16
  override_special = "!#$%^&*()-_+="
  special = true
}

resource "random_id" "snapshot_suffix" {
  count       = length(local.db_name_list)
  byte_length = 2
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "${local.prefix}-rds-credentials"
  description = "RDS credentials for ${local.prefix}"
  tags        = local.common_tags
}

resource "aws_secretsmanager_secret_version" "rds_credentials_version" {
  secret_id     = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.username
    password = random_password.rds_password.result
  })

  depends_on = [aws_secretsmanager_secret.rds_credentials]
}

data "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
}

resource "aws_kms_key" "db_key" {
  description             = "KMS Key for encrypting RDS"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"
  rotation_period_in_days = 365
}

resource "aws_kms_alias" "db_key_alias" {
  name          = "alias/rds-encryption-key"
  target_key_id = aws_kms_key.db_key.id
}

resource "aws_security_group" "rds_sg" {
  name        = local.rds_sg_name
  description = "Security group for RDS access"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.160.56.0/22"]
    description = "Allow RDS traffic from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    {
      Name = local.rds_sg_name
    },
    local.common_tags
  )
}

resource "aws_db_subnet_group" "rds_subnet" {
  name       = lower("${local.prefix}-rds-subnet")
  subnet_ids = var.subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = lower("${local.prefix}-rds-subnet")
    }
  )
}

resource "aws_db_parameter_group" "postgres" {
  count  = length(local.db_name_list)
  name   = lower("${local.prefix}-rds-pg-${local.db_name_list[count.index]}")
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = lower("${local.prefix}-rds-pg-${local.db_name_list[count.index]}")
    }
  )
}

resource "aws_db_instance" "postgres" {
  count                           = length(local.db_name_list)
  identifier                      = lower("${local.prefix}-rds-${local.db_name_list[count.index]}")
  allocated_storage               = var.allocated_storage
  engine                          = "postgres"
  engine_version                  = var.engine_version
  instance_class                  = var.instance_class
  db_name                         = local.db_name_list[count.index]
  username = jsondecode(aws_secretsmanager_secret_version.rds_credentials_version.secret_string).username
  password = jsondecode(aws_secretsmanager_secret_version.rds_credentials_version.secret_string).password
  parameter_group_name            = aws_db_parameter_group.postgres[count.index].name
  publicly_accessible             = false
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = var.skip_final_snapshot ? null : local.final_snapshot_ids[count.index]
  vpc_security_group_ids          = [aws_security_group.rds_sg.id]
  db_subnet_group_name            = aws_db_subnet_group.rds_subnet.name
  multi_az                        = false
  storage_encrypted               = true
  storage_type         = "gp3"
  deletion_protection  = true
  apply_immediately = true
  kms_key_id                      = aws_kms_key.db_key.arn
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn
  enabled_cloudwatch_logs_exports = var.cloudwatch_log_types
  maintenance_window              = "sun:02:00-sun:02:30"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-rds-${local.db_name_list[count.index]}"
    }
  )
}

resource "aws_iam_role" "rds_monitoring" {
  name = "${local.prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
