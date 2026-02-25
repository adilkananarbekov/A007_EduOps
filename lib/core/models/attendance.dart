/// Attendance status enumeration
enum AttendanceStatus {
  PRESENT,
  ABSENT,
  LATE,
  EXCUSED;

  static AttendanceStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return AttendanceStatus.PRESENT;
      case 'ABSENT':
        return AttendanceStatus.ABSENT;
      case 'LATE':
        return AttendanceStatus.LATE;
      case 'EXCUSED':
        return AttendanceStatus.EXCUSED;
      default:
        throw ArgumentError('Invalid attendance status: $status');
    }
  }

  String get displayName {
    switch (this) {
      case AttendanceStatus.PRESENT:
        return 'Present';
      case AttendanceStatus.ABSENT:
        return 'Absent';
      case AttendanceStatus.LATE:
        return 'Late';
      case AttendanceStatus.EXCUSED:
        return 'Excused';
    }
  }
}

/// Attendance record model
class Attendance {
  final int id;
  final int studentId;
  final String? studentName;
  final int scheduleId;
  final String? subjectName;
  final DateTime date;
  final AttendanceStatus status;
  final String? notes;

  Attendance({
    required this.id,
    required this.studentId,
    this.studentName,
    required this.scheduleId,
    this.subjectName,
    required this.date,
    required this.status,
    this.notes,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as int,
      studentId: json['studentId'] as int,
      studentName: json['studentName'] as String?,
      scheduleId: json['scheduleId'] as int,
      subjectName: json['subjectName'] as String?,
      date: DateTime.parse(json['date'] as String),
      status: AttendanceStatus.fromString(json['status'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'scheduleId': scheduleId,
      'subjectName': subjectName,
      'date': date.toIso8601String(),
      'status': status.name,
      'notes': notes,
    };
  }
}

/// Attendance statistics model
class AttendanceStats {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int excusedDays;
  final double attendanceRate;

  AttendanceStats({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.excusedDays,
    required this.attendanceRate,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    return AttendanceStats(
      totalDays: json['totalDays'] as int,
      presentDays: json['presentDays'] as int,
      absentDays: json['absentDays'] as int,
      lateDays: json['lateDays'] as int,
      excusedDays: json['excusedDays'] as int,
      attendanceRate: (json['attendanceRate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDays': totalDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'lateDays': lateDays,
      'excusedDays': excusedDays,
      'attendanceRate': attendanceRate,
    };
  }
}
