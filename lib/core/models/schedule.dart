import '../utils/remote_id_registry.dart';

/// Schedule model
class Schedule {
  final int id;
  final int classGroupId;
  final String? classGroupName;
  final int subjectId;
  final String subjectName;
  final int teacherId;
  final String? teacherName;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;

  Schedule({
    required this.id,
    required this.classGroupId,
    this.classGroupName,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    this.teacherName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value, {int fallback = 0, String namespace = 'default'}) {
      if (value == null) {
        return fallback;
      }
      return RemoteIdRegistry.localId(value, namespace: namespace);
    }

    // Helper to convert LocalTime object or string to HH:mm string
    String parseTime(dynamic timeValue) {
      if (timeValue == null) return '00:00';
      if (timeValue is String) return timeValue;
      if (timeValue is Map<String, dynamic>) {
        final hour = (timeValue['hour'] as int?) ?? 0;
        final minute = (timeValue['minute'] as int?) ?? 0;
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }
      return '00:00';
    }

    final id = asInt(json['id'], namespace: 'schedule');
    final classGroupName =
        json['classGroupName'] as String? ??
        json['studentGroupName'] as String? ??
        json['className'] as String?;
    final classGroupId =
        asInt(
              json['classGroupId'] ?? json['studentGroupId'],
              namespace: 'group',
            ) !=
            0
        ? asInt(
            json['classGroupId'] ?? json['studentGroupId'],
            namespace: 'group',
          )
        : RemoteIdRegistry.localId(classGroupName, namespace: 'group_name');
    final subjectName =
        json['subjectName'] as String? ??
        json['className'] as String? ??
        'Subject';
    final subjectId =
        asInt(json['subjectId'] ?? json['classId'], namespace: 'subject') != 0
        ? asInt(json['subjectId'] ?? json['classId'], namespace: 'subject')
        : RemoteIdRegistry.localId(subjectName, namespace: 'subject_name');
    RemoteIdRegistry.registerScheduleMeta(
      id,
      className: classGroupName,
      subjectName: subjectName,
    );
    RemoteIdRegistry.registerGroupName(classGroupId, classGroupName ?? '');
    RemoteIdRegistry.registerSubjectName(subjectId, subjectName);

    return Schedule(
      id: id,
      classGroupId: classGroupId,
      classGroupName: classGroupName,
      subjectId: subjectId,
      subjectName: subjectName,
      teacherId: asInt(json['teacherId'], namespace: 'user'),
      teacherName: json['teacherName'] as String?,
      dayOfWeek: _parseDayOfWeek(json['dayOfWeek']),
      startTime: parseTime(json['startTime']),
      endTime: parseTime(json['endTime']),
      room: json['room'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classGroupId': classGroupId,
      'classGroupName': classGroupName,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
    };
  }

  static String _parseDayOfWeek(dynamic value) {
    if (value is num) {
      const days = [
        'MONDAY',
        'TUESDAY',
        'WEDNESDAY',
        'THURSDAY',
        'FRIDAY',
        'SATURDAY',
        'SUNDAY',
      ];
      final index = value.toInt() - 1;
      return index >= 0 && index < days.length ? days[index] : 'MONDAY';
    }

    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return 'MONDAY';
    }

    final numeric = int.tryParse(raw);
    if (numeric != null) {
      return _parseDayOfWeek(numeric);
    }

    return raw.toUpperCase();
  }
}
