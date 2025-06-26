output "instance_ids" {
  description = "EC2 Instance IDs"
  value       = [for instance in aws_instance.linux_server : instance.id]
}

output "instance_private_ips" {
  description = "Private IPs of EC2 Instances"
  value       = [for instance in aws_instance.linux_server : instance.private_ip]
}

output "instance_ids_map" {
  description = "EC2 Instance IDs by server name"
  value       = { for k, v in aws_instance.linux_server : k => v.id }
}

output "private_ips_map" {
  description = "Private IPs by server name"
  value       = { for k, v in aws_instance.linux_server : k => v.private_ip }
}
