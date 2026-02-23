"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
// import { Button } from "../components/ui/button";
// import { Input } from "../components/ui/input";
// import { Label } from "../components/ui/label";

export default function Login() {
  const navigate = useRouter();
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");

  // const handleLogin = (e: React.FormEvent) => {
  const handleLogin = () => {
    // e.preventDefault();
    // Mock login - redirect to admin dashboard
    navigate.push("/admin");
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
              <label htmlFor="phone">Phone Number</label>
              <input
                id="phone"
                type="tel"
                placeholder="+996 XXX XXX XXX"
                value={phone}
                onChange={(e: any) => setPhone(e.target.value)}
                className="border-border"
                required
              />
            </div>

            <div className="space-y-2">
              <label htmlFor="password">Password</label>
              <input
                id="password"
                type="password"
                placeholder="Enter your password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="border-border"
                required
              />
            </div>

            <button type="submit" className="w-full bg-primary hover:bg-primary/90">
              Log In
            </button>

            <div className="text-center">
              <a href="#" className="text-sm text-muted-foreground hover:text-foreground">
                Forgot Password?
              </a>
            </div>
          </form>

          {/* Demo Navigation */}
          <div className="mt-8 pt-6 border-t border-border">
            <p className="text-xs text-muted-foreground text-center mb-3">Quick Demo Navigation:</p>
            <div className="flex flex-wrap gap-2 justify-center">
              <Link href="/admin">
                <button className="text-xs border bg-background text-foreground hover:bg-accent hover:text-accent-foreground dark:bg-input/30 dark:border-input dark:hover:bg-input/50 h-8 rounded-md gap-1.5 px-3 has-[>svg]:px-2.5">Admin Dashboard</button>
              </Link>
              <Link href="/students">
                <button className="text-xs border bg-background text-foreground hover:bg-accent hover:text-accent-foreground dark:bg-input/30 dark:border-input dark:hover:bg-input/50 h-8 rounded-md gap-1.5 px-3 has-[>svg]:px-2.5">Students List</button>
              </Link>
              <Link href="/attendance/1">
                <button className="text-xs border bg-background text-foreground hover:bg-accent hover:text-accent-foreground dark:bg-input/30 dark:border-input dark:hover:bg-input/50 h-8 rounded-md gap-1.5 px-3 has-[>svg]:px-2.5">Attendance</button>
              </Link>
              <Link href="/parent">
                <button className="text-xs border-accent text-accent border bg-background text-foreground hover:bg-accent hover:text-accent-foreground dark:bg-input/30 dark:border-input dark:hover:bg-input/50 h-8 rounded-md gap-1.5 px-3 has-[>svg]:px-2.5">Parent/Student View</button>
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}