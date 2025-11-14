'use client'
import Link from 'next/link'
import RiskBadge from './RiskBadge'

type Bot = {
  id: string
  name: string
  pair?: string
  strategy?: string
  risk?: number | string
  status?: string
  pnl?: number | string
}

type BotCardProps = {
  bot: Bot | null | undefined
}

export default function BotCard({ bot }: BotCardProps) {
  if (!bot) return null

  return (
    <div className="card">
      <div className="flex justify-between items-start">
        <div>
          <h3 className="text-lg font-semibold">{bot.name}</h3>
          <p className="text-sm text-slate-500">
            {bot.pair ?? '—'} • {bot.strategy ?? '—'}
          </p>
        </div>
        <div className="flex flex-col items-end gap-2">
          <RiskBadge risk={bot.risk == null ? '—' : String(bot.risk)} />
          <span className="text-sm">{bot.status ?? '—'}</span>
        </div>
      </div>

      <div className="mt-4 flex items-center justify-between">
        <div>
          <div className="text-sm text-slate-500">PnL</div>
          <div className="text-lg font-medium">{bot.pnl ?? '—'}%</div>
        </div>
        <Link href={`/bot/${bot.id}`} className="px-4 py-2 bg-slate-100 rounded-lg">
          Open
        </Link>
      </div>
    </div>
  )
}
