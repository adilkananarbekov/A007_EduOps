"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { ApiError, login } from "@/lib/api";
import { storeTokens } from "@/lib/auth";

export default function LoginForm() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  async function submitLogin(nextEmail = email, nextPassword = password) {
    setError(null);
    setIsLoading(true);

    try {
      const tokens = await login(nextEmail.trim(), nextPassword);
      storeTokens(tokens);
      router.replace("/dashboard");
    } catch (err) {
      if (err instanceof ApiError) {
        setError(err.message);
      } else {
        setError("Could not reach EduOps. Please try again later.");
      }
    } finally {
      setIsLoading(false);
    }
  }

  async function handleLogin(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await submitLogin();
  }

  return (
    <form onSubmit={handleLogin} className="login-form">
      <label className="field">
        <span>Email</span>
        <input
          id="email"
          type="email"
          placeholder="name@eduops.kg"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
          autoComplete="username"
          required
        />
      </label>

      <label className="field">
        <span>Password</span>
        <input
          id="password"
          type="password"
          placeholder="Enter password"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
          autoComplete="current-password"
          required
        />
      </label>

      {error ? <div className="form-error">{error}</div> : null}

      <button type="submit" className="primary-action" disabled={isLoading}>
        {isLoading ? "Signing in..." : "Enter workspace"}
      </button>
    </form>
  );
}
