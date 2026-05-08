import LoginForm from "@/components/LoginForm";

export default function Login() {
  return (
    <main className="login-page">
      <section className="login-story" aria-labelledby="login-title">
        <div className="login-brand">
          <div className="brand-mark large logo-mark">
            <img src="/eduops-logo.png" alt="EduOps logo" />
          </div>
          <div>
            <p className="brand-kicker">EduOps React</p>
            <h1 id="login-title">Academic operations in one secure workspace.</h1>
          </div>
        </div>

        <p className="login-copy">
          A production web client for administrators, teachers, and students.
          It works with the EduOps FastAPI backend and keeps academic data in
          a role based workspace.
        </p>

        <div className="login-evidence-strip" aria-label="Platform status">
          <div>
            <strong>JWT</strong>
            <span>Secure access</span>
          </div>
          <div>
            <strong>API</strong>
            <span>Live backend</span>
          </div>
          <div>
            <strong>NGINX</strong>
            <span>Production hosting</span>
          </div>
        </div>

        <div className="login-preview-grid" aria-label="Key capabilities">
          <div className="preview-card">
            <span>01</span>
            <strong>Academic data</strong>
            <p>Users, roles, groups, lessons, assignments, tests, and notifications.</p>
          </div>
          <div className="preview-card">
            <span>02</span>
            <strong>Role permissions</strong>
            <p>Administrators manage records, teachers work with classes, and students view their learning data.</p>
          </div>
          <div className="preview-card wide">
            <span>03</span>
            <strong>Learning workflow</strong>
            <p>Lessons, assignments, tests, and profile data are loaded from the same protected API.</p>
          </div>
        </div>
      </section>

      <section className="login-panel" aria-label="Sign in">
        <div className="panel-head">
          <div>
            <p className="eyebrow">Secure access</p>
            <h2>Sign in</h2>
          </div>
          <span className="status-chip">Production</span>
        </div>
        <LoginForm />
      </section>
    </main>
  );
}
