import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/grade.dart';
import '../utils/remote_id_registry.dart';

/// Service for grade-related operations
class GradeService {
  final ApiClient _apiClient;

  GradeService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get my grades
  Future<List<Grade>> getMyGrades() async {
    final response = await _apiClient.get(ApiConstants.grades);
    return (response as List)
        .map((json) => Grade.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get my grades by subject
  Future<List<Grade>> getGradesBySubject(int subjectId) async {
    final grades = await getMyGrades();
    final subjectName = RemoteIdRegistry.subjectName(subjectId);
    return grades
        .where(
          (grade) =>
              grade.subjectId == subjectId ||
              (subjectName != null && grade.subjectName == subjectName),
        )
        .toList();
  }

  /// Get my grade averages
  Future<GradeAverages> getGradeAverages() async {
    final grades = await getMyGrades();
    if (grades.isEmpty) {
      return GradeAverages(overallAverage: 0, subjectAverages: const {});
    }

    final subjectScores = <String, List<double>>{};
    for (final grade in grades) {
      subjectScores
          .putIfAbsent(grade.subjectName, () => <double>[])
          .add(grade.percentage);
    }

    final subjectAverages = subjectScores.map((subject, scores) {
      final total = scores.fold<double>(0, (sum, score) => sum + score);
      return MapEntry(subject, total / scores.length);
    });
    final overall =
        grades.fold<double>(0, (sum, grade) => sum + grade.percentage) /
        grades.length;
    return GradeAverages(
      overallAverage: overall,
      subjectAverages: subjectAverages,
    );
  }

  /// Get student grades (teacher/admin)
  Future<List<Grade>> getStudentGrades(int studentId) async {
    final response = await _apiClient.get(
      '/grades/students/${Uri.encodeComponent(RemoteIdRegistry.remoteId(studentId))}',
    );
    return (response as List)
        .map((json) => Grade.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create grade (teacher/admin)
  Future<Grade> createGrade({
    required int studentId,
    required int subjectId,
    required double score,
    required double maxScore,
    String? gradeType,
    required DateTime date,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.teacherGrades,
      body: {
        'studentId': RemoteIdRegistry.remoteId(studentId),
        'subjectName':
            RemoteIdRegistry.subjectName(subjectId) ?? 'Subject #$subjectId',
        'value': score,
        'maxValue': maxScore,
        'type': gradeType ?? 'UNKNOWN',
        'date': date.toUtc().toIso8601String(),
        'description': notes,
      },
    );
    return Grade.fromJson(response as Map<String, dynamic>);
  }

  /// Delete grade (teacher/admin)
  Future<void> deleteGrade(int id) async {
    throw UnsupportedError(
      'Deleting grades is not exposed by this backend API.',
    );
  }
}
