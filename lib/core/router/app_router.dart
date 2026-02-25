import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../layouts/admin_layout.dart';
import '../../layouts/parent_layout.dart';
import '../../pages/login_page.dart';
import '../../pages/admin/admin_dashboard_page.dart';
import '../../pages/admin/students_list_page.dart';
import '../../pages/admin/student_profile_page.dart';
import '../../pages/admin/groups_page.dart';
import '../../pages/admin/schedule_page.dart';
import '../../pages/admin/week_schedule_page.dart';
import '../../pages/admin/attendance_marking_page.dart';
import '../../pages/admin/billing_page.dart';
import '../../pages/admin/reports_page.dart';
import '../../pages/admin/settings_page.dart';
import '../../pages/parent/parent_dashboard_page.dart';
import '../../pages/parent/mobile_schedule_page.dart';
import '../../pages/parent/mobile_billing_page.dart';
import '../../pages/parent/announcements_page.dart';
import '../../pages/parent/parent_settings_page.dart';
import '../../pages/not_found_page.dart';
import '../../pages/splash_page.dart';
import '../providers/providers.dart';
import '../models/user_role.dart';

GoRouter appRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/splash',
    errorBuilder: (context, state) => const NotFoundPage(),
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isSplashRoute = state.matchedLocation == '/splash';
      final isLoginRoute = state.matchedLocation == '/login';

      if (authState.isLoading) {
        return isSplashRoute ? null : '/splash';
      }

      final currentUser = authState.value;
      final isAuthenticated = currentUser != null;

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      // If authenticated and trying to access splash/login page, redirect by role
      if (isAuthenticated && (isLoginRoute || isSplashRoute)) {
        if (currentUser.role == UserRole.STUDENT) {
          return '/parent';
        } else {
          return '/admin';
        }
      }

      if (!isAuthenticated && isSplashRoute) {
        return '/login';
      }

      // Allow navigation
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),

      // ─── Login ─────────────────────────────────────────────────────────────
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      // ─── Admin Shell ────────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            AdminLayout(currentRoute: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: '/admin/students',
            builder: (context, state) => const StudentsListPage(),
          ),
          GoRoute(
            path: '/admin/students/:id',
            builder: (context, state) =>
                StudentProfilePage(studentId: state.pathParameters['id'] ?? ''),
          ),
          GoRoute(
            path: '/admin/groups',
            builder: (context, state) => const GroupsPage(),
          ),
          GoRoute(
            path: '/admin/schedule',
            builder: (context, state) => const SchedulePage(),
          ),
          GoRoute(
            path: '/admin/week-schedule',
            builder: (context, state) => const WeekSchedulePage(),
          ),
          GoRoute(
            path: '/admin/attendance',
            builder: (context, state) => const AttendanceMarkingPage(),
          ),
          GoRoute(
            path: '/admin/attendance/:groupId',
            builder: (context, state) =>
                AttendanceMarkingPage(groupId: state.pathParameters['groupId']),
          ),
          GoRoute(
            path: '/admin/billing',
            builder: (context, state) => const BillingPage(),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (context, state) => const ReportsPage(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),

      // ─── Parent Shell ────────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            ParentLayout(currentRoute: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/parent',
            builder: (context, state) => const ParentDashboardPage(),
          ),
          GoRoute(
            path: '/parent/schedule',
            builder: (context, state) => const MobileSchedulePage(),
          ),
          GoRoute(
            path: '/parent/billing',
            builder: (context, state) => const MobileBillingPage(),
          ),
          GoRoute(
            path: '/parent/announcements',
            builder: (context, state) => const AnnouncementsPage(),
          ),
          GoRoute(
            path: '/parent/settings',
            builder: (context, state) => const ParentSettingsPage(),
          ),
        ],
      ),
    ],
  );
}
