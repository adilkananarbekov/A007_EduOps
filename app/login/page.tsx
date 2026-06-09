import LoginForm from "@/components/LoginForm";

export default function Login() {
  return (
    <main className="login-page">
      <section className="login-story" aria-labelledby="login-title">
        <div className="login-brand">
          <div className="brand-mark large">E</div>
          <div>
            <p className="brand-kicker">EduOps React</p>
            <h1 id="login-title">School operations without the noise.</h1>
          </div>
        </div>

        <p className="login-copy">
          A focused workspace for managers, teachers, and students. The React
          client uses the same EduOps backend as the deployed Flutter app.
        </p>

        <div className="login-preview-grid">
          <div className="preview-card">
            <span>01</span>
            <strong>Live API</strong>
            <p>JWT auth, role-aware screens, users, lessons, tests, and reports.</p>
          </div>
          <div className="preview-card">
            <span>02</span>
            <strong>Course demo</strong>
            <p>Demo accounts stay visible so the project is easy to defend.</p>
          </div>
          <div className="preview-card wide">
            <span>03</span>
            <strong>Desktop first</strong>
            <p>Dense, readable layouts for repeated school operations work.</p>
          </div>
        </div>
      </section>

      <section className="login-panel" aria-label="Sign in">
        <div className="panel-head">
          <div>
            <p className="eyebrow">Secure access</p>
            <h2>Sign in</h2>
          </div>
          <span className="status-chip">Test mode</span>
        </div>
        <LoginForm />
      </section>
    </main>
  );
}
