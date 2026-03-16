"use client";

import { useEffect, useState } from "react";
import { cn } from "@/lib/utils";
import { ChevronLeft, ChevronRight, Search } from "lucide-react";

type Book = {
    "ISBN": string;
    "Book-Title": string;
    "Book-Author": string;
    "Year-Of-Publication": string | number;
    "Publisher": string;
    "Image-URL-M": string;
    "Image-URL-L": string;
};

export function BooksTable() {
    const [books, setBooks] = useState<Book[]>([]);
    const [loading, setLoading] = useState(true);
    const [page, setPage] = useState(1);
    const [totalPages, setTotalPages] = useState(0);
    const [error, setError] = useState("");

    const fetchBooks = async (page: number) => {
        setLoading(true);
        setError("");
        try {
            const apiUrl = process.env.NEXT_PUBLIC_API_URL || "";
            const res = await fetch(`${apiUrl}/api/books?page=${page}&limit=12`);
            if (!res.ok) throw new Error("Failed to fetch books");
            const data = await res.json();
            setBooks(data.data);
            setTotalPages(data.pages);
            setPage(data.page);
        } catch (err) {
            setError("Error loading books. Make sure the backend is running.");
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchBooks(page);
    }, [page]);

    return (
        <div className="w-full space-y-8">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-6">
                <h2 className="text-3xl font-bold text-slate-900 dark:text-white">Trending Books</h2>
                {/* Search */}
                <div className="relative w-full sm:w-80 group">
                    <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400 group-focus-within:text-indigo-500 transition-colors" />
                    <input
                        type="text"
                        placeholder="Search books..."
                        className="w-full pl-12 pr-4 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:border-indigo-500 transition-all text-sm font-medium dark:text-white placeholder:text-slate-400"
                    />
                </div>
            </div>

            {error ? (
                <div className="p-8 text-center text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 rounded-2xl border border-red-100 dark:border-red-900/50 font-medium">
                    {error}
                </div>
            ) : (
                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6 lg:gap-8">
                    {loading ? (
                        Array.from({ length: 12 }).map((_, i) => (
                            <div key={i} className="animate-pulse bg-slate-200 dark:bg-slate-800 rounded-2xl aspect-[2/3] w-full shadow-sm" />
                        ))
                    ) : (
                        books.map((book) => (
                            <div
                                key={book.ISBN}
                                className="group relative flex flex-col bg-white dark:bg-slate-800 rounded-2xl overflow-hidden shadow-sm hover:shadow-2xl transition-all duration-500 hover:-translate-y-2 border border-slate-100 dark:border-slate-700/50"
                            >
                                <div className="aspect-[2/3] overflow-hidden bg-gradient-to-br from-slate-100 to-slate-200 dark:from-slate-700 dark:to-slate-800 relative ring-1 ring-inset ring-black/5 dark:ring-white/10">
                                    {book["Image-URL-L"] || book["Image-URL-M"] ? (
                                        // eslint-disable-next-line @next/next/no-img-element
                                        <img
                                            src={book["Image-URL-L"] || book["Image-URL-M"]}
                                            alt={book["Book-Title"]}
                                            className="object-cover w-full h-full group-hover:scale-110 transition-transform duration-700 ease-in-out"
                                            loading="lazy"
                                        />
                                    ) : (
                                        <div className="flex items-center justify-center h-full text-slate-400 dark:text-slate-500 text-5xl font-serif opacity-30 group-hover:scale-110 transition-transform duration-700">
                                            {book["Book-Title"]?.[0] || "?"}
                                        </div>
                                    )}
                                    <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-end p-5">
                                        <div className="translate-y-4 group-hover:translate-y-0 transition-transform duration-300 w-full">
                                            <span className="text-white/90 font-semibold text-sm truncate block w-full mb-1">
                                                {book.Publisher}
                                            </span>
                                            <span className="text-white/60 text-xs font-medium">
                                                ISBN: {book.ISBN}
                                            </span>
                                        </div>
                                    </div>
                                </div>

                                <div className="p-5 flex flex-col flex-grow bg-white dark:bg-slate-800 group-hover:bg-slate-50 dark:group-hover:bg-slate-800/80 transition-colors duration-300">
                                    <h3 className="font-bold text-slate-900 dark:text-white line-clamp-2 leading-tight mb-2" title={book["Book-Title"]}>
                                        {book["Book-Title"]}
                                    </h3>
                                    <p className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-4 truncate">
                                        {book["Book-Author"]}
                                    </p>
                                    <div className="mt-auto flex items-center justify-between">
                                        <span className="text-xs font-bold text-slate-400 dark:text-slate-500">
                                            {book["Year-Of-Publication"]}
                                        </span>
                                        <span className="bg-indigo-50 dark:bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 px-2.5 py-1 rounded-md text-xs font-bold tracking-wide">
                                            BOOK
                                        </span>
                                    </div>
                                </div>
                            </div>
                        ))
                    )}
                </div>
            )}

            {/* Pagination */}
            <div className="flex items-center justify-center gap-6 mt-12 mb-8">
                <button
                    onClick={() => setPage((p) => Math.max(1, p - 1))}
                    disabled={page === 1 || loading}
                    className="p-3 rounded-full bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 shadow-sm hover:shadow-md hover:border-slate-300 dark:hover:border-slate-600 disabled:opacity-50 disabled:pointer-events-none transition-all focus:outline-none focus:ring-2 focus:ring-indigo-500/50"
                >
                    <ChevronLeft className="h-5 w-5" />
                </button>
                <div className="flex items-center gap-2">
                    <span className="text-sm font-semibold text-slate-500 dark:text-slate-400">Page</span>
                    <span className="flex items-center justify-center h-8 min-w-[32px] px-2 rounded-lg bg-slate-100 dark:bg-slate-800 text-sm font-bold text-slate-900 dark:text-white border border-slate-200 dark:border-slate-700">
                        {page}
                    </span>
                    <span className="text-sm font-semibold text-slate-500 dark:text-slate-400">of {totalPages || 1}</span>
                </div>
                <button
                    onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                    disabled={page === totalPages || loading}
                    className="p-3 rounded-full bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 shadow-sm hover:shadow-md hover:border-slate-300 dark:hover:border-slate-600 disabled:opacity-50 disabled:pointer-events-none transition-all focus:outline-none focus:ring-2 focus:ring-indigo-500/50"
                >
                    <ChevronRight className="h-5 w-5" />
                </button>
            </div>
        </div>
    );
}
