import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  final String id;
  final String className;
  final String teacherId;
  final String teacherName;
  final String subjectName;
  final String? subjectShortName;
  final String room;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final int lessonNumber;

  ScheduleModel({
    required this.id,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    required this.subjectName,
    this.subjectShortName,
    required this.room,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.lessonNumber,
  });

  factory ScheduleModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduleModel(
      id: doc.id,
      className: data['className'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      subjectName: data['subjectName'] ?? '',
      subjectShortName: data['subjectShortName'],
      room: data['room'] ?? '',
      dayOfWeek: data['dayOfWeek'] ?? 1,
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      lessonNumber: data['lessonNumber'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'subjectName': subjectName,
      'subjectShortName': subjectShortName,
      'room': room,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'lessonNumber': lessonNumber,
    };
  }
}
