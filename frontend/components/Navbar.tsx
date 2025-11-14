'use client'
import Link from 'next/link'
import React from 'react'


export default function Navbar({ address = '0xABC...DEF' }: { address?: string }) {
return (
<nav className="w-full flex items-center justify-between py-4">
<Link href="/" className="text-xl font-semibold">DeFi Trading Bot</Link>
<div className="flex items-center gap-4">
<Link href="/dashboard" className="hidden sm:inline">Dashboard</Link>
<button className="px-4 py-2 bg-slate-100 rounded-lg">{address}</button>
</div>
</nav>
)
}