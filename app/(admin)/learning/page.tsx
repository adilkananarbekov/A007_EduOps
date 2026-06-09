"use client";

import { useEffect, useState } from "react";
import { getAssignments, getDashboard, getLessons, getTests } from "@/lib/api";
import type { DashboardData, LearningItem } from "@/lib/types";

export default function LearningPage() {
  const [lessons, setLessons] = useState<LearningItem[]>([]);
  const [assignments, setAssignments] = useState<LearningItem[]>([]);
  const [tests, setTests] = useState<LearningItem[]>([]);
  const [dashboard, setDashboard] = useState<DashboardData>({});
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const [nextLessons, nextAssignments, nextTests, nextDashboard] =
          await Promise.all([
            getLessons().catch(() => []),
            getAssignments().catch(() => []),
            getTests().catch(() => []),
            getDashboard().catch(() => ({})),
          ]);

        setLessons(nextLessons);
        setAssignments(nextAssignments);
        setTests(nextTests);
        setDashboard(nextDashboard);
      } catch (err) {
        setError(err instanceof Error ? err.message : "Learning failed to load.");
      } finally {
        setIsLoading(false);
      }
    }

    void load();
  }, []);

  return (
    <section className="page-stack">
      <header className="page-hero">
        <div>
          <p className="eyebrow">Learning workspace</p>
          <h1>Lessons, assignments, and tests in one view.</h1>
          <p>
            Built as a React client over the same EduOps learning endpoints.
          </p>
        </div>
        <div className="hero-status">
          <span>Average</span>
          <strong>{dashboard.gradeAverage ?? "N/A"}</strong>
          <small>{dashboard.pendingTests ?? 0} pending tests</small>
        </div>
      </header>

      <div className="metrics-grid">
        <Metric label="Lessons" value={lessons.length} />
        <Metric label="Assignments" value={assignments.length} />
        <Metric label="Tests" value={tests.length} />
        <Metric label="Loaded from API" value={isLoading ? "..." : "OK"} />
      </div>

      {error ? <div className="form-error">{error}</div> : null}

      <div className="content-grid three">
        <LearningPanel title="Lessons" items={lessons} empty="No lessons yet." />
        <LearningPanel
          title="Assignments"
          items={assignments}
          empty="No assignments yet."
        />
        <LearningPanel title="Tests" items={tests} empty="No tests yet." />
      </div>
    </section>
  );
}

function Metric({ label, value }: { label: string; value: number | string }) {
  return (
    <article className="metric-card">
      <span>{label}</span>
      <strong>{value}</strong>
      <p>Live endpoint data</p>
    </article>
  );
}

function LearningPanel({
  title,
  items,
  empty,
}: {
  title: string;
  items: LearningItem[];
  empty: string;
}) {
  return (
    <article className="panel">
      <div className="panel-title">
        <div>
          <p className="eyebrow">Section</p>
          <h2>{title}</h2>
        </div>
        <span className="status-chip">{items.length}</span>
      </div>

      <div className="list-stack">
        {items.length === 0 ? (
          <div className="empty-state compact">{empty}</div>
        ) : (
          items.slice(0, 8).map((item, index) => (
            <div className="info-row" key={item.id ?? `${title}-${index}`}>
              <div>
                <strong>{item.title || title}</strong>
                <span>
                  {[item.subjectName, item.className, item.teacherName]
                    .filter(Boolean)
                    .join(" / ") || "No metadata"}
                </span>
              </div>
              <b>{item.score ?? item.coefficient ?? item.durationMinutes ?? ""}</b>
            </div>
          ))
        )}
      </div>
    </article>
  );
}
