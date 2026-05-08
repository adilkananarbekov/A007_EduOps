# EduOps React

React/Next.js client for the EduOps academic management platform. It connects to the same backend used by the Flutter app:

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

to use admin panel use "manager@eduops.kg" email and "12341234" password

Credentials are not committed to the repository. Keep real credentials outside Git and use `.env.local` only for local configuration.

## Build

```bash
npm run lint
npm run build
```

The app uses `output: "export"` in `next.config.ts`, so `npm run build` creates a static `out/` directory for nginx hosting.

## Deploy

Production URL:

- https://azim.adilkan.com

Backend API:

- https://adilkan.com/api/eduprog
