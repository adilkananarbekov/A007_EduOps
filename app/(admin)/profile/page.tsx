"use client";

import { useEffect, useState } from "react";

const api = process.env.NEXT_PUBLIC_API_URL;

export default function UsersPage() {
    const [ me, setMe ] = useState(null);

    useEffect(() => {
        (async () => {
            const tokensRaw = localStorage.getItem("tokens");
            const tokens = tokensRaw ? JSON.parse(tokensRaw) : null;
            // const res = await fetch("/api/v1/admin/users", {
            const res = await fetch(`${api}/auth/me`, {
                method: "GET",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `${tokens?.tokenType} ${tokens?.accessToken}`
                }
            });
            const myData = await res.json();
            console.log(myData);
            setMe(myData);
        })()
    }, []);

    return (
        <div className="text-center">
            {me && Object.entries(me).map(([key, value]) => (
                <div key={key}>
                    <strong>{key}:</strong> {String(value)}
                </div>
            ))}
        </div>
    )
}