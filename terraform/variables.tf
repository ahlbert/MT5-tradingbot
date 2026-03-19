variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "oracle_vm_ip" {
  description = "oracle_cloud VM public IP address (for RDS access)"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
}

variable "db_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
 }

variable "dynamodb_table" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
}

variable "ssh_key_name" {
  description = "Optional SSH keypair name to attach to EC2 (leave null to skip)"
  type        = string
  default     = null
}

variable "mt5_login" {
  description = "MT5 account login number"
  type        = string
  sensitive   = true
}

variable "mt5_password" {
  description = "MT5 account password"
  type        = string
  sensitive   = true
}

variable "mt5_server" {
  description = "MT5 broker server address"
  type        = string
}

variable "alert_email" {
  description = "Email address for trading alerts"
  type        = string
 }