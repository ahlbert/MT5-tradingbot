output "ec2_public_ip" {
  description = "Public IP address of the trading bot EC2 instance"
  value       = aws_instance.trading_bot.public_ip
}

output "ec2_instance_id" {
  description = "Instance ID of the trading bot EC2"
  value       = aws_instance.trading_bot.id
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.trading_db.endpoint
  sensitive   = true
}

output "s3_bucket_name" {
  description = "S3 bucket name for model storage"
  value       = aws_s3_bucket.model_storage.id
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.trading_alerts.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.trading_bot_logs.name
}

output "ssh_command" {
  description = "SSH command to connect to the EC2 instance"
  sensitive   = true
  value       = "ssh -i ${coalesce(var.ssh_key_name, \"your-key.pem\")} ubuntu@${aws_instance.trading_bot.public_ip}"
}

output "secrets_manager_arn" {
  description = "Secrets Manager ARN for MT5 credentials"
  value       = aws_secretsmanager_secret.mt5_credentials.arn
  sensitive   = true
}

output "rds_secrets_manager_arn" {
  description = "Secrets Manager ARN for RDS master credentials"
  value       = aws_secretsmanager_secret.rds_master.arn
  sensitive   = true
}
