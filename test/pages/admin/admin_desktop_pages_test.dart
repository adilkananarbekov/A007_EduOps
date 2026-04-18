import 'package:eduprog/core/api/api_client.dart';
import 'package:eduprog/core/models/attendance.dart';
import 'package:eduprog/core/models/auth_response.dart';
import 'package:eduprog/core/models/class_group.dart';
import 'package:eduprog/core/models/grade.dart';
import 'package:eduprog/core/models/schedule.dart';
import 'package:eduprog/core/models/student.dart';
import 'package:eduprog/core/models/user_role.dart';
import 'package:eduprog/core/providers/providers.dart';
import 'package:eduprog/core/services/admin_service.dart';
import 'package:eduprog/core/services/attendance_service.dart';
import 'package:eduprog/core/services/grade_service.dart';
import 'package:eduprog/core/services/schedule_service.dart';
import 'package:eduprog/core/theme/app_theme.dart';
import 'package:eduprog/layouts/admin_layout.dart';
import 'package:eduprog/pages/admin/attendance_marking_page.dart';
import 'package:eduprog/pages/admin/attendance_overview_page.dart';
import 'package:eduprog/pages/admin/reports_page.dart';
import 'package:eduprog/pages/admin/students_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final adminUser = AuthResponse(
    token: 'token',
    type: 'Bearer',
    userId: 1,
    email: 'admin@edupage.com',
    firstName: 'System',
    lastName: 'Admin',
    role: UserRole.ADMIN,
  );

  final group10A = ClassGroup(id: 1, name: '10A', grade: 10, studentCount: 3);
  final schedule10A = Schedule(
    id: 1,
    classGroupId: 1,
    classGroupName: '10A',
    subjectId: 1,
    subjectName: 'Class #1',
    teacherId: 2,
    dayOfWeek: 'THURSDAY',
    startTime: '09:00',
    endTime: '09:45',
    room: 'A-201',
  );
  final students10A = <Student>[
    Student(
      id: 1,
      userId: 5,
      name: 'Alice Johnson',
      email: 'alice@edupage.com',
      classGroupId: 1,
      classGroupName: '10A',
    ),
    Student(
      id: 2,
      userId: 6,
      name: 'Bob Williams',
      email: 'bob@edupage.com',
      classGroupId: 1,
      classGroupName: '10A',
    ),
    Student(
      id: 3,
      userId: 7,
      name: 'Diana Keller',
      email: 'diana@edupage.com',
      classGroupId: 1,
      classGroupName: '10A',
    ),
  ];

  Future<void> pumpDesktopPage(
    WidgetTester tester, {
    required Widget child,
    required AdminService adminService,
    ScheduleService? scheduleService,
    AttendanceService? attendanceService,
    GradeService? gradeService,
  }) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => adminUser),
          adminServiceProvider.overrideWith((ref) => adminService),
          if (scheduleService != null)
            scheduleServiceProvider.overrideWith((ref) => scheduleService),
          if (attendanceService != null)
            attendanceServiceProvider.overrideWith((ref) => attendanceService),
          if (gradeService != null)
            gradeServiceProvider.overrideWith((ref) => gradeService),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: Scaffold(body: SizedBox.expand(child: child)),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();
  }

  Future<void> pumpMobilePage(
    WidgetTester tester, {
    required Widget child,
    required AdminService adminService,
    ScheduleService? scheduleService,
    AttendanceService? attendanceService,
    GradeService? gradeService,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => adminUser),
          adminServiceProvider.overrideWith((ref) => adminService),
          if (scheduleService != null)
            scheduleServiceProvider.overrideWith((ref) => scheduleService),
          if (attendanceService != null)
            attendanceServiceProvider.overrideWith((ref) => attendanceService),
          if (gradeService != null)
            gradeServiceProvider.overrideWith((ref) => gradeService),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: Scaffold(body: SizedBox.expand(child: child)),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();
  }

  Future<void> pumpDesktopRouter(
    WidgetTester tester, {
    required AdminService adminService,
    ScheduleService? scheduleService,
    AttendanceService? attendanceService,
    GradeService? gradeService,
    String initialLocation =
        '/admin/attendance/mark?scheduleId=1&groupId=1&date=2026-04-23',
  }) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminLayout(
            currentRoute: '/admin',
            child: Center(child: Text('Admin home')),
          ),
        ),
        GoRoute(
          path: '/admin/attendance',
          builder: (context, state) => const AdminLayout(
            currentRoute: '/admin/attendance',
            child: AttendanceOverviewPage(),
          ),
        ),
        GoRoute(
          path: '/admin/attendance/mark',
          builder: (context, state) => AdminLayout(
            currentRoute: '/admin/attendance/mark',
            child: AttendanceMarkingPage(
              groupId: state.uri.queryParameters['groupId'],
              initialScheduleId: int.tryParse(
                state.uri.queryParameters['scheduleId'] ?? '',
              ),
              initialDate: DateTime.tryParse(
                state.uri.queryParameters['date'] ?? '',
              ),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => adminUser),
          adminServiceProvider.overrideWith((ref) => adminService),
          if (scheduleService != null)
            scheduleServiceProvider.overrideWith((ref) => scheduleService),
          if (attendanceService != null)
            attendanceServiceProvider.overrideWith((ref) => attendanceService),
          if (gradeService != null)
            gradeServiceProvider.overrideWith((ref) => gradeService),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Attendance detail page shows compact desktop table with full class roster',
    (tester) async {
      await pumpDesktopPage(
        tester,
        child: AttendanceMarkingPage(
          groupId: '1',
          initialScheduleId: 1,
          initialDate: DateTime(2026, 4, 23),
        ),
        adminService: _FakeAdminService(
          groups: [group10A],
          studentsByGroup: {1: students10A},
          accessibleStudents: students10A,
        ),
        scheduleService: _FakeScheduleService(
          schedulesByGroup: {1: [schedule10A]},
        ),
        attendanceService: _FakeAttendanceService(
          scheduleAttendanceById: {
            1: [
              Attendance(
                id: 1,
                studentId: 1,
                studentName: 'Alice Johnson',
                scheduleId: 1,
                subjectName: 'Class #1',
                date: DateTime(2026, 4, 23),
                status: AttendanceStatus.PRESENT,
              ),
              Attendance(
                id: 2,
                studentId: 2,
                studentName: 'Bob Williams',
                scheduleId: 1,
                subjectName: 'Class #1',
                date: DateTime(2026, 4, 23),
                status: AttendanceStatus.LATE,
              ),
            ],
          },
        ),
      );

      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Mark'), findsOneWidget);
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Bob Williams'), findsOneWidget);
      expect(find.text('Diana Keller'), findsOneWidget);
    },
  );

  testWidgets(
    'Attendance overview page shows group status and separate mark button',
    (tester) async {
      await pumpDesktopPage(
        tester,
        child: const AttendanceOverviewPage(),
        adminService: _FakeAdminService(
          groups: [group10A],
          studentsByGroup: {1: students10A},
          accessibleStudents: students10A,
        ),
        scheduleService: _FakeScheduleService(
          schedulesByGroup: {1: [schedule10A]},
        ),
        attendanceService: _FakeAttendanceService(
          scheduleAttendanceById: {
            1: [
              Attendance(
                id: 1,
                studentId: 1,
                studentName: 'Alice Johnson',
                scheduleId: 1,
                subjectName: 'Class #1',
                date: DateTime(2026, 4, 23),
                status: AttendanceStatus.PRESENT,
              ),
              Attendance(
                id: 2,
                studentId: 2,
                studentName: 'Bob Williams',
                scheduleId: 1,
                subjectName: 'Class #1',
                date: DateTime(2026, 4, 23),
                status: AttendanceStatus.LATE,
              ),
            ],
          },
        ),
      );

      expect(find.text('Group partially marked'), findsOneWidget);
      expect(find.text('Mark group'), findsOneWidget);
      expect(find.text('Student'), findsNothing);
      expect(find.text('Alice Johnson'), findsNothing);
    },
  );

  testWidgets(
    'Attendance detail page uses mobile bottom sheet marking flow',
    (tester) async {
      await pumpMobilePage(
        tester,
        child: AttendanceMarkingPage(
          groupId: '1',
          initialScheduleId: 1,
          initialDate: DateTime(2026, 4, 23),
        ),
        adminService: _FakeAdminService(
          groups: [group10A],
          studentsByGroup: {1: students10A},
          accessibleStudents: students10A,
        ),
        scheduleService: _FakeScheduleService(
          schedulesByGroup: {1: [schedule10A]},
        ),
        attendanceService: _FakeAttendanceService(
          scheduleAttendanceById: {
            1: [
              Attendance(
                id: 2,
                studentId: 2,
                studentName: 'Bob Williams',
                scheduleId: 1,
                subjectName: 'Class #1',
                date: DateTime(2026, 4, 23),
                status: AttendanceStatus.LATE,
              ),
            ],
          },
        ),
      );

      expect(find.text('Tap anywhere on this row to change the status.'), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('Alice Johnson'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Alice Johnson'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alice Johnson'));
      await tester.pumpAndSettle();

      expect(find.text('Select attendance status'), findsOneWidget);
      expect(find.text('No saved record for this date yet.'), findsOneWidget);
      expect(find.text('Clear current mark'), findsOneWidget);
    },
  );

  testWidgets('Students page keeps compact desktop table layout', (tester) async {
    await pumpDesktopPage(
      tester,
      child: const StudentsListPage(),
      adminService: _FakeAdminService(
        groups: [group10A],
        studentsByGroup: {1: students10A},
        accessibleStudents: students10A,
      ),
    );

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Group'), findsAtLeastNWidgets(1));
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Alice Johnson'), findsOneWidget);
    expect(find.text('Bob Williams'), findsOneWidget);
    expect(find.text('Diana Keller'), findsOneWidget);
  });

  testWidgets(
    'Reports page marks attendance below 70 percent as failed',
    (tester) async {
      await pumpDesktopPage(
        tester,
        child: const ReportsPage(),
        adminService: _FakeAdminService(
          groups: [group10A],
          studentsByGroup: {1: students10A.take(2).toList()},
          accessibleStudents: students10A.take(2).toList(),
        ),
        attendanceService: _FakeAttendanceService(
          studentAttendanceById: {
            1: [
              Attendance(
                id: 1,
                studentId: 1,
                studentName: 'Alice Johnson',
                scheduleId: 1,
                subjectName: 'Class #1',
                date: DateTime(2026, 4, 23),
                status: AttendanceStatus.PRESENT,
              ),
              Attendance(
                id: 2,
                studentId: 1,
                studentName: 'Alice Johnson',
                scheduleId: 1,
                subjectName: 'Class #1',
                date: DateTime(2026, 4, 22),
                status: AttendanceStatus.ABSENT,
              ),
              Attendance(
                id: 3,
                studentId: 1,
                studentName: 'Alice Johnson',
                scheduleId: 1,
                subjectName: 'Class #1',
                date: DateTime(2026, 4, 21),
                status: AttendanceStatus.ABSENT,
              ),
            ],
            2: [
              Attendance(
                id: 4,
                studentId: 2,
                studentName: 'Bob Williams',
                scheduleId: 1,
                subjectName: 'Class #1',
                date: DateTime(2026, 4, 23),
                status: AttendanceStatus.PRESENT,
              ),
              Attendance(
                id: 5,
                studentId: 2,
                studentName: 'Bob Williams',
                scheduleId: 1,
                subjectName: 'Class #1',
                date: DateTime(2026, 4, 22),
                status: AttendanceStatus.PRESENT,
              ),
            ],
          },
        ),
        gradeService: _FakeGradeService(
          gradesByStudentId: {
            1: [
              Grade(
                id: 1,
                studentId: 1,
                subjectId: 1,
                subjectName: 'Class #1',
                score: 70,
                maxScore: 100,
                date: DateTime(2026, 4, 23),
              ),
            ],
            2: [
              Grade(
                id: 2,
                studentId: 2,
                subjectId: 1,
                subjectName: 'Class #1',
                score: 95,
                maxScore: 100,
                date: DateTime(2026, 4, 23),
              ),
            ],
          },
        ),
      );

      expect(find.text('Failed Students'), findsOneWidget);
      expect(find.text('At-Risk Students'), findsNothing);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Failed'), findsWidgets);
    },
  );

  testWidgets(
    'Attendance detail page warns before leaving with unsaved changes',
    (tester) async {
      await pumpDesktopRouter(
        tester,
        adminService: _FakeAdminService(
          groups: [group10A],
          studentsByGroup: {1: students10A},
          accessibleStudents: students10A,
        ),
        scheduleService: _FakeScheduleService(
          schedulesByGroup: {1: [schedule10A]},
        ),
        attendanceService: _FakeAttendanceService(),
      );

      await tester.tap(find.text('All present'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.text('Leave without saving?'), findsOneWidget);
      expect(find.text('You have unsaved attendance changes. Do you want to leave this page without saving?'), findsOneWidget);

      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();

      expect(find.text('All present'), findsOneWidget);
      expect(find.text('Admin home'), findsNothing);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave without saving'));
      await tester.pumpAndSettle();

      expect(find.text('Admin home'), findsOneWidget);
    },
  );
}

class _FakeAdminService extends AdminService {
  final List<ClassGroup> groups;
  final Map<int, List<Student>> studentsByGroup;
  final List<Student> accessibleStudents;

  _FakeAdminService({
    required this.groups,
    required this.studentsByGroup,
    required this.accessibleStudents,
  }) : super(apiClient: ApiClient());

  @override
  Future<List<ClassGroup>> getClassGroups() async => groups;

  @override
  Future<List<Student>> getStudentsByClass(int classGroupId) async =>
      studentsByGroup[classGroupId] ?? const [];

  @override
  Future<AccessibleStudentsResult> getAccessibleStudents({
    int? classGroupId,
  }) async {
    return AccessibleStudentsResult(
      students: classGroupId == null
          ? accessibleStudents
          : (studentsByGroup[classGroupId] ?? const []),
    );
  }
}

class _FakeScheduleService extends ScheduleService {
  final Map<int, List<Schedule>> schedulesByGroup;

  _FakeScheduleService({required this.schedulesByGroup})
    : super(apiClient: ApiClient());

  @override
  Future<List<Schedule>> getClassSchedule(int classGroupId) async =>
      schedulesByGroup[classGroupId] ?? const [];

  @override
  Future<List<Schedule>> getWeeklySchedule() async =>
      schedulesByGroup.values.expand((items) => items).toList();
}

class _FakeAttendanceService extends AttendanceService {
  final Map<int, List<Attendance>> scheduleAttendanceById;
  final Map<int, List<Attendance>> studentAttendanceById;

  _FakeAttendanceService({
    this.scheduleAttendanceById = const {},
    this.studentAttendanceById = const {},
  }) : super(apiClient: ApiClient());

  @override
  Future<List<Attendance>> getScheduleAttendance({
    required int scheduleId,
    required DateTime date,
  }) async => scheduleAttendanceById[scheduleId] ?? const [];

  @override
  Future<List<Attendance>> getStudentAttendance(int studentId) async =>
      studentAttendanceById[studentId] ?? const [];
}

class _FakeGradeService extends GradeService {
  final Map<int, List<Grade>> gradesByStudentId;

  _FakeGradeService({required this.gradesByStudentId})
    : super(apiClient: ApiClient());

  @override
  Future<List<Grade>> getStudentGrades(int studentId) async =>
      gradesByStudentId[studentId] ?? const [];
}
