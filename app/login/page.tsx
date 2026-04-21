import LoginForm from "@/components/LoginForm";

export default function Login() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-900">
      <div className="w-full max-w-md">
        <div className="bg-gray-800 border border-border rounded-lg shadow-sm p-8">
          {/* Logo and Brand */}
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-20 h-20 mb-4 bg-blue-500 rounded-lg">
              <span className="text-3xl font-bold text-white">E</span>
            </div>
            <h1 className="text-3xl font-semibold text-foreground">EduOps</h1>
            <p className="text-muted-foreground mt-2">School Management System</p>
            <p className="text-sm text-muted-foreground mt-1">Ala-Too International University</p>
          </div>

          {/* Login Form */}
          <LoginForm></LoginForm>

        </div>
      </div>
    </div>
  );
}