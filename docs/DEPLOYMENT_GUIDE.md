# MT5 Trading Bot - Complete Deployment Guide

## 📋 Overview

This is a complete ML-powered trading bot for MetaTrader 5 that learns patterns and crafts its own strategy using reinforcement learning (PPO algorithm).

**Components:**
- ✅ AWS Infrastructure (Terraform)
- ✅ Python Trading Bot with ML
- ✅ CloudWatch Monitoring & Alerts
- ✅ PostgreSQL Database
- ✅ S3 Model Storage

---

## 🚀 Quick Start (30 Minutes to Deploy)

### Prerequisites

1. **AWS Account** with least-privilege permissions
   - Admin access is not required. Grant the account the specific permissions needed for this deployment: EC2, RDS, S3, IAM (limited), CloudWatch, SNS, and VPC. Prefer PowerUserAccess with targeted IAM permissions for credential management, or create a minimal IAM policy scoped to Terraform actions.
2. **MT5 Demo Account** from a broker (IC Markets, Pepperstone, etc.)
3. **Local Machine** with:
   - Terraform installed
   - AWS CLI configured
   - SSH key pair for EC2

---

## 📦 Step 1: Set Up Your Local Environment

```bash
# Clone or download the project
cd mt5-trading-bot

# Configure AWS CLI
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and region (us-east-1)

# Create SSH key pair (if you don't have one)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/mt5-trading-bot-key.pem
```

---

## 🏗️ Step 2: Configure Terraform

```bash
cd terraform

# Copy example tfvars file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your actual values
nano terraform.tfvars
```

**Required values to update:**

```hcl
# YOUR IP ADDRESS (for SSH access)
allowed_ssh_ips = ["YOUR_PUBLIC_IP/32"]  # Get from: curl ifconfig.me

# Database password (choose a strong one)
db_password = "YourSecurePassword123!"

# MT5 Demo Account Details
mt5_login    = "12345678"  # Your demo account number
mt5_password = "your_demo_password"
mt5_server   = "ICMarketsSC-Demo"  # Or your broker's demo server

# Your email for alerts
alert_email = "your-email@example.com"
```

---

## 🚢 Step 3: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy everything
terraform apply
# Type 'yes' when prompted
```

**This will create:**
- VPC with public/private subnets
- EC2 instance (Ubuntu 24.04)
- RDS PostgreSQL database
- S3 bucket for models
- Security groups
- IAM roles
- SNS topic for alerts
- CloudWatch monitoring

**Deployment takes ~10-15 minutes**

---

## 📧 Step 4: Confirm SNS Subscription

After deployment, check your email for an SNS subscription confirmation from AWS. **Click the confirmation link** to start receiving alerts.

---

## 💻 Step 5: Access and Configure EC2

```bash
# Get EC2 public IP from Terraform output
terraform output ec2_public_ip

# SSH into the instance
ssh -i ~/.ssh/mt5-trading-bot-key.pem ubuntu@<EC2_PUBLIC_IP>
```

Once connected:

```bash
# Check if user data script completed
sudo tail -f /var/log/cloud-init-output.log

# Switch to trader user
sudo su - trader

# Verify Python environment
source venv/bin/activate
python --version  # Should be 3.11+

# Clone bot code (if not already there)
cd /home/trader/mt5-bot
```

---

## 📝 Step 6: Deploy Bot Code

From your local machine, copy the bot code to EC2:

```bash
# From mt5-trading-bot directory
scp -i ~/.ssh/mt5-trading-bot-key.pem -r bot/* ubuntu@<EC2_IP>:/home/trader/mt5-bot/

# SSH back in and set permissions
ssh -i ~/.ssh/mt5-trading-bot-key.pem ubuntu@<EC2_IP>
sudo chown -R trader:trader /home/trader/mt5-bot
```

---

## 🤖 Step 7: Install MT5 Terminal

```bash
# As trader user
sudo su - trader
cd ~

# Install MT5 via Wine (already done in user_data, but verify)
# Run the installer
WINEPREFIX=~/.wine wine mt5setup.exe

# Follow the installation wizard
# When prompted, enter your demo account credentials
```

---

## ▶️ Step 8: Start the Trading Bot

```bash
# Start the bot service
sudo systemctl start trading-bot

# Check status
sudo systemctl status trading-bot

# View logs
tail -f /home/trader/mt5-bot/logs/trading_bot.log
```

**You should see:**
```
MT5 Trading Bot
Connected to MT5 account: 12345678
Account balance: 10000.00
Starting trading bot...
Trading bot started successfully!
```

---

## 📊 Step 9: Access Monitoring

### CloudWatch Dashboard

1. Go to AWS Console → CloudWatch → Dashboards
2. Create dashboard using: `monitoring/cloudwatch_dashboard.json`
3. You'll see:
   - Account balance/equity
   - Daily P&L
   - Trades executed
   - CPU usage
   - Error logs

### Health Check Script

```bash
# From your local machine
cd mt5-trading-bot/monitoring

# Recommended: retrieve DB credentials from a secrets store (AWS Secrets Manager)
# or use a local .env file with strict permissions (chmod 600 .env) loaded by your runtime.
# Minimal transient example using PGPASSWORD (avoids storing password in shell history when prefixed by a space):
#  PGPASSWORD=your-password python health_check.py

# Run health check (ensure credentials are provided securely to the script)
python health_check.py
```

---

## 🎯 What Happens Next?

### Phase 1: Learning (First 24-48 Hours)
- Bot connects to MT5 demo account
- Fetches historical market data (EURUSD)
- Trains ML model using PPO algorithm
- Observes patterns but makes minimal trades

### Phase 2: Active Trading (After Initial Training)
- Executes trades based on learned patterns
- Continues learning from results
- Adapts strategy to market conditions
- Sends alerts for:
  - Trades executed
  - High losses
  - Errors

### Phase 3: Optimization (Ongoing)
- Model improves over time
- Risk management enforced
- Performance tracked in database

---

## 🔍 Monitoring Your Bot

### Check Bot Status
```bash
ssh ubuntu@<EC2_IP>
sudo systemctl status trading-bot
```

### View Real-Time Logs
```bash
tail -f /home/trader/mt5-bot/logs/trading_bot.log
```

### Check Database
```bash
# Connect to RDS (recommended: use ~/.pgpass or Secrets Manager)
# Option A: Use ~/.pgpass (format: host:port:db:username:password) and set chmod 600 ~/.pgpass
#   psql -h <RDS_ENDPOINT> -U trading_admin -d trading_db
# Option B: Transient password (avoid storing in shell history):
#   PGPASSWORD=your_password psql -h <RDS_ENDPOINT> -U trading_admin -d trading_db

# View recent trades
SELECT * FROM trades ORDER BY open_time DESC LIMIT 10;

# View account metrics
SELECT * FROM account_metrics ORDER BY timestamp DESC LIMIT 10;
```

### CloudWatch Metrics
- Go to AWS Console → CloudWatch → Metrics → MT5TradingBot

---

## 🛑 How to Stop the Bot

```bash
# SSH into EC2
ssh -i ~/.ssh/mt5-trading-bot-key.pem ubuntu@<EC2_IP>

# Stop the service
sudo systemctl stop trading-bot

# The bot will:
# - Close all open positions
# - Save the ML model
# - Disconnect from MT5
# - Send shutdown notification
```

---

## 💰 Cost Estimate

**Monthly AWS Costs (Demo Phase):**
- EC2 t3.medium (24/7): ~$30
- RDS db.t3.micro: ~$15
- Data transfer/storage: ~$10
- **Total: ~$55/month**

**Cost Savings Tips:**
- Use t3.small instead of t3.medium: Save $15/mo
- Stop EC2 when market is closed (weekends): Save ~30%
- Use spot instances: Save up to 70%

---

## 🔧 Troubleshooting

### Bot Won't Start
```bash
# Check logs
sudo journalctl -u trading-bot -n 50

# Verify MT5 connection
cd /home/trader/mt5-bot
source /home/trader/venv/bin/activate
python -c "import MetaTrader5 as mt5; print(mt5.initialize())"
```

### No Trades Being Made
- Check if demo account is active
- Verify market is open (forex: Mon-Fri 24hrs)
- Review ML model training status
- Check risk limits aren't being hit

### Database Connection Issues
```bash
# Test database connection
psql -h <RDS_ENDPOINT> -U trading_admin -d trading_db -c "SELECT 1;"
```

### MT5 Connection Failed
- Verify demo account credentials in Secrets Manager
- Check broker server name is correct
- Ensure demo account hasn't expired

---

## 📈 Customization Options

### Adjust Risk Parameters
Edit `/home/trader/mt5-bot/bot/risk_manager.py`:
```python
max_risk_per_trade = 0.01  # 1% instead of 2%
max_daily_loss = 0.03      # 3% instead of 5%
```

### Change Trading Symbol
Edit `/home/trader/mt5-bot/bot/main.py`:
```python
# Change from EURUSD to GBPUSD
market_data = self.mt5.get_market_data(symbol="GBPUSD")
```

### Adjust ML Training
Edit `/home/trader/mt5-bot/bot/ml_agent.py`:
```python
# More training steps for better learning
self.train(market_data, timesteps=200000)  # Instead of 100000
```

---

## 🔐 Security Best Practices

1. **Restrict SSH Access**
   - Update `allowed_ssh_ips` to ONLY your IP
   
2. **Rotate Credentials**
   - Change database password monthly
   - Update in Secrets Manager

3. **Enable MFA**
   - Enable MFA on AWS root account
   
4. **Monitor Alerts**
   - Act on SNS alerts immediately
   - Review CloudWatch logs daily

5. **Backup Data**
   - Database backups run automatically (7-day retention)
   - Download important data periodically

## Infrastructure Security Notes

- **Secrets Manager for all credentials**: This deployment stores MT5 credentials and RDS master credentials in AWS Secrets Manager. Avoid committing secrets to `terraform.tfvars` or source control. Use Secrets Manager or environment-specific secret tooling.

- **DynamoDB state locking**: The Terraform S3 backend should be used together with a DynamoDB table for state locking to prevent concurrent state modifications. See `terraform.tfvars.example` and use `-backend-config` during `terraform init` to point to the DynamoDB table.

- **Managed RDS master password**: Terraform is configured to delegate master password handling so the password is not placed on the RDS resource. Rotate the secret in Secrets Manager and, if desired, enable automatic rotation with a Lambda function.

- **Provisioning hardening**: The EC2 user-data script runs non-interactively, builds native dependencies (e.g., TA-Lib C) before Python installs, and provides runtime environment variables to the service via a systemd `EnvironmentFile` (`/home/trader/trading-bot.env`). The `trader` user is not added to the global `sudo` group by default; create narrow `/etc/sudoers.d/` rules if needed.

---

## 🎓 Learning & Improvement

### Understanding the Bot's Decisions

Check the logs to see why trades are made:
```bash
grep "Trading signal" /home/trader/mt5-bot/logs/trading_bot.log
```

### Retrain the Model
```bash
cd /home/trader/mt5-bot
source /home/trader/venv/bin/activate

# Run training script (create this)
python scripts/retrain_model.py  # note: you may need to create or supply scripts/retrain_model.py
```

### Backtest Strategies
```bash
# Backtest on historical data before going live
python scripts/backtest.py --start-date 2024-01-01 --end-date 2024-12-31  # note: you may need to create or supply scripts/backtest.py
```

---

## 📞 Support & Next Steps

### When to Move to Live Trading
- ✅ Bot runs stable for 30+ days on demo
- ✅ Consistent profitable pattern observed
- ✅ Risk management working correctly
- ✅ You understand bot's behavior
- ⚠️ Start with SMALL live account ($500-1000)

### Scaling Up
- Increase EC2 instance size for more complex strategies
- Add multiple trading pairs
- Implement more sophisticated ML models
- Add sentiment analysis from news

---

## 🧹 Cleanup (If Needed)

To completely remove everything:

```bash
cd terraform
terraform destroy
# Type 'yes' to confirm

# This will delete ALL resources and data
```

---

## 📚 Additional Resources

- **MT5 Python Docs**: https://www.mql5.com/en/docs/python_metatrader5
- **Stable-Baselines3**: https://stable-baselines3.readthedocs.io/
- **AWS CloudWatch**: https://docs.aws.amazon.com/cloudwatch/
- **Terraform AWS**: https://registry.terraform.io/providers/hashicorp/aws/

---

**Remember:** This is a DEMO/LEARNING system. Never risk money you can't afford to lose. Always thoroughly test on demo accounts before considering live trading.

---

## ✅ Deployment Checklist

- [ ] AWS account configured
- [ ] MT5 demo account created
- [ ] Terraform tfvars updated
- [ ] Infrastructure deployed
- [ ] SNS email confirmed
- [ ] Bot code deployed to EC2
- [ ] MT5 terminal installed
- [ ] Trading bot service started
- [ ] CloudWatch dashboard created
- [ ] First successful trade logged
- [ ] Monitoring checks passing

**You're all set! Your ML trading bot is now running. 🎉**
