'use client'
import React from 'react'


export default function StrategySlider({ value, onChange }: { value: number, onChange: (v: number) => void }) {
const color = value < 40 ? 'bg-green-500' : value < 70 ? 'bg-amber-500' : 'bg-red-500'


return (
<div>
<input
type="range"
min={0}
max={100}
value={value}
onChange={(e) => onChange(Number(e.target.value))}
className="w-full h-3 appearance-none rounded-full bg-slate-200"
style={{ accentColor: undefined }}
/>
<div className="mt-2 text-sm">Risk Level: <span className={`font-semibold`}>{value}</span></div>
<div className="w-full h-2 mt-2 rounded-full bg-slate-200">
<div className={`h-2 rounded-full ${color}`} style={{ width: `${value}%` }} />
</div>
</div>
)
}