export type UserRole = "manager" | "teacher" | "student" | "admin" | string;

export type EduUser = {
  id: string;
  email: string;
  firstName?: string | null;
  lastName?: string | null;
  role: UserRole;
  className?: string | null;
  isActive?: boolean;
};

export type AuthTokens = {
  accessToken: string;
  refreshToken?: string;
  tokenType?: string;
  user?: EduUser;
};

export type ClassGroup = {
  id?: string;
  name?: string;
  className?: string;
  studentCount?: number;
};

export type LearningItem = {
  id?: string;
  title?: string;
  description?: string | null;
  subjectName?: string | null;
  className?: string | null;
  teacherName?: string | null;
  lessonDate?: string | null;
  dueAt?: string | null;
  closesAt?: string | null;
  durationMinutes?: number | null;
  gradeType?: string | null;
  coefficient?: number | null;
  submitted?: boolean;
  score?: number | null;
};

export type DashboardData = {
  gradeAverage?: number | string | null;
  pendingTests?: number | string | null;
  [key: string]: unknown;
};

export type AppStats = {
  users: EduUser[];
  groups: ClassGroup[];
  lessons: LearningItem[];
  assignments: LearningItem[];
  tests: LearningItem[];
  notifications: unknown[];
  dashboard: DashboardData;
};
