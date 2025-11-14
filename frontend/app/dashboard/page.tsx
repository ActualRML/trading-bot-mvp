'use client'
import { useStore } from '../../lib/store'
import BotCard from '../../components/Botcard'
import Link from 'next/link'


export default function Dashboard() {
const bots = useStore(s => s.bots)


return (
<div className="space-y-6">
<header className="flex justify-between items-center">
<div>
<div className="text-sm">Wallet</div>
<div className="font-mono">0xABC...DEF</div>
</div>
<div className="flex gap-2">
<button className="px-4 py-2 bg-red-100 rounded">Disconnect</button>
</div>
</header>


<section>
<h2 className="text-xl font-semibold">My Active Bots</h2>
<div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
{bots.map(b => (
<BotCard key={b.id} bot={b} />
))}
</div>
</section>


<div className="mt-6">
<Link href="/create-bot" className="px-6 py-4 bg-slate-900 text-white rounded-2xl">+ Create New Bot</Link>
</div>
</div>
)
}