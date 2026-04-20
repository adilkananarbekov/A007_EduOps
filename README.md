# EduOps

EduOps is a Flutter-based education management app with admin and parent flows.
This repository also includes a separate `EduOps Web design` folder that looks
like a React/Vite design prototype rather than the main production app.

## Flutter App

- State management: Riverpod
- Routing: GoRouter
- API access: `http` via a small `ApiClient` wrapper
- Platforms: Android, iOS, web, desktop

## Setup

1. Install Flutter and run `flutter pub get`
2. Start the app with the default local backend:
   `flutter run`
3. Override the backend URL when needed:
   `flutter run --dart-define=EDUOPS_BASE_URL=http://136.116.64.6`
4. To point at a specific local backend explicitly:
   `flutter run --dart-define=EDUOPS_BASE_URL=http://localhost:8080`
5. If your backend uses a different API prefix:
   `flutter run --dart-define=EDUOPS_API_PREFIX=/api`

## Security Notes

- The local dev backend uses plain HTTP. Android and iOS include cleartext exceptions so the app can reach local or remote HTTP backends.
- Move the backend to HTTPS for production use.

## Useful Commands

- `flutter analyze`
- `flutter test`
- `flutter run`

## Current Focus Areas

- Connect missing backend-managed features such as teacher-subject assignment
- Replace placeholder settings screens with persisted backend-driven forms
- Decide whether the React prototype should stay separate or be promoted into a maintained app
