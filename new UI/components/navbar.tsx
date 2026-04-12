import Link from 'next/link';

export function NavBar() {
    return (
        <header className="sticky top-0 z-50 backdrop-blur-xl bg-white/70 dark:bg-[#0f172a]/80 border-b border-slate-200/50 dark:border-slate-800/50 shadow-sm transition-all duration-300">
            <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
                <Link href="/" className="flex items-center gap-3 group">
                    <div className="h-10 w-10 bg-gradient-to-tr from-slate-900 to-slate-700 dark:from-white dark:to-slate-300 rounded-xl flex items-center justify-center shadow-lg group-hover:scale-105 group-hover:rotate-3 transition-transform duration-300">
                        <span className="text-white dark:text-slate-900 font-bold text-xl drop-shadow-md">L</span>
                    </div>
                    <h1 className="text-2xl font-black tracking-tighter bg-clip-text text-transparent bg-gradient-to-r from-slate-900 to-slate-600 dark:from-white dark:to-slate-400">Wordsmith</h1>
                </Link>
                <nav className="hidden md:flex items-center gap-8">
                    {['Overview', 'Books', 'Authors', 'Community'].map((item) => (
                        <Link
                            key={item}
                            href={item === 'Books' ? '/books' : '#'}
                            className={`text-sm font-semibold transition-all duration-300 relative after:content-[''] after:absolute after:-bottom-1.5 after:left-0 after:w-0 after:h-0.5 after:bg-slate-900 dark:after:bg-white hover:after:w-full after:transition-all after:duration-300 ${item === 'Books'
                                ? 'text-slate-900 dark:text-white after:w-full'
                                : 'text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white'
                                }`}
                        >
                            {item}
                        </Link>
                    ))}
                </nav>
                <div className="flex items-center gap-5">
                    <button className="text-sm font-semibold text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white transition-colors">
                        Log in
                    </button>
                    <button className="bg-slate-900 hover:bg-slate-800 dark:bg-white dark:hover:bg-slate-100 text-white dark:text-slate-900 px-5 py-2.5 rounded-full text-sm font-semibold transition-all shadow-md hover:shadow-lg hover:-translate-y-0.5 active:translate-y-0">
                        Get Started
                    </button>
                </div>
            </div>
        </header>
    );
}
