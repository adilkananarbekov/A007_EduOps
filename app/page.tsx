"use client";
import { useRouter } from "next/navigation";
import { useEffect } from "react";

export default function Home() {

  const router = useRouter();

  useEffect(() => {

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
  }, []);

  return (
    <h1>Loading...</h1>
  )
}