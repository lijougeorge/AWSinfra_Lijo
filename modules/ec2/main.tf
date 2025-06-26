locals {
  environment   = var.environment
  project       = "dali"
  os_type       = lower(var.os_type)

  common_tags = {
    Project     = local.project
    Owner       = "EvidenDevOpsTeam"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }

  ec2_name_prefix = "eu-${local.project}"
  ec2_sg_name     = "ec2-sg-${local.environment}-${local.project}"
  ebs_device_name = local.os_type == "windows" ? "xvdf" : "/dev/xvdf"
  user_data_file  = local.os_type == "windows" ? "${path.module}/user_script/windows_setup.ps1" : "${path.module}/user_script/user_script.sh"
  kms_key_arn     = "arn:aws:kms:${var.region}:${var.Account_ID}:key/${var.kms_key_id}"
}

data "aws_ami" "ec2_ami" {
  most_recent = true
  owners      = ["amazon"]

  dynamic "filter" {
    for_each = local.os_type == "windows" ? [1] : []
    content {
      name   = "name"
      values = ["Windows_Server-2022-English-Full-Base-*"]
    }
  }

  dynamic "filter" {
    for_each = local.os_type == "amz2" ? [1] : []
    content {
      name   = "name"
      values = ["amzn2-ami-hvm*"]
    }
  }

  dynamic "filter" {
    for_each = local.os_type == "al2023" ? [1] : []
    content {
      name   = "name"
      values = ["al2023-ami-2023.*-x86_64"]
    }
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_iam_instance_profile" "ssm_profile" {
  name = "mgmt-aws-iam-role-ssm-instance-profile"
}

resource "aws_security_group" "ec2_sg" {
  name        = local.ec2_sg_name
  description = "Security group for EC2 access"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.254.153.23/32", "10.254.153.28/32", "10.254.153.250/32", "10.254.153.248/32"]
    description = "Allow SSH traffic from VPC"
  }

  ingress {
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = ["10.160.56.0/22"]
    description = "Allow SMB traffic from VPC"
  }

  ingress {
    from_port   = 135
    to_port     = 135
    protocol    = "tcp"
    cidr_blocks = ["10.160.56.0/22"]
    description = "Allow SMB traffic from VPC"
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
      Name = local.ec2_sg_name
    },
    local.common_tags
  )
}

resource "aws_instance" "linux_server" {
  for_each = var.servers

  ami                    = data.aws_ami.ec2_ami.id
  instance_type          = each.value.instance_type
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = var.ec2_key_name
  iam_instance_profile   = data.aws_iam_instance_profile.ssm_profile.name
  ebs_optimized          = true

  root_block_device {
    volume_size           = each.value.root_block_device.volume_size
    volume_type           = each.value.root_block_device.volume_type
    throughput            = each.value.root_block_device.volume_type == "gp3" ? each.value.root_block_device.throughput : null
    encrypted             = true
    kms_key_id            = local.kms_key_arn
    delete_on_termination = lookup(each.value.root_block_device, "delete_on_termination", true)
  }

  dynamic "ebs_block_device" {
    for_each = each.value.additional_volumes
    content {
      device_name           = ebs_block_device.value.device_name
      volume_size           = ebs_block_device.value.volume_size
      volume_type           = ebs_block_device.value.volume_type
      throughput            = contains(["gp3"], ebs_block_device.value.volume_type) ? ebs_block_device.value.throughput : null
      encrypted             = true
      kms_key_id            = local.kms_key_arn
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", true)
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "dss-${local.ec2_name_prefix}-${each.key}"
    }
  )

  user_data = file(local.user_data_file)

  lifecycle {
    ignore_changes = [user_data]
  }
}
