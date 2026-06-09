"use client";

import { useEffect, useState } from "react";
import { displayName, roleLabel } from "@/lib/auth";
import { getAppStats, getMe } from "@/lib/api";
import type { AppStats, EduUser } from "@/lib/types";

const emptyStats: AppStats = {
  users: [],
  groups: [],
  lessons: [],
  assignments: [],
  tests: [],
  notifications: [],
  dashboard: {},
};

export default function DashboardPage() {
  const [user, setUser] = useState<EduUser | null>(null);
  const [stats, setStats] = useState<AppStats>(emptyStats);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const me = await getMe();
        setUser(me);
        setStats(await getAppStats(me));
      } catch (err) {
        setError(err instanceof Error ? err.message : "Dashboard failed to load.");
      } finally {
        setIsLoading(false);
      }
    }

    void load();
  }, []);

  const average = stats.dashboard.gradeAverage;
  const metricCards = [
    {
      label: user?.role === "student" ? "My lessons" : "Users",
      value: user?.role === "student" ? stats.lessons.length : stats.users.length,
      detail:
        user?.role === "student"
          ? "Lessons available to this account"
          : "People loaded from /users",
    },
    {
      label: user?.role === "student" ? "Assignments" : "Groups",
      value:
        user?.role === "student" ? stats.assignments.length : stats.groups.length,
      detail:
        user?.role === "student"
          ? "Open learning tasks"
          : "Class groups from the backend",
    },
    {
      label: "Tests",
      value: stats.tests.length,
      detail:
        stats.dashboard.pendingTests == null
          ? "Assessments available"
          : `${stats.dashboard.pendingTests} pending tests`,
    },
    {
      label: "Updates",
      value: stats.notifications.length,
      detail: "Notifications for this account",
    },
  ];

  return (
    <section className="page-stack">
      <header className="page-hero">
        <div>
          <p className="eyebrow">EduOps React</p>
          <h1>
            {isLoading
              ? "Loading workspace"
              : `Welcome, ${displayName(user).split(" ")[0]}`}
          </h1>
          <p>
            {error ??
              `Signed in as ${roleLabel(user?.role)}. This dashboard reads live data from the EduOps API.`}
          </p>
        </div>
        <div className="hero-status">
          <span>API</span>
          <strong>{error ? "Needs attention" : "Online"}</strong>
          {average != null ? <small>Average {String(average)}</small> : null}
        </div>
      </header>

      <div className="metrics-grid">
        {metricCards.map((metric) => (
          <article key={metric.label} className="metric-card">
            <span>{metric.label}</span>
            <strong>{isLoading ? "..." : metric.value}</strong>
            <p>{metric.detail}</p>
          </article>
        ))}
      </div>

      <div className="content-grid">
        <article className="panel">
          <div className="panel-title">
            <div>
              <p className="eyebrow">Learning</p>
              <h2>Current academic load</h2>
            </div>
          </div>
          <div className="list-stack">
            <InfoRow
              title="Lessons"
              value={`${stats.lessons.length} items`}
              detail="Course material and class content"
            />
            <InfoRow
              title="Assignments"
              value={`${stats.assignments.length} items`}
              detail="Tasks and deadlines"
            />
            <InfoRow
              title="Tests"
              value={`${stats.tests.length} items`}
              detail="Assessments from /tests/me"
            />
          </div>
        </article>

        <article className="panel accent-panel">
          <div className="panel-title">
            <div>
              <p className="eyebrow">Readiness</p>
              <h2>What this React version already has</h2>
            </div>
          </div>
          <ul className="check-list">
            <li>JWT login against the current backend</li>
            <li>Role-aware navigation for staff and students</li>
            <li>Responsive desktop and mobile layout</li>
            <li>Static export ready for nginx hosting</li>
          </ul>
        </article>
      </div>
    </section>
  );
}

function InfoRow({
  title,
  value,
  detail,
}: {
  title: string;
  value: string;
  detail: string;
}) {
  return (
    <div className="info-row">
      <div>
        <strong>{title}</strong>
        <span>{detail}</span>
      </div>
      <b>{value}</b>
    </div>
  );
}
