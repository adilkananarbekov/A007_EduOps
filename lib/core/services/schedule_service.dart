import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/schedule.dart';
import '../utils/remote_id_registry.dart';

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
    final className =
        RemoteIdRegistry.groupName(classGroupId) ??
        RemoteIdRegistry.remoteId(classGroupId);
    final response = await _apiClient.get(
      '/schedule/classes/${Uri.encodeComponent(className)}',
    );
    return (response as List)
        .map((json) => Schedule.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get teacher schedule
  Future<List<Schedule>> getTeacherSchedule(int teacherId) async {
    final response = await _apiClient.get(
      '/schedule/teachers/${Uri.encodeComponent(RemoteIdRegistry.remoteId(teacherId))}',
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
        'className':
            RemoteIdRegistry.groupName(classGroupId) ??
            RemoteIdRegistry.remoteId(classGroupId),
        'subjectName':
            RemoteIdRegistry.subjectName(subjectId) ?? 'Subject #$subjectId',
        'teacherId': RemoteIdRegistry.remoteId(teacherId),
        'dayOfWeek': _dayNumber(dayOfWeek),
        'lessonNumber': 1,
        'startTime': startTime,
        'endTime': endTime,
        'room': room ?? '',
      },
    );
    return Schedule.fromJson(response as Map<String, dynamic>);
  }

  /// Generate schedule (admin)
  Future<List<Schedule>> generateSchedule() async {
    return getWeeklySchedule();
  }

  /// Delete schedule (admin)
  Future<void> deleteSchedule(int id) async {
    await _apiClient.delete(
      '/management/schedule/${Uri.encodeComponent(RemoteIdRegistry.remoteId(id))}',
    );
  }

  int _dayNumber(String dayOfWeek) {
    switch (dayOfWeek.trim().toUpperCase()) {
      case 'MONDAY':
        return 1;
      case 'TUESDAY':
        return 2;
      case 'WEDNESDAY':
        return 3;
      case 'THURSDAY':
        return 4;
      case 'FRIDAY':
        return 5;
      case 'SATURDAY':
        return 6;
      case 'SUNDAY':
        return 7;
      default:
        return int.tryParse(dayOfWeek) ?? 1;
    }
  }
}
