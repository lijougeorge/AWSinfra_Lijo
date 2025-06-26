output "transfer_server_endpoint" {
  description = "The endpoint URL for the AWS Transfer Family SFTP server"
  value       = aws_transfer_server.sftp.endpoint
}

output "transfer_server_id" {
  description = "The ID of the AWS Transfer Family SFTP server"
  value       = aws_transfer_server.sftp.id
}
