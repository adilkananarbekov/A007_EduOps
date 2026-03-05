import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/attendance.dart';

class AttendanceMarkingRecord {
  final int studentId;
  final AttendanceStatus status;
  final String? notes;

  const AttendanceMarkingRecord({
    required this.studentId,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {'studentId': studentId, 'status': status.name, 'notes': notes};
  }
}

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
  Future<List<Attendance>> markAttendance({
    required int scheduleId,
    required DateTime date,
    required List<AttendanceMarkingRecord> records,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.teacherAttendance,
      body: {
        'scheduleId': scheduleId,
        'date': date.toIso8601String().split('T')[0],
        'attendanceRecords': records.map((record) => record.toJson()).toList(),
      },
    );
    return (response as List)
        .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
        .toList();
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
