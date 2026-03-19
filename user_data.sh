#!/bin/bash
set -e

# Update system non-interactively
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# Install dependencies (include build tools for compiling native libs)
apt-get install -y \
  build-essential \
  automake \
  autoconf \
  libtool \
  python3.11 \
  python3.11-venv \
  python3.11-dev \
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
# Do not add trader to full sudo group by default. If limited elevated
# permissions are necessary, provision a specific sudoers.d file with
# least-privilege rules instead of granting blanket sudo access.

# Set up Python environment
su - trader -c "python3.11 -m venv /home/trader/venv"
su - trader -c "/home/trader/venv/bin/pip install --upgrade pip"

# Build and install TA-Lib C library prerequisites before installing the
# Python wrapper so the pip install can link against the system library.
cd /tmp
wget https://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz -O ta-lib-0.4.0-src.tar.gz
tar -xzf ta-lib-0.4.0-src.tar.gz
cd ta-lib-0.4.0-src
./configure --prefix=/usr
make
make install

# Install Python packages (ta-lib will now build against the system library)
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

# Create a simple key=value environment file for systemd (no 'export')
cat > /home/trader/trading-bot.env <<EOF
DB_ENDPOINT=${db_endpoint}
DB_NAME=${db_name}
DB_USERNAME=${db_username}
SECRET_ARN=${secret_arn}
S3_BUCKET=${s3_bucket}
AWS_REGION=${region}
PYTHONPATH=/home/trader/mt5-bot:
PATH=/home/trader/venv/bin:/usr/local/bin:/usr/bin:/bin
EOF
chown trader:trader /home/trader/trading-bot.env
chmod 600 /home/trader/trading-bot.env

# Create systemd service for trading bot
cat > /etc/systemd/system/trading-bot.service <<EOF
[Unit]
Description=MT5 Trading Bot
After=network.target

[Service]
Type=simple
User=trader
WorkingDirectory=/home/trader/mt5-bot
EnvironmentFile=/home/trader/trading-bot.env
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
