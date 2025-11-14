import Link from 'next/link'


export default function Landing() {
return (
<section className="min-h-[60vh] flex flex-col items-center justify-center text-center gap-8">
<h1 className="text-4xl font-bold">Non-custodial DeFi Trading Bot</h1>
<p className="max-w-xl">Pilih strategi kamu, biarkan bot bekerja.</p>
<div className="flex gap-4">
<button className="px-6 py-3 bg-slate-900 text-white rounded-2xl">Connect Wallet</button>
<Link href="/dashboard" className="px-6 py-3 bg-slate-200 rounded-2xl">Launch App</Link>
</div>
</section>
)
}