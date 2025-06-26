variable "db_name" {
  description = "Name of the database"
  type        = list(string)
}

variable "prefix" {
  description = "Prefix for all the resouces"
  type        = string
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

variable "subnet_ids" {
  description = "Subnet ID for single-AZ deployment"
  type        = list(string)
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

variable "vpc_id" {
  description = "VPC ID for the EC2"
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g. dev, uat, prod)"
  type        = string
}
