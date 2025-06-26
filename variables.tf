variable "Account_ID" {
  description = "AWS Account ID"
  type        = string
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "prefix" {
  description = "Prefix for all the resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to create the resources"
  type        = string
}

variable "subnet_ids" {
  description = "List of Subnet IDs for creating the resources"
  type        = list(string)
}

variable "route_table_ids" {
  description = "List of Route Table IDs where the endpoints will be created"
  type        = list(string)
}

variable "private_ips" {
  description = "List of private IPs to assign to the EC2 instances"
  type        = list(string)
}

variable "internal" {
  description = "Boolean indicating whether the ALB is internal"
  type        = bool
}

variable "alb_subnets" {
  description = "List of Subnet IDs for the ALB"
  type        = list(string)
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
}

variable "access_logs_bucket" {
  description = "S3 bucket for ALB logging"
  type        = string
}

variable "access_logs_prefix" {
  description = "Prefix for the ALB logs"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "target_group_name" {
  description = "Name of the Target Group"
  type        = string
}

variable "target_group_port" {
  description = "Port for the Target Group"
  type        = number
}

variable "health_check_path" {
  description = "Health check path for the Target Group"
  type        = string
}

variable "desired_size" {
  description = "The desired number of nodes for the EKS node group"
  type        = number
}

variable "max_size" {
  description = "The maximum number of nodes for the EKS node group"
  type        = number
}

variable "min_size" {
  description = "The minimum number of nodes for the EKS node group"
  type        = number
}

variable "max_unavailable" {
  description = "The maximum number of nodes that can be unavailable during an update"
  type        = number
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  type        = string
}

variable "enable_cluster_log_types" {
  description = "Enable Cluster Logs"
  type        = list(string)
}

variable "efs_performance_mode" {
  description = "Performance mode of the EFS file system"
  type        = string
}

variable "efs_throughput_mode" {
  description = "Throughput mode of the EFS file system"
  type        = string
}

variable "iam_roles" {
  description = "List of IAM role ARNs to grant EKS access"
  type        = list(string)
}

variable "ec2_key_name" {
  description = "Key Pair of the EC2 Instance"
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g. dev, uat, prod)"
  type        = string
}

variable "os_type" {
  description = "Operating system type: windows, amz2, al2023"
  type        = string
  validation {
    condition     = contains(["windows", "amz2", "al2023"], lower(var.os_type))
    error_message = "Allowed values for os_type are 'windows', 'amz2', 'al2023'."
  }
}

variable "servers" {
  description = "Map of servers with configuration"
  type = map(object({
    instance_type = string
    subnet_id     = string
    root_block_device = object({
      volume_size           = number
      volume_type           = string
      throughput            = optional(number)
      delete_on_termination = optional(bool)
    })
    additional_volumes = list(object({
      device_name           = string
      volume_size           = number
      volume_type           = string
      throughput            = optional(number)
      delete_on_termination = optional(bool)
    }))
  }))
}

variable "db_name" {
  description = "Name of the database"
  type        = list(string)
}

variable "allocated_storage" {
  description = "The size of the database storage"
  type        = number
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
}

variable "instance_class" {
  description = "Instance type for the database"
  type        = string
}

variable "username" {
  description = "Database master username"
  type        = string
}

variable "parameter_group_family" {
  description = "DB parameter group family"
  type        = string
}

variable "skip_final_snapshot" {
  description = "Whether to skip final snapshot on deletion"
  type        = bool
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
}

variable "monitoring_interval" {
  description = "Monitoring interval for enhanced monitoring"
  type        = number
}

variable "cloudwatch_log_types" {
  description = "CloudWatch logs to export"
  type        = list(string)
}

variable "db_parameters" {
  type = list(object({
    name         = string
    value        = string
    apply_method = string
  }))
}

variable "kms_key_id" {
  type        = string
  description = "KMS key ID (not full ARN)"
}

variable "sftp_bucket" {
  description = "S3 bucket name for SFTP"
  type        = string
}
