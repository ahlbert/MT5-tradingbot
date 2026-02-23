variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type for trading bot"
  type        = string
  default     = "t3.medium"
}

variable "ubuntu_ami" {
  description = "Ubuntu 24.04 LTS AMI ID for the region"
  type        = string
  # Update this with the latest Ubuntu 24.04 AMI for your region
  # Find at: https://cloud-images.ubuntu.com/locator/ec2/
  default = "ami-0c7217cdde317cfec" # us-east-1 Ubuntu 24.04 LTS
}

variable "allowed_ssh_ips" {
  description = "List of IP addresses allowed to SSH into the EC2 instance"
  type        = list(string)
  default     = ["0.0.0.0/0"] # CHANGE THIS to your IP for security!
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "trading_db"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "trading_admin"
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
  # Set this via terraform.tfvars or environment variable
}

variable "mt5_login" {
  description = "MT5 account login number"
  type        = string
  sensitive   = true
  # Set this via terraform.tfvars or environment variable
}

variable "mt5_password" {
  description = "MT5 account password"
  type        = string
  sensitive   = true
  # Set this via terraform.tfvars or environment variable
}

variable "mt5_server" {
  description = "MT5 broker server address"
  type        = string
  default     = "ICMarketsSC-Demo" # Example for IC Markets demo
}

variable "alert_email" {
  description = "Email address for trading alerts"
  type        = string
  # Set this via terraform.tfvars or environment variable
}
