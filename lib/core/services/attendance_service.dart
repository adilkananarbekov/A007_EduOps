import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/attendance.dart';
import '../models/student.dart';
import '../utils/remote_id_registry.dart';

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
    final records = await getMyAttendance();
    return records
        .where(
          (record) =>
              !record.date.isBefore(
                DateTime(startDate.year, startDate.month, startDate.day),
              ) &&
              !record.date.isAfter(
                DateTime(endDate.year, endDate.month, endDate.day),
              ),
        )
        .toList();
  }

  /// Get my attendance statistics
  Future<AttendanceStats> getAttendanceStats() async {
    final records = await getMyAttendance();
    final present = records
        .where((record) => record.status == AttendanceStatus.PRESENT)
        .length;
    final absent = records
        .where((record) => record.status == AttendanceStatus.ABSENT)
        .length;
    final late = records
        .where((record) => record.status == AttendanceStatus.LATE)
        .length;
    final excused = records
        .where((record) => record.status == AttendanceStatus.EXCUSED)
        .length;
    final total = records.length;
    return AttendanceStats(
      totalDays: total,
      presentDays: present,
      absentDays: absent,
      lateDays: late,
      excusedDays: excused,
      attendanceRate: total == 0 ? 0 : (present / total) * 100,
    );
  }

  /// Get student attendance (teacher/admin)
  Future<List<Attendance>> getStudentAttendance(int studentId) async {
    final response = await _apiClient.get(
      '/attendance/students/${Uri.encodeComponent(RemoteIdRegistry.remoteId(studentId))}',
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
    final subjectName = RemoteIdRegistry.scheduleSubjectName(scheduleId);
    final responses = await Future.wait(
      records.map((record) async {
        final response = await _apiClient.post(
          ApiConstants.teacherAttendance,
          body: {
            'studentId': RemoteIdRegistry.remoteId(record.studentId),
            'subjectName': subjectName,
            'date': date.toIso8601String().split('T')[0],
            'status': record.status.name.toLowerCase(),
            'notes': record.notes,
          },
        );
        return _withScheduleId(
          Attendance.fromJson(response as Map<String, dynamic>),
          scheduleId,
        );
      }),
    );
    return responses;
  }

  /// Get attendance for a schedule on a specific date
  Future<List<Attendance>> getScheduleAttendance({
    required int scheduleId,
    required DateTime date,
  }) async {
    final className = RemoteIdRegistry.scheduleClassName(scheduleId);
    final subjectName = RemoteIdRegistry.scheduleSubjectName(scheduleId);
    if (className == null || className.isEmpty) {
      return <Attendance>[];
    }

    final studentsResponse = await _apiClient.get(
      '/groups/${Uri.encodeComponent(className)}/students',
    );
    final students = (studentsResponse as List)
        .map((json) => Student.fromJson(json as Map<String, dynamic>))
        .toList();

    final attendanceGroups = await Future.wait(
      students.map((student) async {
        try {
          return await getStudentAttendance(student.id);
        } catch (_) {
          return <Attendance>[];
        }
      }),
    );

    final requestedDate = DateTime(date.year, date.month, date.day);
    return attendanceGroups
        .expand((records) => records)
        .where(
          (record) =>
              _sameDate(record.date, requestedDate) &&
              (subjectName == null ||
                  record.subjectName == null ||
                  record.subjectName == subjectName),
        )
        .map((record) => _withScheduleId(record, scheduleId))
        .toList();
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Attendance _withScheduleId(Attendance attendance, int scheduleId) {
    return Attendance(
      id: attendance.id,
      studentId: attendance.studentId,
      studentName: attendance.studentName,
      scheduleId: scheduleId,
      subjectName: attendance.subjectName,
      date: attendance.date,
      status: attendance.status,
      notes: attendance.notes,
      markedByName: attendance.markedByName,
      markedAt: attendance.markedAt,
    );
  }
}
