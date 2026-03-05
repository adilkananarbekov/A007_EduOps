import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/schedule.dart';

/// Service for schedule-related operations
class ScheduleService {
  final ApiClient _apiClient;

  ScheduleService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get my weekly schedule
  Future<List<Schedule>> getWeeklySchedule() async {
    final response = await _apiClient.get(ApiConstants.scheduleWeek);
    return (response as List)
        .map((json) => Schedule.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get class schedule
  Future<List<Schedule>> getClassSchedule(int classGroupId) async {
    final response = await _apiClient.get(
      ApiConstants.scheduleByClass(classGroupId),
    );
    return (response as List)
        .map((json) => Schedule.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get teacher schedule
  Future<List<Schedule>> getTeacherSchedule(int teacherId) async {
    final response = await _apiClient.get(
      ApiConstants.scheduleByTeacher(teacherId),
    );
    return (response as List)
        .map((json) => Schedule.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create schedule (admin)
  Future<Schedule> createSchedule({
    required int classGroupId,
    required int subjectId,
    required int teacherId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.schedule,
      body: {
        'studentGroupId': classGroupId,
        'classId': subjectId,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'room': room,
      },
    );
    return Schedule.fromJson(response as Map<String, dynamic>);
  }

  /// Generate schedule (admin)
  Future<List<Schedule>> generateSchedule() async {
    final response = await _apiClient.post(ApiConstants.scheduleGenerate);
    return (response as List)
        .map((json) => Schedule.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Delete schedule (admin)
  Future<void> deleteSchedule(int id) async {
    await _apiClient.delete(ApiConstants.scheduleById(id));
  }
}
