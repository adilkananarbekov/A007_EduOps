import 'package:flutter/foundation.dart';

/// API constants for EduOps backend integration
class ApiConstants {
  static const String cloudBackendUrl = 'https://adilkan.com';
  static const String localBackendUrl = 'http://localhost:8080';
  static const String androidEmulatorBackendUrl = 'http://10.0.2.2:8080';
  static String? _runtimeBaseUrlOverride;

  static String get baseUrl {
    final runtimeBaseUrlOverride = _runtimeBaseUrlOverride;
    if (runtimeBaseUrlOverride != null && runtimeBaseUrlOverride.isNotEmpty) {
      return runtimeBaseUrlOverride;
    }

    const configuredApiBaseUrl = String.fromEnvironment('EDUOPS_API_BASE_URL');
    if (configuredApiBaseUrl.isNotEmpty) {
      return _trimTrailingSlash(configuredApiBaseUrl);
    }

    const configuredBaseUrl = String.fromEnvironment('EDUOPS_BASE_URL');
    if (configuredBaseUrl.isNotEmpty) {
      return _trimTrailingSlash(configuredBaseUrl);
    }

    return _defaultBaseUrl;
  }

  static String get apiPrefix {
    const configuredApiBaseUrl = String.fromEnvironment('EDUOPS_API_BASE_URL');
    if (configuredApiBaseUrl.isNotEmpty) {
      return '';
    }

    const configuredApiPrefix = String.fromEnvironment('EDUOPS_API_PREFIX');
    if (configuredApiPrefix.isNotEmpty) {
      return _normalizeApiPrefix(configuredApiPrefix);
    }

    return '/api/eduprog';
  }

  static String get baseApiUrl => '$baseUrl$apiPrefix';

  // Timeout configuration
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration remoteAuthTimeout = Duration(seconds: 40);

  // Authentication endpoints
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String register = '/auth/register';
  static const String registerInitial = register;

  // Admin endpoints
  static const String users = '/users';
  static const String students = '/users';
  static const String studentsUnassigned = '/users';
  static String studentsByClass(int classGroupId) =>
      '/groups/${Uri.encodeComponent(classGroupId.toString())}/students';
  static String updateStudentClass(int studentId) => '/users/$studentId';
  static const String studentsBulkAssign = '/users';
  static const String teachers = '/users';
  static String updateTeacherSubjects(int teacherId) => '/users/$teacherId';
  static const String classGroups = '/groups';
  static const String adminClassGroups = '/management/groups';
  static String classGroup(int id) => '/management/groups/$id';
  static const String subjects = '/subjects';

  // Announcement endpoints
  static const String announcements = '/notifications/me';
  static const String announcementsAll = '/notifications/me';
  static const String announcementsAdmin = '/notifications';
  static String announcementById(int id) => '/notifications/$id/read';

  // Attendance endpoints
  static const String attendance = '/attendance/me';
  static const String teacherAttendance = '/attendance';
  static const String attendanceRange = '/attendance/me';
  static const String attendanceStats = '/attendance/me';
  static String attendanceByStudent(int studentId) =>
      '/attendance/students/$studentId';
  static String attendanceBySchedule(int scheduleId) =>
      '/attendance/schedule/$scheduleId';

  // Grade endpoints
  static const String grades = '/grades/me';
  static const String teacherGrades = '/grades';
  static String gradesBySubject(int subjectId) => '/grades/me';
  static const String gradesAverages = '/grades/me';
  static String gradesByStudent(int studentId) => '/grades/students/$studentId';
  static String gradeById(int id) => '/grades/$id';

  // Schedule endpoints
  static const String scheduleWeek = '/schedule/me';
  static String scheduleByClass(int classGroupId) =>
      '/schedule/classes/${Uri.encodeComponent(classGroupId.toString())}';
  static String scheduleByTeacher(int teacherId) =>
      '/schedule/teachers/$teacherId';
  static const String schedule = '/management/schedule';
  static const String scheduleGenerate = '/management/schedule';
  static String scheduleById(int id) => '/management/schedule/$id';

  // Headers
  static const String authorizationHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String contentTypeJson = 'application/json';

  // Token prefix
  static const String bearerPrefix = 'Bearer ';

  static void setRuntimeBaseUrlOverride(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      _runtimeBaseUrlOverride = null;
      return;
    }
    _runtimeBaseUrlOverride = _trimTrailingSlash(trimmed);
  }

  static void clearRuntimeBaseUrlOverride() {
    _runtimeBaseUrlOverride = null;
  }

  static String get _defaultBaseUrl {
    if (kIsWeb) {
      return localBackendUrl;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidEmulatorBackendUrl;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return localBackendUrl;
    }
  }

  static String _trimTrailingSlash(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }

  static String _normalizeApiPrefix(String value) {
    final trimmed = _trimTrailingSlash(value);
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }
}
