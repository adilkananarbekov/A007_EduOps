import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/attendance.dart';

/// Service for attendance-related operations
class AttendanceService {
  final ApiClient _apiClient;

  AttendanceService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get my attendance records
  Future<List<Attendance>> getMyAttendance() async {
    final response = await _apiClient.get(ApiConstants.attendance);
    return (response as List)
        .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get attendance by date range
  Future<List<Attendance>> getAttendanceByRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.attendanceRange,
      queryParams: {
        'startDate': startDate.toIso8601String().split('T')[0],
        'endDate': endDate.toIso8601String().split('T')[0],
      },
    );
    return (response as List)
        .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get my attendance statistics
  Future<AttendanceStats> getAttendanceStats() async {
    final response = await _apiClient.get(ApiConstants.attendanceStats);
    return AttendanceStats.fromJson(response as Map<String, dynamic>);
  }

  /// Get student attendance (teacher/admin)
  Future<List<Attendance>> getStudentAttendance(int studentId) async {
    final response = await _apiClient.get(
      ApiConstants.attendanceByStudent(studentId),
    );
    return (response as List)
        .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Mark attendance (teacher/admin)
  Future<Attendance> markAttendance({
    required int studentId,
    required int scheduleId,
    required DateTime date,
    required AttendanceStatus status,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.attendance,
      body: {
        'studentId': studentId,
        'scheduleId': scheduleId,
        'date': date.toIso8601String().split('T')[0],
        'status': status.name,
        'notes': notes,
      },
    );
    return Attendance.fromJson(response as Map<String, dynamic>);
  }

  /// Get attendance for a schedule on a specific date
  Future<List<Attendance>> getScheduleAttendance({
    required int scheduleId,
    required DateTime date,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.attendanceBySchedule(scheduleId),
      queryParams: {'date': date.toIso8601String().split('T')[0]},
    );
    return (response as List)
        .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
