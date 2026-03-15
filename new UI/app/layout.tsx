import type { Metadata } from "next";
import { Inter } from "next/font/google"; // Requires internet, might fail if offline, but standard.
import "./globals.css";
import { NavBar } from "@/components/navbar";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });

export const metadata: Metadata = {
    title: "LIBERA",
    description: "Modern Library Management",
};

export default function RootLayout({
    children,
}: Readonly<{
    children: React.ReactNode;
}>) {
    return (
        <html lang="en" className="scroll-smooth">
            <body className={`${inter.className} bg-slate-50 dark:bg-[#0f172a] text-slate-900 dark:text-slate-50 antialiased selection:bg-blue-200 dark:selection:bg-blue-900/50 min-h-screen flex flex-col`}>
                <NavBar />
                <div className="flex-grow flex flex-col">
                    {children}
                </div>
            </body>
        </html>
    );
}
