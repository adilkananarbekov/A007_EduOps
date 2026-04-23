"use client";

import Link from "next/link";
import { useState } from "react";

const navElems = [
    {
        title: "All users",
        href: "/users"
    },
    {
        title: "Profile",
        href: "/profile"
    }
]

export default function AdminLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
    const [ isOpen, setIsOpen ] = useState(false);
    return (
        <>
            <nav className={`fixed flex flex-col text-3xl w-100 bg-white h-screen text-black top-0 p-6 gap-3 border-r-2 duration-300 ${isOpen ? 'translate-x-0' : '-translate-x-full'}`}>
                <div className={`mb-10 w-100 duration-300 ${isOpen ? 'translate-x-0' : 'translate-x-full'}`}>
                    <div className="w-7 h-7 md:w-15 md:h-15 group flex flex-col gap-3" onClick={() => setIsOpen(!isOpen)}>
                        <div className="w-15 h-3 bg-blue-500 group-hover:bg-blue-400 rounded-full"></div>
                        <div className="w-15 h-3 bg-blue-500 group-hover:bg-blue-400 rounded-full"></div>
                        <div className="w-15 h-3 bg-blue-500 group-hover:bg-blue-400 rounded-full"></div>
                    </div>
                </div>
                {navElems.map((elem) => (
                    <Link key={elem.href} href={elem.href} className="border-3 border-amber-300 p-3 rounded-2xl hover:bg-amber-300 hover:text-white duration-75">
                        {elem.title}
                    </Link>
                ))}
            </nav>
            {children}
        </>
    );
}