'use client'
import { useState } from 'react'
import StrategySlider from '../../components/StrategySlider'
import { useStore, State } from '../../lib/store'
import { useRouter } from 'next/navigation'

export default function CreateBot() {
  const addBot = useStore((s: State) => s.addBot)
  const router = useRouter()

  const [pair, setPair] = useState('ETH/USDC')
  const [strategy, setStrategy] = useState('Low Risk')
  const [customRisk, setCustomRisk] = useState(50)
  const [showAdvanced, setShowAdvanced] = useState(false)

  function startBot() {
    const id = Date.now().toString()
    const newBot = {
      id,
      name: `${strategy} ${pair}`,
      pair,
      risk: strategy.toLowerCase().includes('high')
        ? 'high'
        : strategy.toLowerCase().includes('medium')
        ? 'medium'
        : 'low',
      strategy,
      status: 'running',
      pnl: 0,
      entryPrice: 0,
      currentPrice: 0,
      params: { tp: 0.02, sl: 0.01, freq: '10m', size: 10 },
    }

    if (strategy === 'Custom') {
      newBot.params = {
        tp: +(customRisk / 100).toFixed(2),
        sl: +(customRisk / 100 / 4).toFixed(3),
        freq: '10m',
        size: Math.round(customRisk / 2),
      }
      newBot.risk =
        customRisk > 70 ? 'high' : customRisk > 40 ? 'medium' : 'low'
    }

    addBot(newBot)
    router.push('/dashboard')
  }

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-semibold">Create Bot</h2>

      <div className="card">
        <label className="block mb-2">Select Pair</label>
        <select
          value={pair}
          onChange={(e) => setPair(e.target.value)}
          className="w-full p-2 rounded"
        >
          <option>ETH/USDC</option>
          <option>BTC/USDT</option>
          <option>SOL/USDC</option>
        </select>

        <div className="mt-4">
          <label className="block mb-2">Choose Strategy</label>
          <div className="grid grid-cols-2 gap-3">
            {['Low Risk', 'Medium Risk', 'High Risk', 'Custom'].map((s) => (
              <button
                key={s}
                onClick={() => setStrategy(s)}
                className={`p-4 rounded-lg text-left ${
                  strategy === s ? 'ring-2 ring-slate-300' : 'bg-slate-50'
                }`}
              >
                <div className="font-semibold">{s}</div>
              </button>
            ))}
          </div>
        </div>

        {strategy === 'Custom' && (
          <div className="mt-4">
            <StrategySlider value={customRisk} onChange={setCustomRisk} />
            <div className="mt-3">
              <div className="font-mono">
                Risk Level: {customRisk} (Aggressive)
              </div>
              <div>Take Profit: 2%</div>
              <div>Stop Loss: 0.5%</div>
              <div>Trade Frequency: 10m</div>
              <div>Position Size: {Math.round(customRisk / 2)}%</div>
            </div>

            <div className="mt-3">
              <label className="inline-flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={showAdvanced}
                  onChange={() => setShowAdvanced((s) => !s)}
                />
                <span>Show Advanced Settings</span>
              </label>

              {showAdvanced && (
                <div className="mt-3 space-y-2">
                  <input
                    placeholder="Take Profit %"
                    className="w-full p-2 rounded"
                  />
                  <input
                    placeholder="Stop Loss %"
                    className="w-full p-2 rounded"
                  />
                </div>
              )}
            </div>
          </div>
        )}

        <div className="mt-6 flex justify-end">
          <button
            onClick={startBot}
            className="px-6 py-3 bg-slate-900 text-white rounded-2xl"
          >
            Start Bot
          </button>
        </div>
      </div>
    </div>
  )
}
