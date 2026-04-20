"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export default function Login() {
  const navigate = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    // Mock login - redirect to admin dashboard
    const res = await fetch("http://localhost:8080/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    });
    
    if (!res.ok) {
      console.error(res.status);
      return;
    }

    const data = await res.json();
    localStorage.setItem("userData", JSON.stringify(data));
    // localStorage.setItem("token", data.token);
    // localStorage.setItem("role", data.role);
    // console.log(data);
    navigate.push("/");
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-white">
      <div className="w-full max-w-md">
        <div className="bg-white border border-border rounded-lg shadow-sm p-8">
          {/* Logo and Brand */}
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-20 h-20 mb-4 bg-primary rounded-lg">
              <span className="text-3xl font-bold text-white">E</span>
            </div>
            <h1 className="text-3xl font-semibold text-foreground">EduOps</h1>
            <p className="text-muted-foreground mt-2">School Management System</p>
            <p className="text-sm text-muted-foreground mt-1">Ala-Too International University</p>
          </div>

          {/* Login Form */}
          <form onSubmit={handleLogin} className="space-y-6">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="user@gmail.com"
                value={email}
                onChange={(e: any) => setEmail(e.target.value)}
                className="border-border"
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                placeholder="Enter your password"
                value={password}
                onChange={(e: any) => setPassword(e.target.value)}
                className="border-border"
                required
              />
            </div>

            <Button type="submit" className="w-full bg-primary hover:bg-primary/90">
              Log In
            </Button>

            <div className="text-center">
              <a href="#" className="text-sm text-muted-foreground hover:text-foreground">
                Forgot Password?
              </a>
            </div>
          </form>

          {/* Demo Navigation */}
          {/* <div className="mt-8 pt-6 border-t border-border">
            <p className="text-xs text-muted-foreground text-center mb-3">Quick Demo Navigation:</p>
            <div className="flex flex-wrap gap-2 justify-center">
              <Link href="/admin">
                <Button variant="outline" size="sm" className="text-xs">Admin Dashboard</Button>
              </Link>
              <Link href="/students">
                <Button variant="outline" size="sm" className="text-xs">Students List</Button>
              </Link>
              <Link href="/attendance/1">
                <Button variant="outline" size="sm" className="text-xs">Attendance</Button>
              </Link>
              <Link href="/parent">
                <Button variant="outline" size="sm" className="text-xs border-accent text-accent">Parent/Student View</Button>
              </Link>
            </div>
          </div> */}
        </div>
      </div>
    </div>
  );
}