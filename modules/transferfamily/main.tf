locals {
  environment = var.environment
  project     = "ihub"
  prefix      = "${local.environment}-${local.project}"

  common_tags = {
    Project     = local.project
    Owner       = "EvidenDevOpsTeam"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
  sftp_sg_name     = "sftp-sg-${local.environment}-${local.project}"
}

resource "aws_s3_bucket" "sftp_bucket" {
  bucket = var.sftp_bucket
  tags   = local.common_tags
}

resource "aws_cloudwatch_log_group" "transfer_logs" {
  name              = "/aws/transfer/sftp"
  retention_in_days = 30
  tags              = local.common_tags
}

resource "aws_iam_role" "transfer_logging_role" {
  name = "${local.prefix}-transfer-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "transfer.amazonaws.com"
        },
        Action   = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "transfer_logging_policy" {
  name = "${local.prefix}-transfer-logging-policy"
  role = aws_iam_role.transfer_logging_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ],
        Resource = "${aws_cloudwatch_log_group.transfer_logs.arn}:*"
      }
    ]
  })
}

resource "aws_iam_role" "transfer_user_role" {
  name = "${local.prefix}-transfer-user-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "transfer.amazonaws.com"
        },
        Action   = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "transfer_user_policy" {
  name = "${local.prefix}-transfer-user-policy"
  role = aws_iam_role.transfer_user_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:ListBucket"
        ],
        Resource = "arn:aws:s3:::${var.sftp_bucket}"
      },
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = "arn:aws:s3:::${var.sftp_bucket}/*"
      }
    ]
  })
}

resource "aws_security_group" "sftp_sg" {
  name        = local.sftp_sg_name
  description = "Security group for SFTP access"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.160.40.0/22", "10.160.48.0/22", "10.160.28.0/22","10.160.28.0/22"]
    description = "Allow SSH traffic from VPC"
  }

  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["10.160.28.0/22"]
    description = "Allow SFTP traffic from VPC"
  }

  ingress {
    from_port   = 22000
    to_port     = 22000
    protocol    = "tcp"
    cidr_blocks = ["10.160.28.0/22"]
    description = "Allow SFTP traffic from VPC"
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
      Name = local.sftp_sg_name
    },
    local.common_tags
  )
}

resource "aws_transfer_server" "sftp" {
  identity_provider_type = "SERVICE_MANAGED"
  endpoint_type          = "VPC"

  endpoint_details {
    vpc_id             = var.vpc_id
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.sftp_sg.id]
  }

  logging_role = aws_iam_role.transfer_logging_role.arn
  protocols    = ["SFTP"]
  domain       = "S3"

  pre_authentication_login_banner  = "Welcome to SFTP - Authorized access only."
  post_authentication_login_banner = "You have successfully logged in."

  tags = merge(
    {
      Name = "transfer-sftp-${local.project}-${local.environment}"
    },
    local.common_tags
  )
}
