variable "vpc_id" {
  description = "VPC ID for the EC2"
  type        = string
}

variable "ec2_key_name" {
  description = "Key Pair of the EC2 Instance"
  type        = string
}

variable "prefix" {
  description = "Prefix for all the resources"
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

variable "kms_key_id" {
  type        = string
  description = "KMS key ID (not full ARN)"
}

variable "Account_ID" {
  type        = string
  description = "AWS Account ID for constructing ARNs"
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
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
