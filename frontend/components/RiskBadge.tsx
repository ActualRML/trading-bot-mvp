export default function RiskBadge({ risk }: { risk: string }) {
const map = {
low: 'bg-green-100 text-green-800',
medium: 'bg-amber-100 text-amber-800',
high: 'bg-red-100 text-red-800'
}
return <span className={`px-2 py-1 rounded-full text-sm ${map[risk as keyof typeof map] || 'bg-slate-100'}`}>{risk}</span>
}