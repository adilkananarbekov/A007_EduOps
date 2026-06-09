import '../utils/remote_id_registry.dart';

/// Class group (class) model
class ClassGroup {
  final int id;
  final String name;
  final int? grade;
  final int? monthlyFee;
  final int? studentCount;

  ClassGroup({
    required this.id,
    required this.name,
    this.grade,
    this.monthlyFee,
    this.studentCount,
  });

  factory ClassGroup.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic value) => value == null
        ? null
        : RemoteIdRegistry.localId(value, namespace: 'group');

    final students = json['students'];
    final id =
        asInt(json['id']) ??
        RemoteIdRegistry.localId(json['name'], namespace: 'group_name');
    final name = json['name'] as String;
    RemoteIdRegistry.registerGroupName(id, name);

    return ClassGroup(
      id: id,
      name: name,
      grade: asInt(json['grade']) ?? asInt(json['year']),
      monthlyFee: json['monthlyFee'] as int?,
      studentCount:
          asInt(json['studentCount']) ??
          asInt(json['student_count']) ??
          (students is List ? students.length : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'monthlyFee': monthlyFee,
      'studentCount': studentCount,
    };
  }
}
