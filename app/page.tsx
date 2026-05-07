"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

const api = process.env.NEXT_PUBLIC_API_URL;

export default function Home() {
  const router = useRouter();
  useEffect(() => {
    (async () => {
        const tokensRaw = localStorage.getItem("tokens");
        if (!tokensRaw) {
            router.push("/login");
            return;
        }
        const tokens = tokensRaw ? JSON.parse(tokensRaw) : null;
        // const res = await fetch("/api/v1/users/me", {
        const res = await fetch(`${api}/auth/me`, {
            method: "GET",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `${tokens?.tokenType} ${tokens?.accessToken}`
            }
        });
        const meData = await res.json();
        console.log(meData);
        if (res.ok) {
          if (meData.role === "manager") {
            router.push("/users");
            return;
          }
        } else {
          router.push("/login");
        }
    })()
    // router.push("/login");
    // router.push("/users");
  }, []);

  return (
    <div className="w-screen h-screen">
      <div className="flex flex-col items-center justify-center h-full text-6xl">
        Redirecting...
      </div>
    </div>
  );
}
