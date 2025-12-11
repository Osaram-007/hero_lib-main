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
            const res = await fetch(`http://localhost:5000/books?page=${page}&limit=12`);
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
        <div className="w-full space-y-6">
            <div className="flex items-center justify-between">
                <h2 className="text-2xl font-bold text-slate-800 dark:text-white">Collection</h2>
                {/* Placeholder for search - backend doesn't support it yet */}
                <div className="relative">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
                    <input
                        type="text"
                        placeholder="Search books..."
                        className="pl-10 pr-4 py-2 rounded-full border border-slate-200 bg-white/50 backdrop-blur-sm focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all text-sm"
                    />
                </div>
            </div>

            {error ? (
                <div className="p-8 text-center text-red-500 bg-red-50 rounded-xl border border-red-100">
                    {error}
                </div>
            ) : (
                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                    {loading ? (
                        Array.from({ length: 12 }).map((_, i) => (
                            <div key={i} className="animate-pulse bg-slate-200/50 rounded-xl aspect-[2/3] w-full" />
                        ))
                    ) : (
                        books.map((book) => (
                            <div
                                key={book.ISBN}
                                className="group relative flex flex-col bg-white dark:bg-slate-800 rounded-xl overflow-hidden shadow-sm hover:shadow-xl transition-all duration-300 hover:-translate-y-1 border border-slate-100 dark:border-slate-700"
                            >
                                <div className="aspect-[2/3] overflow-hidden bg-slate-100 relative">
                                    {book["Image-URL-L"] || book["Image-URL-M"] ? (
                                        // eslint-disable-next-line @next/next/no-img-element
                                        <img
                                            src={book["Image-URL-L"] || book["Image-URL-M"]}
                                            alt={book["Book-Title"]}
                                            className="object-cover w-full h-full group-hover:scale-105 transition-transform duration-500"
                                            loading="lazy"
                                        />
                                    ) : (
                                        <div className="flex items-center justify-center h-full text-slate-300 text-4xl font-serif">
                                            {book["Book-Title"]?.[0] || "?"}
                                        </div>
                                    )}
                                    <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-end p-4">
                                        <span className="text-white font-medium text-sm truncate w-full">
                                            {book.Publisher}
                                        </span>
                                    </div>
                                </div>

                                <div className="p-4 flex flex-col flex-grow">
                                    <h3 className="font-semibold text-slate-900 dark:text-white line-clamp-2 leading-tight mb-1" title={book["Book-Title"]}>
                                        {book["Book-Title"]}
                                    </h3>
                                    <p className="text-sm text-slate-500 dark:text-slate-400 mb-2 truncate">
                                        {book["Book-Author"]}
                                    </p>
                                    <div className="mt-auto flex items-center justify-between text-xs text-slate-400 font-medium">
                                        <span>{book["Year-Of-Publication"]}</span>
                                        <span className="bg-slate-100 dark:bg-slate-700 px-2 py-0.5 rounded text-slate-600 dark:text-slate-300">
                                            Book
                                        </span>
                                    </div>
                                </div>
                            </div>
                        ))
                    )}
                </div>
            )}

            {/* Pagination */}
            <div className="flex items-center justify-center gap-4 mt-8">
                <button
                    onClick={() => setPage((p) => Math.max(1, p - 1))}
                    disabled={page === 1 || loading}
                    className="p-2 rounded-full hover:bg-slate-100 disabled:opacity-50 transition-colors"
                >
                    <ChevronLeft className="h-5 w-5" />
                </button>
                <span className="text-sm font-medium text-slate-600">
                    Page {page} of {totalPages || 1}
                </span>
                <button
                    onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                    disabled={page === totalPages || loading}
                    className="p-2 rounded-full hover:bg-slate-100 disabled:opacity-50 transition-colors"
                >
                    <ChevronRight className="h-5 w-5" />
                </button>
            </div>
        </div>
    );
}
