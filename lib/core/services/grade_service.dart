import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/grade.dart';

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
    final response = await _apiClient.get(
      ApiConstants.gradesBySubject(subjectId),
    );
    return (response as List)
        .map((json) => Grade.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get my grade averages
  Future<GradeAverages> getGradeAverages() async {
    final response = await _apiClient.get(ApiConstants.gradesAverages);
    return GradeAverages.fromJson(response as Map<String, dynamic>);
  }

  /// Get student grades (teacher/admin)
  Future<List<Grade>> getStudentGrades(int studentId) async {
    final response = await _apiClient.get(
      ApiConstants.gradesByStudent(studentId),
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
      ApiConstants.grades,
      body: {
        'studentId': studentId,
        'subjectId': subjectId,
        'score': score,
        'maxScore': maxScore,
        'gradeType': gradeType,
        'date': date.toIso8601String().split('T')[0],
        'notes': notes,
      },
    );
    return Grade.fromJson(response as Map<String, dynamic>);
  }

  /// Delete grade (teacher/admin)
  Future<void> deleteGrade(int id) async {
    await _apiClient.delete(ApiConstants.gradeById(id));
  }
}
