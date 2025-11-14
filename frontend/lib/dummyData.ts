export const initialBots = [
{
id: '1',
name: 'High Risk ETH/USDC',
pair: 'ETH/USDC',
risk: 'high',
strategy: 'High Risk',
status: 'running',
pnl: 5.2,
entryPrice: 1800,
currentPrice: 1890,
params: { tp: 0.02, sl: 0.005, freq: '10m', size: 30 }
},
{
id: '2',
name: 'Medium BTC/USDT',
pair: 'BTC/USDT',
risk: 'medium',
strategy: 'Medium Risk',
status: 'running',
pnl: 1.8,
entryPrice: 42000,
currentPrice: 42600,
params: { tp: 0.01, sl: 0.01, freq: '30m', size: 15 }
},
{
id: '3',
name: 'Stopped ETH/USDC',
pair: 'ETH/USDC',
risk: 'low',
strategy: 'Low Risk',
status: 'stopped',
pnl: -0.5,
entryPrice: 1850,
currentPrice: 1820,
params: { tp: 0.005, sl: 0.002, freq: '1h', size: 5 }
}
]