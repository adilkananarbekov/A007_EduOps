import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/schedule_model.dart';
import '../models/grade_model.dart';
import '../models/attendance_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- User ---
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- Schedule ---
  Stream<List<ScheduleModel>> getSchedulesForClass(String className) {
    return _db
        .collection('schedules')
        .where('className', isEqualTo: className)
        .orderBy('dayOfWeek')
        .orderBy('lessonNumber')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ScheduleModel.fromDocument(doc))
              .toList(),
        );
  }

  Stream<List<ScheduleModel>> getSchedulesForTeacher(String teacherId) {
    return _db
        .collection('schedules')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('dayOfWeek')
        .orderBy('lessonNumber')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ScheduleModel.fromDocument(doc))
              .toList(),
        );
  }

  // --- Grades ---
  Stream<List<GradeModel>> getGradesForStudent(String studentId) {
    return _db
        .collection('grades')
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => GradeModel.fromDocument(doc)).toList(),
        );
  }

  Future<void> addGrade(GradeModel grade) async {
    await _db.collection('grades').add(grade.toMap());
  }

  // --- Attendance ---
  Stream<List<AttendanceModel>> getAttendanceForStudent(String studentId) {
    return _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AttendanceModel.fromDocument(doc))
              .toList(),
        );
  }

  Future<void> markAttendance(AttendanceModel attendance) async {
    await _db.collection('attendance').add(attendance.toMap());
  }
}
