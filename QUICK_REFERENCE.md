# 🚀 MT5 Trading Bot - Quick Reference

## 📋 Project Structure
```
mt5-trading-bot/
├── terraform/          # Infrastructure as Code
│   ├── main.tf        # Main AWS resources
│   ├── variables.tf   # Configuration variables
│   ├── outputs.tf     # Output values
│   └── user_data.sh   # EC2 initialization script
├── bot/               # Python trading bot
│   ├── main.py        # Main orchestrator
│   ├── mt5_connector.py    # MT5 API integration
│   ├── ml_agent.py         # ML/RL agent
│   ├── database.py         # PostgreSQL operations
│   ├── risk_manager.py     # Risk management
│   └── aws_integration.py  # AWS services
├── monitoring/        # Monitoring setup
│   ├── cloudwatch_dashboard.json
│   ├── alarms.tf
│   └── health_check.py
└── docs/             # Documentation
    ├── DEPLOYMENT_GUIDE.md
    └── architecture.mermaid
```

## ⚡ Quick Commands

### Deployment
```bash
cd terraform
terraform init
terraform apply
```

### SSH Access
```bash
ssh -i ~/.ssh/mt5-trading-bot-key.pem ubuntu@<EC2_IP>
```

### Bot Control
```bash
# Start
sudo systemctl start trading-bot

# Stop
sudo systemctl stop trading-bot

# Status
sudo systemctl status trading-bot

# Logs
tail -f /home/trader/mt5-bot/logs/trading_bot.log
```

### Database Access
```bash
psql -h <RDS_ENDPOINT> -U trading_admin -d trading_db
```

### Health Check
```bash
python monitoring/health_check.py
```

## 🎯 Key Files to Edit

### 1. Terraform Configuration
**File:** `terraform/terraform.tfvars`
```hcl
allowed_ssh_ips = ["YOUR_IP/32"]
db_password = "YourPassword"
mt5_login = "12345678"
mt5_password = "demo_password"
alert_email = "you@email.com"
```

### 2. Risk Parameters
**File:** `bot/risk_manager.py`
```python
max_risk_per_trade = 0.02  # 2%
max_daily_loss = 0.05      # 5%
max_positions = 3
```

### 3. Trading Symbol
**File:** `bot/main.py` (line ~120)
```python
market_data = self.mt5.get_market_data(symbol="EURUSD")
```

### 4. ML Training
**File:** `bot/ml_agent.py`
```python
timesteps = 100000  # Increase for more training
```

## 📊 Useful Database Queries

### Recent Trades
```sql
SELECT * FROM trades 
ORDER BY open_time DESC 
LIMIT 10;
```

### Trading Statistics
```sql
SELECT 
    COUNT(*) as total,
    SUM(CASE WHEN profit > 0 THEN 1 ELSE 0 END) as wins,
    SUM(profit) as total_profit
FROM trades 
WHERE close_time >= NOW() - INTERVAL '30 days';
```

### Account Performance
```sql
SELECT 
    date_trunc('day', timestamp) as day,
    AVG(balance) as avg_balance,
    MAX(equity) as max_equity
FROM account_metrics
GROUP BY day
ORDER BY day DESC
LIMIT 7;
```

## 🔍 Monitoring URLs

### AWS Console
- **EC2**: `https://console.aws.amazon.com/ec2`
- **RDS**: `https://console.aws.amazon.com/rds`
- **CloudWatch**: `https://console.aws.amazon.com/cloudwatch`
- **S3**: `https://console.aws.amazon.com/s3`
- **Secrets Manager**: `https://console.aws.amazon.com/secretsmanager`

### Key Metrics to Watch
- ✅ Account Balance (should be stable/growing)
- ✅ Daily P&L (should be positive most days)
- ✅ CPU Usage (should be <50%)
- ✅ Error Logs (should be minimal)
- ✅ Trade Frequency (5-15 trades/day typical)

## 🚨 Alert Thresholds

| Alert | Trigger | Action |
|-------|---------|--------|
| Low Balance | <$9,000 | Review strategy |
| High Daily Loss | <-$400 | Stop bot, investigate |
| No Metrics | 15 min gap | Check EC2 status |
| High CPU | >80% | Check for issues |
| RDS Storage | <2GB | Increase storage |

## 💰 Cost Summary

**Monthly AWS Costs:**
- EC2 t3.medium: $30
- RDS db.t3.micro: $15  
- S3/Data: $10
- **Total: ~$55/month**

**Savings:**
- t3.small instead: -$15/mo
- Weekend shutdown: -$15/mo
- Spot instance: -$20/mo

## 🔧 Common Issues & Fixes

### Bot Won't Start
```bash
# Check logs
sudo journalctl -u trading-bot -n 50

# Verify environment
sudo su - trader
source venv/bin/activate
python -c "import MetaTrader5; print('OK')"
```

### MT5 Connection Failed
```bash
# Check credentials
aws secretsmanager get-secret-value --secret-id <SECRET_ARN>

# Verify MT5 terminal
ps aux | grep mt5
```

### Database Connection Error
```bash
# Test connection
psql -h <RDS_ENDPOINT> -U trading_admin -d trading_db -c "SELECT 1;"

# Check security group
aws ec2 describe-security-groups --group-ids <SG_ID>
```

### No Trades
1. Verify market is open (Mon-Fri)
2. Check risk limits not exceeded
3. Confirm ML model loaded
4. Review logs for signals

## 📞 Emergency Actions

### Stop All Trading Immediately
```bash
ssh ubuntu@<EC2_IP>
sudo systemctl stop trading-bot
# Bot will close all positions and stop
```

### Force Close All Positions
```python
# In Python shell
from bot.mt5_connector import MT5Connector
mt5 = MT5Connector()
mt5.connect()
mt5.close_all_positions()
```

### Full Shutdown
```bash
# Stop bot
sudo systemctl stop trading-bot

# Stop EC2 (from local machine)
aws ec2 stop-instances --instance-ids <INSTANCE_ID>
```

## 📈 Performance Benchmarks

**Expected Demo Performance:**
- Win Rate: 55-65%
- Avg Trade Duration: 2-6 hours
- Avg Profit/Trade: $20-40
- Max Drawdown: 5-10%
- Monthly Return: 5-15%

*Actual results vary by market conditions*

## 🎓 Learning Resources

- **MT5 API**: https://www.mql5.com/en/docs/python_metatrader5
- **Stable-Baselines3**: https://stable-baselines3.readthedocs.io/
- **AWS CloudWatch**: https://docs.aws.amazon.com/cloudwatch/
- **PostgreSQL**: https://www.postgresql.org/docs/

## ✅ Pre-Flight Checklist

Before deploying:
- [ ] AWS account set up
- [ ] MT5 demo account created
- [ ] terraform.tfvars configured
- [ ] SSH key pair created
- [ ] Alert email ready
- [ ] Reviewed deployment guide
- [ ] Understand costs
- [ ] Backup plan ready

After deploying:
- [ ] SNS email confirmed
- [ ] Bot service running
- [ ] First trade logged
- [ ] CloudWatch dashboard created
- [ ] Monitoring script tested
- [ ] Can SSH to EC2
- [ ] Database accessible

## 🎯 Success Criteria

**Week 1:**
- ✅ Bot runs without crashes
- ✅ Makes 10+ demo trades
- ✅ Risk management working
- ✅ All alerts functioning

**Month 1:**
- ✅ Positive demo P&L
- ✅ Consistent strategy
- ✅ Win rate >50%
- ✅ Max drawdown <10%

**Before Live:**
- ✅ 30+ days demo success
- ✅ Understand all components
- ✅ Tested failure scenarios
- ✅ Ready to lose invested amount

---

**Need Help?** Review the full [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)

**Remember:** DEMO FIRST. Never risk real money until thoroughly tested!
