"use client";

import { useEffect, useMemo, useState } from "react";
import { getUsers } from "@/lib/api";
import { displayName, roleLabel } from "@/lib/auth";
import type { EduUser } from "@/lib/types";

export default function UsersPage() {
  const [users, setUsers] = useState<EduUser[]>([]);
  const [query, setQuery] = useState("");
  const [role, setRole] = useState("all");
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        setUsers(await getUsers());
      } catch (err) {
        setError(err instanceof Error ? err.message : "Users failed to load.");
      } finally {
        setIsLoading(false);
      }
    }

    void load();
  }, []);

  const filteredUsers = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase();
    return users.filter((user) => {
      const matchesRole = role === "all" || user.role === role;
      const matchesQuery =
        !normalizedQuery ||
        [user.email, user.firstName, user.lastName, user.className, user.role]
          .filter(Boolean)
          .join(" ")
          .toLowerCase()
          .includes(normalizedQuery);
      return matchesRole && matchesQuery;
    });
  }, [query, role, users]);

  const roleCounts = users.reduce<Record<string, number>>((acc, user) => {
    acc[user.role] = (acc[user.role] ?? 0) + 1;
    return acc;
  }, {});

  return (
    <section className="page-stack">
      <header className="page-header">
        <div>
          <p className="eyebrow">People</p>
          <h1>Users</h1>
          <p>
            Staff and students from the live backend. Search and filter without
            leaving the page.
          </p>
        </div>
      </header>

      <div className="toolbar">
        <label className="search-field">
          <span>Search</span>
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Name, email, role, class"
          />
        </label>
        <label className="select-field">
          <span>Role</span>
          <select value={role} onChange={(event) => setRole(event.target.value)}>
            <option value="all">All roles</option>
            <option value="manager">Managers</option>
            <option value="teacher">Teachers</option>
            <option value="student">Students</option>
          </select>
        </label>
      </div>

      <div className="mini-metrics">
        {["manager", "teacher", "student"].map((item) => (
          <div key={item}>
            <span>{roleLabel(item)}</span>
            <strong>{roleCounts[item] ?? 0}</strong>
          </div>
        ))}
      </div>

      {error ? <div className="form-error">{error}</div> : null}

      <div className="user-grid">
        {isLoading ? (
          <div className="empty-state">Loading users...</div>
        ) : filteredUsers.length === 0 ? (
          <div className="empty-state">No users match this filter.</div>
        ) : (
          filteredUsers.map((user) => (
            <article key={user.id} className="user-card">
              <div className="user-card-head">
                <div className="user-avatar">{displayName(user).slice(0, 1)}</div>
                <div>
                  <h2>{displayName(user)}</h2>
                  <p>{user.email}</p>
                </div>
              </div>
              <div className="user-fields">
                <span>{roleLabel(user.role)}</span>
                <span>{user.className || "No class"}</span>
                <span>{user.isActive === false ? "Inactive" : "Active"}</span>
              </div>
            </article>
          ))
        )}
      </div>
    </section>
  );
}
