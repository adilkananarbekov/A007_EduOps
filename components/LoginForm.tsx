"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { ApiError, API_BASE_URL, login } from "@/lib/api";
import { storeTokens } from "@/lib/auth";

const demoAccounts = [
  { label: "Admin", email: "manager@eduops.kg", password: "12345678" },
  { label: "Teacher", email: "teacher1@eduops.kg", password: "12345678" },
  { label: "Student", email: "student1@eduops.kg", password: "12345678" },
];

export default function LoginForm() {
  const router = useRouter();
  const [email, setEmail] = useState("manager@eduops.kg");
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
        setError("Could not reach the EduOps API. Check CORS or network access.");
      }
    } finally {
      setIsLoading(false);
    }
  }

  async function handleLogin(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await submitLogin();
  }

  function fillDemo(emailValue: string, passwordValue: string) {
    setEmail(emailValue);
    setPassword(passwordValue);
    void submitLogin(emailValue, passwordValue);
  }

  return (
    <form onSubmit={handleLogin} className="login-form">
      <div className="api-pill">
        <span>API</span>
        <strong>{API_BASE_URL}</strong>
      </div>

      <label className="field">
        <span>Email</span>
        <input
          id="email"
          type="email"
          placeholder="manager@eduops.kg"
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

      <div className="demo-row" aria-label="Demo accounts">
        {demoAccounts.map((account) => (
          <button
            key={account.email}
            type="button"
            className="demo-button"
            disabled={isLoading}
            onClick={() => fillDemo(account.email, account.password)}
          >
            {account.label}
          </button>
        ))}
      </div>

      <p className="form-note">
        Demo mode uses the shared course backend. Do not enter real student data
        here.
      </p>
    </form>
  );
}
