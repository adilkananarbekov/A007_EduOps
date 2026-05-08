"use client";

import { useEffect, useState } from "react";
import { API_BASE_URL, getMe } from "@/lib/api";
import { displayName, roleLabel } from "@/lib/auth";
import type { EduUser } from "@/lib/types";

export default function ProfilePage() {
  const [me, setMe] = useState<EduUser | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getMe()
      .then(setMe)
      .catch((err) => {
        setError(err instanceof Error ? err.message : "Profile failed to load.");
      });
  }, []);

  return (
    <section className="page-stack">
      <header className="page-header">
        <div>
          <p className="eyebrow">Account</p>
          <h1>Profile and access state</h1>
          <p>Current authenticated user from /auth/me and the active API target.</p>
        </div>
        <div className="header-meta">
          <span>{me ? roleLabel(me.role) : "..."}</span>
          <small>Current role</small>
        </div>
      </header>

      {error ? <div className="form-error">{error}</div> : null}

      <div className="content-grid">
        <article className="panel profile-panel">
          <div className="profile-avatar">{displayName(me).slice(0, 1)}</div>
          <h2>{me ? displayName(me) : "Loading..."}</h2>
          <p>{me ? roleLabel(me.role) : "Checking session"}</p>
          <div className="profile-list">
            <Info label="Email" value={me?.email ?? "..."} />
            <Info label="Class" value={me?.className || "Not assigned"} />
            <Info label="Status" value={me?.isActive === false ? "Inactive" : "Active"} />
            <Info label="API" value={API_BASE_URL} />
          </div>
        </article>

        <article className="panel accent-panel">
          <p className="eyebrow">Security note</p>
          <h2>Frontend is not the security boundary</h2>
          <p>
            This React client hides staff-only navigation for students, but the
            backend remains responsible for role checks and data access.
          </p>
          <ul className="check-list">
            <li>Access token is attached only for API requests.</li>
            <li>Session data can be cleared from this browser.</li>
            <li>Public source code does not include real passwords.</li>
          </ul>
        </article>
      </div>
    </section>
  );
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div className="info-row">
      <span>{label}</span>
      <b>{value}</b>
    </div>
  );
}
