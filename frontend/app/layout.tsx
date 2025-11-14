import './globals.css'
import React from 'react'
import Navbar from '../components/Navbar'


export const metadata = { title: 'DeFi Trading Bot MVP' }


export default function RootLayout({ children }: { children: React.ReactNode }) {
return (
<html lang="id">
<body>
<div className="max-w-6xl mx-auto px-6">
<Navbar />
<main className="mt-6">{children}</main>
</div>
</body>
</html>
)
}