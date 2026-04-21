"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

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
        const res = await fetch("http://localhost:8080/api/v1/users/me", {
            method: "GET",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `${tokens?.token_type} ${tokens?.access_token}`
            }
        });
        const meData = await res.json();
        console.log(meData);
        if (res.ok) {
          if (meData.role === "ROLE_ADMIN") {
            router.push("/users");
            return;
          }
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
