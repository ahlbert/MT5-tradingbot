terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    # Update these values with your own
    bucket = "your-terraform-state-bucket"
    key    = "mt5-trading-bot/terraform.tfstate"
    region = "us-east-1"
    # For state locking, set your DynamoDB table here (recommended)
    dynamodb_table = var.dynamodb_table
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "MT5-Trading-Bot"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# VPC Configuration
resource "aws_vpc" "trading_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "mt5-trading-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.trading_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "mt5-trading-public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.trading_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "mt5-trading-private-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.trading_vpc.id

  tags = {
    Name = "mt5-trading-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.trading_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "mt5-trading-public-rt"
  }
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group for EC2
resource "aws_security_group" "trading_bot_sg" {
  name        = "mt5-trading-bot-sg"
  description = "Security group for MT5 trading bot EC2 instance"
  vpc_id      = aws_vpc.trading_vpc.id

  # SSH access (restrict to your IP in production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips
    description = "SSH access"
  }

  # HTTPS outbound for MT5 broker connections
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS to MT5 brokers"
  }

  # HTTP outbound for updates
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for updates"
  }

  # PostgreSQL to RDS
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "PostgreSQL to RDS"
  }

  # DNS
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS"
  }

  tags = {
    Name = "mt5-trading-bot-sg"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "mt5-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.trading_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.trading_bot_sg.id]
    description     = "PostgreSQL from EC2"
  }

  tags = {
    Name = "mt5-rds-sg"
  }
}

# IAM Role for EC2
resource "aws_iam_role" "trading_bot_role" {
  name = "mt5-trading-bot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "trading_bot_policy" {
  name = "mt5-trading-bot-policy"
  role = aws_iam_role.trading_bot_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.model_storage.arn,
          "${aws_s3_bucket.model_storage.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.mt5_credentials.arn,
          aws_secretsmanager_secret.rds_master.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.trading_alerts.arn
      }
    ]
  })
}

# DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "terraform-locks-${var.environment}"
  }
}

# Secrets Manager secret for RDS master credentials
resource "aws_secretsmanager_secret" "rds_master" {
  name        = "mt5-rds-master-${var.environment}"
  description = "RDS master credentials for mt5-trading-db"

  tags = {
    Name = "mt5-rds-master"
  }
}

resource "aws_secretsmanager_secret_version" "rds_master_version" {
  secret_id     = aws_secretsmanager_secret.rds_master.id
  secret_string = jsonencode({
    username = var.db_username,
    password = var.db_password
  })
}

resource "aws_iam_instance_profile" "trading_bot_profile" {
  name = "mt5-trading-bot-profile"
  role = aws_iam_role.trading_bot_role.name
}

# EC2 Instance
resource "aws_instance" "trading_bot" {
  ami           = var.ubuntu_ami # Ubuntu 24.04 LTS
  instance_type = var.instance_type
  # Optional SSH key name (null if not provided)
  key_name      = var.ssh_key_name

  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.trading_bot_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.trading_bot_profile.name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    db_endpoint = aws_db_instance.trading_db.endpoint
    db_name     = var.db_name
    db_username = var.db_username
    secret_arn  = aws_secretsmanager_secret.mt5_credentials.arn
    s3_bucket   = aws_s3_bucket.model_storage.id
    region      = var.aws_region
  })

  tags = {
    Name = "mt5-trading-bot"
  }

  depends_on = [aws_db_instance.trading_db]
}

# RDS PostgreSQL
resource "aws_db_subnet_group" "trading_db_subnet" {
  name       = "mt5-trading-db-subnet"
  subnet_ids = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]

  tags = {
    Name = "mt5-trading-db-subnet"
  }
}

resource "aws_db_instance" "trading_db" {
  identifier     = "mt5-trading-db"
  engine         = "postgres"
  engine_version = "16.1"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  # Password is managed via Secrets Manager. Enable RDS to manage the master
  # user password lifecycle. Terraform will not store the plaintext password
  # on the DB resource when this is enabled.
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.trading_db_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  skip_final_snapshot = var.environment == "dev" ? true : false
  final_snapshot_identifier = var.environment == "dev" ? null : "mt5-trading-db-final-snapshot"

  tags = {
    Name = "mt5-trading-db"
  }
}

# S3 Bucket for Model Storage
resource "aws_s3_bucket" "model_storage" {
  bucket = "mt5-trading-models-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "mt5-model-storage"
  }
}

# Explicitly block public access to the model storage bucket
resource "aws_s3_bucket_public_access_block" "model_storage_block" {
  bucket = aws_s3_bucket.model_storage.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "model_storage_versioning" {
  bucket = aws_s3_bucket.model_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "model_storage_encryption" {
  bucket = aws_s3_bucket.model_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Secrets Manager for MT5 Credentials
resource "aws_secretsmanager_secret" "mt5_credentials" {
  name        = "mt5-trading-credentials-${var.environment}"
  description = "MT5 trading account credentials"

  tags = {
    Name = "mt5-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "mt5_credentials_version" {
  secret_id = aws_secretsmanager_secret.mt5_credentials.id
  secret_string = jsonencode({
    mt5_login    = var.mt5_login
    mt5_password = var.mt5_password
    mt5_server   = var.mt5_server
  })
}

# SNS Topic for Alerts
resource "aws_sns_topic" "trading_alerts" {
  name = "mt5-trading-alerts-${var.environment}"

  tags = {
    Name = "mt5-trading-alerts"
  }
}

resource "aws_sns_topic_subscription" "trading_alerts_email" {
  topic_arn = aws_sns_topic.trading_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "trading_bot_logs" {
  name              = "/aws/ec2/mt5-trading-bot"
  retention_in_days = 30

  tags = {
    Name = "mt5-trading-bot-logs"
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
