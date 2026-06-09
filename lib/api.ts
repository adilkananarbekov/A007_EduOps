import { authHeader, clearTokens, getStoredTokens } from "./auth";
import type {
  AppStats,
  AuthTokens,
  ClassGroup,
  DashboardData,
  EduUser,
  LearningItem,
} from "./types";

export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL ?? "https://adilkan.com/api/eduprog";

type RequestOptions = RequestInit & {
  auth?: boolean;
};

export class ApiError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

async function readResponse<T>(response: Response): Promise<T> {
  const text = await response.text();
  const data = text ? JSON.parse(text) : null;

  if (!response.ok) {
    const detail =
      typeof data?.detail === "string"
        ? data.detail
        : typeof data?.message === "string"
          ? data.message
          : `Request failed with ${response.status}`;
    throw new ApiError(detail, response.status);
  }

  return data as T;
}

export async function apiRequest<T>(
  path: string,
  options: RequestOptions = {},
): Promise<T> {
  const tokens = options.auth === false ? null : getStoredTokens();
  const headers = new Headers(options.headers);
  headers.set("Content-Type", "application/json");

  for (const [key, value] of Object.entries(authHeader(tokens))) {
    headers.set(key, value);
  }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers,
  });

  if (response.status === 401) {
    clearTokens();
  }

  return readResponse<T>(response);
}

export async function login(email: string, password: string): Promise<AuthTokens> {
  return apiRequest<AuthTokens>("/auth/login", {
    auth: false,
    method: "POST",
    body: JSON.stringify({ email, password }),
  });
}

export function getMe(): Promise<EduUser> {
  return apiRequest<EduUser>("/auth/me");
}

export function getUsers(): Promise<EduUser[]> {
  return apiRequest<EduUser[]>("/users");
}

export function getGroups(): Promise<ClassGroup[]> {
  return apiRequest<ClassGroup[]>("/groups");
}

export function getDashboard(): Promise<DashboardData> {
  return apiRequest<DashboardData>("/dashboard/me");
}

export function getLessons(): Promise<LearningItem[]> {
  return apiRequest<LearningItem[]>("/lessons/me");
}

export function getAssignments(): Promise<LearningItem[]> {
  return apiRequest<LearningItem[]>("/assignments/me");
}

export function getTests(): Promise<LearningItem[]> {
  return apiRequest<LearningItem[]>("/tests/me");
}

export function getNotifications(): Promise<unknown[]> {
  return apiRequest<unknown[]>("/notifications/me");
}

export async function getAppStats(user: EduUser): Promise<AppStats> {
  const canViewUsers = user.role !== "student";

  const [users, groups, lessons, assignments, tests, notifications, dashboard] =
    await Promise.all([
      canViewUsers ? getUsers().catch(() => []) : Promise.resolve([]),
      canViewUsers ? getGroups().catch(() => []) : Promise.resolve([]),
      getLessons().catch(() => []),
      getAssignments().catch(() => []),
      getTests().catch(() => []),
      getNotifications().catch(() => []),
      getDashboard().catch(() => ({})),
    ]);

  return {
    users,
    groups,
    lessons,
    assignments,
    tests,
    notifications,
    dashboard,
  };
}
