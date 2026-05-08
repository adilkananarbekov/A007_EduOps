import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "EduOps React",
  description: "React workspace for EduOps school operations",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
