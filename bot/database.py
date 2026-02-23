"""
Database Manager - Handles all database operations
"""

import psycopg2
from psycopg2.extras import RealDictCursor
import logging
import os
from typing import Dict, List, Any, Optional
from datetime import datetime

logger = logging.getLogger(__name__)


class DatabaseManager:
    """Manages PostgreSQL database connections and operations"""
    
    def __init__(self):
        """Initialize database manager"""
        self.conn = None
        self.cursor = None
        
        # Get database credentials from environment
        self.db_endpoint = os.getenv('DB_ENDPOINT', 'localhost')
        self.db_name = os.getenv('DB_NAME', 'trading_db')
        self.db_username = os.getenv('DB_USERNAME', 'trading_admin')
        self.db_password = os.getenv('DB_PASSWORD', '')
        
        # Parse endpoint to get host and port
        if ':' in self.db_endpoint:
            self.db_host, port_str = self.db_endpoint.split(':')
            self.db_port = int(port_str)
        else:
            self.db_host = self.db_endpoint
            self.db_port = 5432
    
    def connect(self) -> bool:
        """Connect to PostgreSQL database"""
        try:
            self.conn = psycopg2.connect(
                host=self.db_host,
                port=self.db_port,
                database=self.db_name,
                user=self.db_username,
                password=self.db_password
            )
            self.cursor = self.conn.cursor(cursor_factory=RealDictCursor)
            
            logger.info(f"Connected to database: {self.db_name}@{self.db_host}")
            
            # Create tables if they don't exist
            self._create_tables()
            
            return True
            
        except Exception as e:
            logger.error(f"Error connecting to database: {e}", exc_info=True)
            return False
    
    def disconnect(self):
        """Disconnect from database"""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        
        logger.info("Disconnected from database")
    
    def _create_tables(self):
        """Create necessary database tables"""
        try:
            # Trades table
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS trades (
                    id SERIAL PRIMARY KEY,
                    order_id BIGINT UNIQUE,
                    symbol VARCHAR(20),
                    order_type VARCHAR(10),
                    volume DECIMAL(10, 2),
                    open_price DECIMAL(10, 5),
                    close_price DECIMAL(10, 5),
                    stop_loss DECIMAL(10, 5),
                    take_profit DECIMAL(10, 5),
                    profit DECIMAL(10, 2),
                    open_time TIMESTAMP,
                    close_time TIMESTAMP,
                    status VARCHAR(20),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Account metrics table
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS account_metrics (
                    id SERIAL PRIMARY KEY,
                    balance DECIMAL(10, 2),
                    equity DECIMAL(10, 2),
                    profit DECIMAL(10, 2),
                    margin DECIMAL(10, 2),
                    margin_free DECIMAL(10, 2),
                    margin_level DECIMAL(10, 2),
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # ML training history table
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS training_history (
                    id SERIAL PRIMARY KEY,
                    model_version VARCHAR(50),
                    training_timesteps INTEGER,
                    final_reward DECIMAL(10, 4),
                    training_duration_seconds INTEGER,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Market data cache table
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS market_data_cache (
                    id SERIAL PRIMARY KEY,
                    symbol VARCHAR(20),
                    timeframe VARCHAR(10),
                    timestamp TIMESTAMP,
                    open DECIMAL(10, 5),
                    high DECIMAL(10, 5),
                    low DECIMAL(10, 5),
                    close DECIMAL(10, 5),
                    volume BIGINT,
                    UNIQUE(symbol, timeframe, timestamp)
                )
            """)
            
            # Create indexes
            self.cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_trades_symbol 
                ON trades(symbol)
            """)
            
            self.cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_trades_open_time 
                ON trades(open_time)
            """)
            
            self.cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_account_metrics_timestamp 
                ON account_metrics(timestamp)
            """)
            
            self.conn.commit()
            logger.info("Database tables created/verified successfully")
            
        except Exception as e:
            logger.error(f"Error creating tables: {e}", exc_info=True)
            self.conn.rollback()
    
    def log_trade(self, trade: Dict[str, Any]) -> bool:
        """Log a trade to the database"""
        try:
            self.cursor.execute("""
                INSERT INTO trades (
                    order_id, symbol, order_type, volume, open_price,
                    stop_loss, take_profit, open_time, status
                ) VALUES (
                    %(order_id)s, %(symbol)s, %(type)s, %(volume)s, %(price)s,
                    %(stop_loss)s, %(take_profit)s, %(timestamp)s, 'OPEN'
                )
                ON CONFLICT (order_id) DO NOTHING
            """, {
                'order_id': trade.get('order_id'),
                'symbol': trade.get('symbol'),
                'type': trade.get('type'),
                'volume': trade.get('volume'),
                'price': trade.get('price'),
                'stop_loss': trade.get('stop_loss'),
                'take_profit': trade.get('take_profit'),
                'timestamp': trade.get('timestamp', datetime.now())
            })
            
            self.conn.commit()
            logger.info(f"Trade logged: {trade.get('order_id')}")
            return True
            
        except Exception as e:
            logger.error(f"Error logging trade: {e}", exc_info=True)
            self.conn.rollback()
            return False
    
    def update_trade(self, order_id: int, close_price: float, profit: float, close_time: datetime) -> bool:
        """Update a trade with close information"""
        try:
            self.cursor.execute("""
                UPDATE trades
                SET close_price = %s, profit = %s, close_time = %s, status = 'CLOSED'
                WHERE order_id = %s
            """, (close_price, profit, close_time, order_id))
            
            self.conn.commit()
            logger.info(f"Trade updated: {order_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error updating trade: {e}", exc_info=True)
            self.conn.rollback()
            return False
    
    def log_account_metrics(self, metrics: Dict[str, Any]) -> bool:
        """Log account metrics"""
        try:
            self.cursor.execute("""
                INSERT INTO account_metrics (
                    balance, equity, profit, margin, margin_free, margin_level
                ) VALUES (
                    %(balance)s, %(equity)s, %(profit)s, 
                    %(margin)s, %(margin_free)s, %(margin_level)s
                )
            """, metrics)
            
            self.conn.commit()
            return True
            
        except Exception as e:
            logger.error(f"Error logging metrics: {e}", exc_info=True)
            self.conn.rollback()
            return False
    
    def get_trade_statistics(self, days: int = 30) -> Dict[str, Any]:
        """Get trading statistics for the specified period"""
        try:
            self.cursor.execute("""
                SELECT 
                    COUNT(*) as total_trades,
                    SUM(CASE WHEN profit > 0 THEN 1 ELSE 0 END) as winning_trades,
                    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) as losing_trades,
                    SUM(profit) as total_profit,
                    AVG(profit) as avg_profit,
                    MAX(profit) as max_profit,
                    MIN(profit) as min_profit
                FROM trades
                WHERE close_time >= NOW() - INTERVAL '%s days'
                AND status = 'CLOSED'
            """, (days,))
            
            result = self.cursor.fetchone()
            return dict(result) if result else {}
            
        except Exception as e:
            logger.error(f"Error getting statistics: {e}")
            return {}
    
    def get_recent_trades(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get recent trades"""
        try:
            self.cursor.execute("""
                SELECT * FROM trades
                ORDER BY open_time DESC
                LIMIT %s
            """, (limit,))
            
            return [dict(row) for row in self.cursor.fetchall()]
            
        except Exception as e:
            logger.error(f"Error getting recent trades: {e}")
            return []
    
    def cache_market_data(self, symbol: str, timeframe: str, data: List[Dict[str, Any]]) -> bool:
        """Cache market data to database"""
        try:
            for bar in data:
                self.cursor.execute("""
                    INSERT INTO market_data_cache (
                        symbol, timeframe, timestamp, open, high, low, close, volume
                    ) VALUES (
                        %s, %s, %s, %s, %s, %s, %s, %s
                    )
                    ON CONFLICT (symbol, timeframe, timestamp) DO UPDATE
                    SET open = EXCLUDED.open,
                        high = EXCLUDED.high,
                        low = EXCLUDED.low,
                        close = EXCLUDED.close,
                        volume = EXCLUDED.volume
                """, (
                    symbol, timeframe, bar['timestamp'],
                    bar['open'], bar['high'], bar['low'], bar['close'], bar['volume']
                ))
            
            self.conn.commit()
            return True
            
        except Exception as e:
            logger.error(f"Error caching market data: {e}")
            self.conn.rollback()
            return False
