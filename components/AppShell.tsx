"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { clearTokens, displayName, getStoredTokens, roleLabel } from "@/lib/auth";
import { getMe } from "@/lib/api";
import type { EduUser } from "@/lib/types";

const navigation = [
  { href: "/dashboard", label: "Overview", icon: "O" },
  { href: "/users", label: "Users", icon: "U" },
  { href: "/learning", label: "Learning", icon: "L" },
  { href: "/profile", label: "Profile", icon: "P" },
];

export default function AppShell({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [user, setUser] = useState<EduUser | null>(null);
  const [isReady, setIsReady] = useState(false);

  useEffect(() => {
    const tokens = getStoredTokens();
    if (!tokens) {
      router.replace("/login");
      return;
    }

    getMe()
      .then((me) => {
        setUser(me);
        setIsReady(true);
      })
      .catch(() => {
        clearTokens();
        router.replace("/login");
      });
  }, [router]);

  function logout() {
    clearTokens();
    router.replace("/login");
  }

  if (!isReady) {
    return (
      <main className="auth-screen">
        <section className="loading-card">
          <div className="pulse-mark" />
          <p>Opening EduOps workspace...</p>
        </section>
      </main>
    );
  }

  const visibleNavigation =
    user?.role === "student"
      ? navigation.filter((item) => item.href !== "/users")
      : navigation;

  return (
    <div className="workspace-shell">
      <aside className="workspace-sidebar">
        <div className="brand-card">
          <div className="brand-mark">E</div>
          <div>
            <p className="brand-title">EduOps</p>
            <p className="brand-subtitle">React workspace</p>
          </div>
        </div>

        <nav className="workspace-nav" aria-label="Workspace navigation">
          {visibleNavigation.map((item) => {
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`nav-item ${isActive ? "active" : ""}`}
              >
                <span className="nav-icon">{item.icon}</span>
                <span>{item.label}</span>
              </Link>
            );
          })}
        </nav>

        <div className="sidebar-footer">
          <div className="user-avatar">{displayName(user).slice(0, 1)}</div>
          <div className="user-meta">
            <strong>{displayName(user)}</strong>
            <span>{roleLabel(user?.role)}</span>
          </div>
          <button className="icon-button" type="button" onClick={logout}>
            Exit
          </button>
        </div>
      </aside>

      <main className="workspace-main">{children}</main>
    </div>
  );
}
