"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function LoginForm() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    // Mock login - redirect to admin dashboard
    // const res = await fetch("/api/v1/auth/login", {
    const res = await fetch("http://localhost:8080/api/v1/auth/login", {
      method: "POST",
      headers: { 
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ email, password }),
    });
    
    if (!res.ok) {
      console.error(res.status);
      return;
    }

    const data = await res.json();
    // localStorage.setItem("userData", JSON.stringify(data));
    localStorage.setItem("tokens", JSON.stringify(data));
    // localStorage.setItem("role", data.role);
    // console.log(data);
    router.push("/");
  };

  return (
    <form onSubmit={handleLogin} className="space-y-6">
        <div className="space-y-2">
            <div>Email</div>
            <input
            id="email"
            type="email"
            placeholder="user@gmail.com"
            value={email}
            onChange={(e: any) => setEmail(e.target.value)}
            className="border-border w-full"
            required
            />
        </div>

        <div className="space-y-2">
            <div>Password</div>
            <input
            id="password"
            type="password"
            placeholder="Enter your password"
            value={password}
            onChange={(e: any) => setPassword(e.target.value)}
            className="border-border w-full"
            required
            />
        </div>

        <button type="submit" className="w-full bg-blue-500 hover:bg-blue-400">
            Log In
        </button>

        <div className="text-center">
            <a href="#" className="text-sm text-muted-foreground hover:text-foreground">
            Forgot Password?
            </a>
        </div>
    </form>
  );
}