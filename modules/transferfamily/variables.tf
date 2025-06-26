variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "sftp_bucket" {
  description = "S3 bucket name for SFTP"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for Transfer Server"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for Transfer Server"
  type        = list(string)
}

