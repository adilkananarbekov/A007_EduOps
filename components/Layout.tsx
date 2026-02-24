"use client";

import { usePathname } from "next/navigation";
import Link from "next/link";
import { useState } from "react";
import {
  LayoutDashboard,
  Users,
  UsersRound,
  Calendar,
  ClipboardCheck,
  FileText,
  Settings,
  Home,
  CreditCard,
  MessageSquare,
  Menu,
  X,
} from "lucide-react";
import { Avatar, AvatarFallback } from "./ui/avatar";

interface LayoutProps {
  children: React.ReactNode;
  userRole?: "admin" | "parent";
}

const adminNavigation = [
  { name: "Dashboard", href: "/admin", icon: LayoutDashboard },
  { name: "Students", href: "/students", icon: Users },
  { name: "Groups", href: "/groups", icon: UsersRound },
  { name: "Schedule", href: "/schedule", icon: Calendar },
  { name: "Attendance", href: "/attendance", icon: ClipboardCheck },
  { name: "Reports", href: "/reports", icon: FileText },
  { name: "Settings", href: "/settings", icon: Settings },
];

const parentNavigation = [
  { name: "Home", href: "/parent", icon: Home },
  { name: "Schedule", href: "/parent/schedule", icon: Calendar },
  { name: "Billing & Payments", href: "/parent/billing", icon: CreditCard },
  { name: "Announcements", href: "/parent/announcements", icon: MessageSquare },
  { name: "Settings", href: "/parent/settings", icon: Settings },
];

export default function Layout({ children, userRole = "admin" }: LayoutProps) {
  const location = usePathname();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const navigation = userRole === "parent" ? parentNavigation : adminNavigation;
  const userName = userRole === "parent" ? "Alina Beknazarova" : "Admin User";
  const userEmail = userRole === "parent" ? "alina.b@example.com" : "admin@eduops.kg";
  const userInitials = userRole === "parent" ? "AB" : "AA";

  return (
    <div className="flex h-screen bg-white">
      {/* Mobile Header */}
      <div className="lg:hidden fixed top-0 left-0 right-0 z-50 bg-white border-b border-border px-4 py-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-primary rounded-md flex items-center justify-center">
              <span className="text-white text-sm font-bold">E</span>
            </div>
            <span className="text-lg font-semibold text-foreground">EduOps</span>
          </div>
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="p-2 rounded-lg hover:bg-muted transition-colors"
          >
            {mobileMenuOpen ? (
              <X className="w-6 h-6 text-foreground" />
            ) : (
              <Menu className="w-6 h-6 text-foreground" />
            )}
          </button>
        </div>
      </div>

      {/* Mobile Menu Overlay */}
      {mobileMenuOpen && (
        <div
          className="lg:hidden fixed inset-0 bg-black/50 z-40"
          onClick={() => setMobileMenuOpen(false)}
        />
      )}

      {/* Sidebar - Desktop and Mobile Drawer */}
      <div
        className={`
          fixed lg:static inset-y-0 left-0 z-40 w-64 border-r border-border bg-white flex flex-col
          transform transition-transform duration-300 ease-in-out
          ${mobileMenuOpen ? "translate-x-0" : "-translate-x-full lg:translate-x-0"}
        `}
      >
        {/* Logo - Desktop only */}
        <div className="hidden lg:block p-6 border-b border-border">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-primary rounded-md flex items-center justify-center">
              <span className="text-white text-lg font-bold">E</span>
            </div>
            <span className="text-xl font-semibold text-foreground">EduOps</span>
          </div>
        </div>

        {/* Mobile Menu Header */}
        <div className="lg:hidden p-6 border-b border-border">
          <div className="flex items-center gap-3">
            <Avatar>
              <AvatarFallback className="bg-primary text-white">{userInitials}</AvatarFallback>
            </Avatar>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-foreground truncate">{userName}</p>
              <p className="text-xs text-muted-foreground truncate">{userEmail}</p>
            </div>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
          {navigation.map((item) => {
            const isActive = location === item.href;
            const Icon = item.icon;
            return (
              <Link
                key={item.name}
                href={item.href}
                onClick={() => setMobileMenuOpen(false)}
                className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                  isActive
                    ? "bg-primary/5 text-primary"
                    : "text-muted-foreground hover:bg-accent hover:text-accent-foreground"
                }`}
              >
                <Icon className="w-5 h-5" />
                <span className="font-medium">{item.name}</span>
              </Link>
            );
          })}
        </nav>

        {/* User Profile - Desktop only */}
        <div className="hidden lg:block p-4 border-t border-border">
          <div className="flex items-center gap-3">
            <Avatar>
              <AvatarFallback className="bg-primary text-white">{userInitials}</AvatarFallback>
            </Avatar>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-foreground truncate">{userName}</p>
              <p className="text-xs text-muted-foreground truncate">{userEmail}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col overflow-hidden pt-14 lg:pt-0">
        {children}
      </div>
    </div>
  );
}