"use client";

import { useEffect, useState } from "react";

const api = process.env.NEXT_PUBLIC_API_URL;

export default function UsersPage() {
    const [users, setUsers] = useState([]);

    useEffect(() => {
        (async () => {
            const tokensRaw = localStorage.getItem("tokens");
            const tokens = tokensRaw ? JSON.parse(tokensRaw) : null;
            // const res = await fetch("/api/v1/admin/users", {
            const res = await fetch(`${api}/users`, {
                method: "GET",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `${tokens?.tokenType} ${tokens?.accessToken}`
                }
            });
            const usersData = await res.json();
            console.log(usersData);
            setUsers(usersData);
        })()
    }, []);

    return (
        <div className="w-full min-h-screen bg-blue-900 px-4 md:px-32 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 place-items-center gap-6 text-1xl md:py-8 py-32">
            {users.length > 0 ? users?.map((user: any) => (
                <div key={user.id} className="bg-white p-4 flex flex-col gap-1 rounded-lg shadow-md max-w-md w-full text-black">
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
                        <span>{user.firstName} {user.lastName}</span>
                    </div>
                    <div className="border-amber-300 border-2 rounded-lg p-2 flex flex-col sm:flex-row justify-between sm:items-center items-start"> 
                        <span>Role: </span>
                        <span>{user.role}</span>
                    </div>
                    <div className="border-amber-300 border-2 rounded-lg p-2 flex flex-col sm:flex-row justify-between sm:items-center items-start"> 
                        <span>Class: </span>
                        <span>{user.className}</span>
                    </div>
                </div>
            )) : (
                <div className="text-3xl">Loading...</div>
            )}
        </div>
    )
}