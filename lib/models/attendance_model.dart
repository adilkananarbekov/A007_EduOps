import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String studentId;
  final String? subjectName;
  final DateTime date;
  final String status;
  final String? notes;

  AttendanceModel({
    required this.id,
    required this.studentId,
    this.subjectName,
    required this.date,
    required this.status,
    this.notes,
  });

  factory AttendanceModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      subjectName: data['subjectName'],
      date: (data['date'] as Timestamp).toDate(),
      status: data['status'] ?? 'PRESENT',
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'subjectName': subjectName,
      'date': Timestamp.fromDate(date),
      'status': status,
      'notes': notes,
    };
  }
}
