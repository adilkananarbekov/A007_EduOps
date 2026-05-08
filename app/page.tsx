"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { getStoredTokens } from "@/lib/auth";

export default function Home() {
  const router = useRouter();

  useEffect(() => {
    router.replace(getStoredTokens() ? "/dashboard" : "/login");
  }, [router]);

  return (
    <main className="auth-screen">
      <section className="loading-card">
        <div className="pulse-mark" />
        <p>Redirecting...</p>
      </section>
    </main>
  );
}
