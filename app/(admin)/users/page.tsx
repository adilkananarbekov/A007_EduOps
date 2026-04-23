"use client";

import { useEffect, useState } from "react";

export default function UsersPage() {
    const [users, setUsers] = useState([]);

    useEffect(() => {
        (async () => {
            const tokensRaw = localStorage.getItem("tokens");
            const tokens = tokensRaw ? JSON.parse(tokensRaw) : null;
            // const res = await fetch("/api/v1/admin/users", {
            const res = await fetch("http://localhost:8080/api/v1/admin/users", {
                method: "GET",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `${tokens?.token_type} ${tokens?.access_token}`
                }
            });
            const usersData = await res.json();
            console.log(usersData);
            setUsers(usersData);
        })()
    }, []);

    return (
        <div className="w-full min-h-screen bg-blue-900 flex flex-col items-center justify-start gap-6 text-1xl md:py-8 py-32">
            {users.length > 0 ? users?.map((user: any) => (
                <div key={user.id} className="bg-white p-4 flex flex-col gap-1 rounded-lg shadow-md lg:w-[36%] md:w-[50%] sm:w-[70%] w-[85%] text-black">
                    <div className="border-amber-300 border-2 rounded-lg p-2 flex sm:justify-between justify-start items-center"> 
                        <span>ID: </span>
                        <span>{user.id}</span>
                    </div>
                    <div className="border-amber-300 border-2 rounded-lg p-2 flex flex-col sm:flex-row justify-between sm:items-center items-start"> 
                        <span>Email: </span>
                        <span>{user.email}</span>
                    </div>
                    <div className="border-amber-300 border-2 rounded-lg p-2 flex flex-col sm:flex-row justify-between sm:items-center items-start"> 
                        <span>Name: </span>
                        <span>{user.full_name}</span>
                    </div>
                    <div className="border-amber-300 border-2 rounded-lg p-2 flex flex-col sm:flex-row justify-between sm:items-center items-start"> 
                        <span>Role: </span>
                        <span>{user.role}</span>
                    </div>
                </div>
            )) : (
                <div className="text-3xl">Loading...</div>
            )}
        </div>
    )
}