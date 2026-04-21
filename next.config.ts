import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  // async rewrites() {
  //   return {
  //     beforeFiles: [
  //       {
  //         source: "/api/v1/:path*",
  //         destination: "http://localhost:8080/api/v1/:path*",
  //       },
  //     ],
  //   };
  // },
};

export default nextConfig;
