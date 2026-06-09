import type { AuthTokens, EduUser } from "./types";

const TOKEN_KEY = "eduops.react.tokens";
const LEGACY_TOKEN_KEY = "tokens";

export function getStoredTokens(): AuthTokens | null {
  if (typeof window === "undefined") {
    return null;
  }

  const raw =
    window.localStorage.getItem(TOKEN_KEY) ??
    window.localStorage.getItem(LEGACY_TOKEN_KEY);

  if (!raw) {
    return null;
  }

  try {
    const parsed = JSON.parse(raw) as AuthTokens;
    return parsed.accessToken ? parsed : null;
  } catch {
    return null;
  }
}

export function storeTokens(tokens: AuthTokens): void {
  window.localStorage.setItem(TOKEN_KEY, JSON.stringify(tokens));
  window.localStorage.removeItem(LEGACY_TOKEN_KEY);
}

export function clearTokens(): void {
  window.localStorage.removeItem(TOKEN_KEY);
  window.localStorage.removeItem(LEGACY_TOKEN_KEY);
}

export function authHeader(tokens: AuthTokens | null): HeadersInit {
  if (!tokens?.accessToken) {
    return {};
  }

  const scheme = tokens.tokenType?.toLowerCase() === "bearer" ? "Bearer" : "Bearer";
  return {
    Authorization: `${scheme} ${tokens.accessToken}`,
  };
}

export function displayName(user: EduUser | null | undefined): string {
  const fullName = [user?.firstName, user?.lastName]
    .filter(Boolean)
    .join(" ")
    .trim();
  return fullName || user?.email || "EduOps user";
}

export function roleLabel(role: string | null | undefined): string {
  switch (role) {
    case "manager":
    case "admin":
      return "Administrator";
    case "teacher":
      return "Teacher";
    case "student":
      return "Student";
    default:
      return role || "User";
  }
}
