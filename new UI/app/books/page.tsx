import { BooksTable } from "@/components/books-table";

export default function BooksPage() {
    return (
        <main className="min-h-screen bg-slate-50 dark:bg-[#0f172a] text-slate-900 dark:text-white font-sans selection:bg-blue-100 dark:selection:bg-blue-900">
            {/* Header Section */}
            <header className="sticky top-0 z-10 backdrop-blur-lg bg-white/70 dark:bg-slate-900/80 border-b border-slate-200 dark:border-slate-800">
                <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                        <div className="h-8 w-8 bg-black dark:bg-white rounded-lg flex items-center justify-center">
                            <span className="text-white dark:text-black font-bold text-lg">L</span>
                        </div>
                        <h1 className="text-2xl font-bold tracking-tight">LIBERA</h1>
                    </div>
                    <nav className="hidden md:flex items-center gap-8">
                        {['Overview', 'Books', 'Authors', 'Community'].map((item) => (
                            <a
                                key={item}
                                href="#"
                                className={`text-sm font-medium transition-colors ${item === 'Books'
                                        ? 'text-black dark:text-white'
                                        : 'text-slate-500 hover:text-black dark:text-slate-400 dark:hover:text-white'
                                    }`}
                            >
                                {item}
                            </a>
                        ))}
                    </nav>
                    <div className="flex items-center gap-4">
                        <button className="text-sm font-medium text-slate-500 hover:text-black dark:text-slate-400 dark:hover:text-white">
                            Log in
                        </button>
                        <button className="bg-black hover:bg-slate-800 dark:bg-white dark:hover:bg-slate-200 text-white dark:text-black px-4 py-2 rounded-full text-sm font-medium transition-all">
                            Get Started
                        </button>
                    </div>
                </div>
            </header>

            {/* Hero / Content */}
            <div className="max-w-7xl mx-auto px-6 py-12">
                <div className="mb-12 text-center md:text-left">
                    <h1 className="text-4xl md:text-6xl font-bold tracking-tight mb-4 bg-clip-text text-transparent bg-gradient-to-r from-slate-900 to-slate-600 dark:from-white dark:to-slate-400">
                        Discover Your Next<br /> Great Read.
                    </h1>
                    <p className="text-lg text-slate-600 dark:text-slate-300 max-w-2xl">
                        Explore our curated collection of books from around the world. Track your reading, review titles, and join the discussion.
                    </p>
                </div>

                <BooksTable />
            </div>

            <footer className="border-t border-slate-200 dark:border-slate-800 mt-20 py-12 bg-white dark:bg-slate-900">
                <div className="max-w-7xl mx-auto px-6 text-center text-slate-400 text-sm">
                    <p>© 2024 Libera. All rights reserved.</p>
                </div>
            </footer>
        </main>
    );
}
