import '../api/api_client.dart';

class LearningService {
  final ApiClient _apiClient;

  LearningService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _apiClient.get('/dashboard/me');
    return response is Map<String, dynamic> ? response : <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> getLessons() async {
    return _getList('/lessons/me');
  }

  Future<List<Map<String, dynamic>>> getAssignments() async {
    return _getList('/assignments/me');
  }

  Future<List<Map<String, dynamic>>> getTests() async {
    return _getList('/tests/me');
  }

  Future<List<Map<String, dynamic>>> getGradeWeights() async {
    return _getList('/grade-weights/me');
  }

  Future<List<Map<String, dynamic>>> _getList(String endpoint) async {
    final response = await _apiClient.get(endpoint);
    if (response is! List) {
      return <Map<String, dynamic>>[];
    }
    return response
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();
  }
}
