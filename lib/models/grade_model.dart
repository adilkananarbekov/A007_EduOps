import 'package:cloud_firestore/cloud_firestore.dart';

class GradeModel {
  final String id;
  final String studentId;
  final String teacherId;
  final String subjectName;
  final double value;
  final double maxValue;
  final String type;
  final String? description;
  final DateTime date;

  GradeModel({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.subjectName,
    required this.value,
    required this.maxValue,
    required this.type,
    this.description,
    required this.date,
  });

  factory GradeModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GradeModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      teacherId: data['teacherId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      value: (data['value'] as num?)?.toDouble() ?? 0.0,
      maxValue: (data['maxValue'] as num?)?.toDouble() ?? 100.0,
      type: data['type'] ?? 'UNKNOWN',
      description: data['description'],
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'teacherId': teacherId,
      'subjectName': subjectName,
      'value': value,
      'maxValue': maxValue,
      'type': type,
      'description': description,
      'date': Timestamp.fromDate(date),
    };
  }
}
