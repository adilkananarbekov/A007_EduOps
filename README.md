# EduOps React

React/Next.js client for the EduOps demo platform. It connects to the same backend used by the Flutter app:

```env
NEXT_PUBLIC_API_URL=https://adilkan.com/api/eduprog
```

## Local Development

```bash
npm install
copy .env.example .env.local
npm run dev -- -p 3001
```

Open [http://localhost:3001](http://localhost:3001).

Demo accounts are available on the login screen for administrator, teacher, and student roles.

## Build

```bash
npm run lint
npm run build
```

The app uses `output: "export"` in `next.config.ts`, so `npm run build` creates a static `out/` directory for nginx hosting.

## Deploy

Current demo URL:

- https://azim.adilkan.com

Backend API:

- https://adilkan.com/api/eduprog
