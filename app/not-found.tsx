"use client";

import Link from "next/link";
import { Button } from "../components/ui/button";
import { Home } from "lucide-react";
import { useRouter } from "next/navigation";

export default function NotFound() {
  const router = useRouter();
  return (
    <div className="min-h-screen flex items-center justify-center bg-white p-4">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-primary mb-4">404</h1>
        <h2 className="text-2xl font-semibold text-foreground mb-2">Page Not Found</h2>
        <p className="text-muted-foreground mb-6">
          The page you're looking for doesn't exist or has been moved.
        </p>
        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          {/* <Link href="/admin">
            <Button className="bg-primary hover:bg-primary/90">
              <Home className="w-4 h-4 mr-2" />
              Go to Admin Dashboard
            </Button>
          </Link>
          <Link href="/parent">
            <Button variant="outline" className="border-accent text-accent hover:bg-accent/10">
              Go to Parent View
            </Button>
          </Link> */}
          <Button onClick={() => router.back()} className="bg-primary hover:bg-primary/90">
            {"<-"} Back
          </Button>
          <Link href="/login">
            <Button variant="outline" className="border-accent text-accent hover:bg-accent/10">
              Go to Login page
            </Button>
          </Link>
        </div>
      </div>
    </div>
  );
}
