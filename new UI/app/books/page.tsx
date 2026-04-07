import { BooksTable } from "@/components/books-table";

export default function BooksPage() {
    return (
        <main className="flex-grow w-full">
            {/* Hero / Content */}
            <div className="relative overflow-hidden w-full">
                {/* Background decorative elements */}
                <div className="absolute top-0 left-1/2 -translate-x-1/2 w-full max-w-3xl h-[400px] opacity-30 dark:opacity-10 pointer-events-none">
                    <div className="absolute inset-0 bg-gradient-to-r from-indigo-300 to-purple-400 dark:from-indigo-600 dark:to-purple-900 blur-[100px] rounded-full mix-blend-multiply dark:mix-blend-screen" />
                </div>
                
                <div className="max-w-7xl mx-auto px-6 py-20 relative z-10">
                    <div className="mb-16 text-center md:text-left max-w-3xl">
                        <div className="inline-flex items-center gap-2 mb-6 px-4 py-1.5 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-full shadow-sm text-sm font-medium text-slate-600 dark:text-slate-300">
                            <span className="relative flex h-2 w-2">
                              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-indigo-400 opacity-75"></span>
                              <span className="relative inline-flex rounded-full h-2 w-2 bg-indigo-500"></span>
                            </span>
                            Library Collection is Live
                        </div>
                        <h1 className="text-5xl md:text-7xl font-black tracking-tight mb-6 text-slate-900 dark:text-white drop-shadow-sm">
                            Discover Your Next<br />
                            <span className="bg-clip-text text-transparent bg-gradient-to-r from-indigo-500 to-purple-600 dark:from-indigo-400 dark:to-purple-500">
                                Great Read.
                            </span>
                        </h1>
                        <p className="text-lg md:text-xl text-slate-600 dark:text-slate-400 max-w-2xl leading-relaxed">
                            Explore our curated collection of books from around the world. Track your reading, review titles, and join the discussion in a beautifully responsive environment.
                        </p>
                    </div>

                    <BooksTable />
                </div>
            </div>

            <footer className="border-t border-slate-200/60 dark:border-slate-800/60 mt-20 py-12 bg-slate-50/50 dark:bg-slate-900/20">
                <div className="max-w-7xl mx-auto px-6 text-center text-slate-500 dark:text-slate-400 text-sm font-medium">
                    <p>© 2024 Liberia. All rights reserved.</p>
                </div>
            </footer>
        </main>
    );
}
