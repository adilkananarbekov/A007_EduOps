"use client";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";

export default function Home() {

  const router = useRouter();
  const [dots, setDots] = useState(1);

  useEffect(() => {
    const interval = setInterval(() => {
      setDots((prev) => (prev === 3 ? 1 : prev + 1));
    }, 150); // speed control here

    // const role = localStorage.getItem("role");
    // const token = localStorage.getItem("token");
    const userDataRaw = localStorage.getItem("userData");
    // if (!token || !role) {
    //   router.replace("/login");
    // }
    if (!userDataRaw) {
      router.replace("/login");
      return;
    }
    const userData = JSON.parse(userDataRaw);
    const token = userData.token;
    const role = userData.role;
    if (role === "ADMIN") {
      (async () => {
        const res = await fetch("http://136.116.64.6/api/admin/users", {
          method: "GET",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          }
        });
        if (res.ok) {
          router.replace("/admin");
        } else {
          router.replace("/login");
        }
      })();
      
    } else if (role === "STUDENT") {
      router.replace("/parent");
    } else {
      router.replace("/login");
    }
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="flex items-center justify-center h-screen">
      <h1>Loading{".".repeat(dots)}</h1>
    </div>
  )
}