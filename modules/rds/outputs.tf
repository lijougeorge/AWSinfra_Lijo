output "rds_instance_endpoints" {
  description = "RDS instance endpoints"
  value       = aws_db_instance.postgres[*].endpoint
}

output "rds_subnet_groups" {
  description = "RDS Subnet Groups"
  value       = aws_db_subnet_group.rds_subnet[*].name
}