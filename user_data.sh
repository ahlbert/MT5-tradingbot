#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install dependencies
apt-get install -y \
    python3.11 \
    python3.11-venv \
    python3-pip \
    postgresql-client \
    wine64 \
    wget \
    curl \
    git \
    awscli \
    jq

# Create trading bot user
useradd -m -s /bin/bash trader
usermod -aG sudo trader

# Set up Python environment
su - trader -c "python3.11 -m venv /home/trader/venv"
su - trader -c "/home/trader/venv/bin/pip install --upgrade pip"

# Install Python packages
su - trader -c "/home/trader/venv/bin/pip install \
    MetaTrader5 \
    pandas \
    numpy \
    psycopg2-binary \
    boto3 \
    stable-baselines3 \
    torch \
    gymnasium \
    finrl \
    ta-lib \
    scikit-learn \
    matplotlib \
    seaborn"

# Create directories
mkdir -p /home/trader/mt5-bot/{logs,models,data}
chown -R trader:trader /home/trader/mt5-bot

# Download MT5 Terminal (Demo)
# Note: MT5 on Linux requires Wine
cd /home/trader
su - trader -c "wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe -O /home/trader/mt5setup.exe"

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/home/trader/mt5-bot/logs/trading_bot.log",
            "log_group_name": "/aws/ec2/mt5-trading-bot",
            "log_stream_name": "{instance_id}/trading_bot",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "MT5TradingBot",
    "metrics_collected": {
      "cpu": {
        "measurement": [{"name": "cpu_usage_idle", "rename": "CPU_IDLE", "unit": "Percent"}],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": [{"name": "mem_used_percent", "rename": "MEM_USED", "unit": "Percent"}],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

# Set environment variables
cat >> /home/trader/.bashrc <<EOF

# Trading Bot Environment
export DB_ENDPOINT="${db_endpoint}"
export DB_NAME="${db_name}"
export DB_USERNAME="${db_username}"
export SECRET_ARN="${secret_arn}"
export S3_BUCKET="${s3_bucket}"
export AWS_REGION="${region}"
export PYTHONPATH="/home/trader/mt5-bot:\$PYTHONPATH"
export PATH="/home/trader/venv/bin:\$PATH"
EOF

# Create systemd service for trading bot
cat > /etc/systemd/system/trading-bot.service <<EOF
[Unit]
Description=MT5 Trading Bot
After=network.target

[Service]
Type=simple
User=trader
WorkingDirectory=/home/trader/mt5-bot
Environment="PATH=/home/trader/venv/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=/home/trader/venv/bin/python /home/trader/mt5-bot/main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable but don't start yet (bot code needs to be deployed first)
systemctl daemon-reload
systemctl enable trading-bot.service

echo "EC2 initialization complete. Trading bot user data script finished."
