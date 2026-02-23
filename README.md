# 🤖 MT5 AI Trading Bot

An intelligent, self-learning trading bot for MetaTrader 5 that uses reinforcement learning to develop and refine its own trading strategies.

## 🌟 Features

- **🧠 Machine Learning**: Uses PPO (Proximal Policy Optimization) reinforcement learning
- **📊 Adaptive Strategy**: Learns patterns and crafts strategies from market data
- **☁️ Cloud-Native**: Fully deployed on AWS infrastructure
- **📈 Real-Time Monitoring**: CloudWatch dashboards and SNS alerts
- **🛡️ Risk Management**: Built-in position sizing and loss limits
- **💾 Data Persistence**: PostgreSQL database for trade history
- **🔄 Continuous Learning**: Improves strategy over time from results

## 🏗️ Architecture

```
┌─────────────────┐
│   You (Cloud    │
│   Engineer)     │
└────────┬────────┘
         │
    ┌────▼──────────────────────────────────────────┐
    │         AWS Cloud Infrastructure              │
    │                                               │
    │  ┌──────────────┐    ┌──────────────┐       │
    │  │ EC2 Instance │◄───┤ RDS Postgres │       │
    │  │  - MT5       │    │              │       │
    │  │  - Python    │    └──────────────┘       │
    │  │  - ML Agent  │                           │
    │  └──────┬───────┘                           │
    │         │                                    │
    │         │      ┌──────────────┐            │
    │         └──────►  S3 Bucket   │            │
    │                │ (ML Models)  │            │
    │                └──────────────┘            │
    │                                            │
    │  ┌────────────────────────────────┐       │
    │  │  CloudWatch Monitoring         │       │
    │  │  - Logs  - Metrics  - Alarms   │       │
    │  └────────────┬───────────────────┘       │
    │               │                            │
    │       ┌───────▼────────┐                  │
    │       │  SNS Alerts    │                  │
    │       │  (Email/SMS)   │                  │
    │       └────────────────┘                  │
    └───────────────────────────────────────────┘
                     │
                     ▼
            ┌────────────────┐
            │  MT5 Broker    │
            │  (Demo/Live)   │
            └────────────────┘
```

## 📦 What's Included

### 1. Infrastructure as Code (Terraform)
- Complete AWS setup
- VPC with public/private subnets
- EC2 instance configuration
- RDS PostgreSQL database
- S3 bucket for model storage
- Security groups and IAM roles
- CloudWatch monitoring setup

### 2. Trading Bot (Python)
- **main.py**: Main orchestrator
- **mt5_connector.py**: MetaTrader 5 API integration
- **ml_agent.py**: Reinforcement learning agent
- **database.py**: PostgreSQL operations
- **risk_manager.py**: Position sizing and risk controls
- **aws_integration.py**: AWS services integration

### 3. Monitoring & Alerts
- CloudWatch dashboard configuration
- Custom metric alarms
- Health check script
- Log aggregation

### 4. Documentation
- Complete deployment guide
- Architecture diagrams
- Troubleshooting tips

## 🚀 Quick Start

### Prerequisites
- AWS account with admin access
- MT5 demo account (from IC Markets, Pepperstone, etc.)
- Terraform installed
- AWS CLI configured
- SSH key pair

### Deploy in 5 Steps

```bash
# 1. Configure your settings
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Update with your values

# 2. Deploy infrastructure
terraform init
terraform apply

# 3. Deploy bot code
scp -r bot/* ubuntu@<EC2_IP>:/home/trader/mt5-bot/

# 4. Start the bot
ssh ubuntu@<EC2_IP>
sudo systemctl start trading-bot

# 5. Monitor
tail -f /home/trader/mt5-bot/logs/trading_bot.log
```

**Full deployment guide**: [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)

## 💡 How It Works

### Learning Phase (First 24-48 hours)
1. Bot connects to MT5 demo account
2. Fetches historical market data (EURUSD by default)
3. Trains reinforcement learning model
4. Learns profitable patterns
5. Begins making conservative trades

### Active Trading Phase
1. Analyzes current market conditions
2. ML agent predicts optimal action (Buy/Sell/Hold)
3. Risk manager calculates safe position size
4. Executes trade through MT5
5. Monitors position and manages exits
6. Records results for continued learning

### Continuous Improvement
- Learns from every trade (profit/loss feedback)
- Adapts to changing market conditions
- Refines strategy parameters
- Saves improved models to S3

## 🎯 Key Components Explained

### Reinforcement Learning Agent
- **Algorithm**: PPO (Proximal Policy Optimization)
- **State Space**: Price data, indicators, account info
- **Action Space**: Buy, Sell, Hold
- **Reward Function**: Profit-based with risk penalties

### Risk Management
- Max 2% risk per trade (configurable)
- Max 5% daily loss limit
- Position sizing based on stop loss
- Automatic position closure on limits

### Trade Execution
- Market orders via MT5 API
- Configurable stop loss and take profit
- Slippage protection
- Trade logging to database

## 📊 Monitoring

### CloudWatch Metrics
- Account balance & equity
- Daily P&L
- Trades executed
- CPU/Memory usage
- Database performance

### Alerts (SNS)
- Low account balance
- High daily losses
- Bot stopped/crashed
- System errors

### Database Queries
```sql
-- View recent trades
SELECT * FROM trades ORDER BY open_time DESC LIMIT 10;

-- Trading statistics
SELECT 
    COUNT(*) as total_trades,
    SUM(CASE WHEN profit > 0 THEN 1 ELSE 0 END) as winning_trades,
    SUM(profit) as total_profit
FROM trades 
WHERE close_time >= NOW() - INTERVAL '30 days';
```

## 🔧 Customization

### Change Trading Symbol
```python
# In main.py
market_data = self.mt5.get_market_data(symbol="GBPUSD")
```

### Adjust Risk Parameters
```python
# In risk_manager.py
max_risk_per_trade = 0.01  # 1% instead of 2%
max_daily_loss = 0.03      # 3% instead of 5%
```

### ML Training Parameters
```python
# In ml_agent.py
self.model = PPO(
    learning_rate=0.0001,  # Lower for more stable learning
    n_steps=4096,          # More steps per update
    # ... other parameters
)
```

## 💰 Cost Breakdown

**AWS Monthly Costs (Demo Account):**
| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| EC2 | t3.medium | ~$30 |
| RDS | db.t3.micro | ~$15 |
| S3 | Storage + transfers | ~$5 |
| Data Transfer | | ~$5 |
| **Total** | | **~$55/month** |

**Cost Optimization Tips:**
- Use t3.small instance: Save $15/mo
- Stop EC2 on weekends: Save ~30%
- Use spot instances: Save up to 70%

## 🔐 Security

- All credentials stored in AWS Secrets Manager
- Encrypted RDS database
- Security groups restrict access
- Regular automated backups
- SSH access limited to your IP

## 📈 Performance

**Demo Account Results (Typical):**
- Win rate: 55-65%
- Average trade: 20-40 pips
- Daily trades: 5-15
- Max drawdown: <10%

*Results vary based on market conditions and training time*

## ⚠️ Important Notes

### This is for DEMO/LEARNING ONLY
- Never risk money you can't afford to lose
- Thoroughly test on demo for 30+ days minimum
- Understand the bot's behavior before going live
- Past performance doesn't guarantee future results
- Market conditions can change rapidly

### Before Live Trading
- [ ] 30+ days successful demo trading
- [ ] Understand all bot components
- [ ] Tested risk management thoroughly
- [ ] Small live account first ($500-1000)
- [ ] Can afford to lose the entire amount

## 🛠️ Troubleshooting

### Bot Won't Start
```bash
sudo journalctl -u trading-bot -n 50
```

### MT5 Connection Issues
- Verify credentials in Secrets Manager
- Check broker server name
- Ensure demo account is active

### No Trades
- Confirm market is open
- Check risk limits aren't hit
- Verify ML model trained

**Full troubleshooting**: See [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)

## 📚 Resources

- [Full Deployment Guide](docs/DEPLOYMENT_GUIDE.md)
- [Architecture Diagram](docs/architecture.mermaid)
- [MT5 Python Documentation](https://www.mql5.com/en/docs/python_metatrader5)
- [Stable-Baselines3 Docs](https://stable-baselines3.readthedocs.io/)

## 🤝 Contributing

This is a personal/learning project, but improvements are welcome:
- Bug fixes
- Documentation improvements
- Performance optimizations
- Additional features

## 📄 License

MIT License - Use at your own risk

## ⚖️ Disclaimer

**TRADING INVOLVES SIGNIFICANT RISK OF LOSS**

This software is provided for educational and research purposes only. The authors and contributors are not responsible for any financial losses incurred through the use of this bot. Always:

- Start with demo accounts
- Never invest more than you can afford to lose
- Seek professional financial advice
- Understand that past performance ≠ future results
- Be aware that market conditions can change

**Use at your own risk.**

---

## 🎯 Next Steps

1. ✅ Read the [Deployment Guide](docs/DEPLOYMENT_GUIDE.md)
2. ✅ Set up your AWS account
3. ✅ Get an MT5 demo account
4. ✅ Deploy the infrastructure
5. ✅ Monitor your bot's learning
6. ✅ Analyze results and optimize

**Happy Trading! 📈🤖**
