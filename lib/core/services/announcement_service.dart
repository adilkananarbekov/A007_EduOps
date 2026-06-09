import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/announcement.dart';
import '../utils/remote_id_registry.dart';

/// Service for announcement-related operations
class AnnouncementService {
  final ApiClient _apiClient;

  AnnouncementService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get my announcements
  Future<List<Announcement>> getMyAnnouncements() async {
    final response = await _apiClient.get(ApiConstants.announcements);
    return (response as List)
        .map((json) => Announcement.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get all announcements (admin)
  Future<List<Announcement>> getAllAnnouncements() async {
    final response = await _apiClient.get(ApiConstants.announcementsAll);
    return (response as List)
        .map((json) => Announcement.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create announcement (teacher/admin)
  Future<Announcement> createAnnouncement({
    required String title,
    required String content,
    int? classGroupId,
    bool isGlobal = false,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.announcementsAdmin,
      body: {
        'title': title,
        'body': content,
        'category': 'announcement',
        'className': isGlobal || classGroupId == null
            ? null
            : RemoteIdRegistry.groupName(classGroupId),
      },
    );
    final responseJson = response is Map<String, dynamic>
        ? response
        : <String, dynamic>{};
    return Announcement.fromJson({
      'id': responseJson['id'] ?? DateTime.now().microsecondsSinceEpoch,
      'title': title,
      'body': content,
      'category': 'announcement',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'className': classGroupId == null
          ? null
          : RemoteIdRegistry.groupName(classGroupId),
    });
  }

  /// Delete announcement (teacher/admin)
  Future<void> deleteAnnouncement(int id) async {
    await _apiClient.post(
      '/notifications/${Uri.encodeComponent(RemoteIdRegistry.remoteId(id))}/read',
    );
  }
}
