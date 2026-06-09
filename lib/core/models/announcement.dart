import '../utils/remote_id_registry.dart';

/// Announcement model
class Announcement {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;
  final int authorId;
  final String? authorName;
  final int? classGroupId;
  final String? classGroupName;
  final bool isGlobal;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.authorId,
    this.authorName,
    this.classGroupId,
    this.classGroupName,
    required this.isGlobal,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic value, {String namespace = 'default'}) {
      if (value == null) {
        return null;
      }
      return RemoteIdRegistry.localId(value, namespace: namespace);
    }

    final targetGroupId =
        asInt(json['classGroupId'], namespace: 'group') ??
        asInt(json['targetStudentGroupId'], namespace: 'group') ??
        _classGroupIdFromName(json['className']);

    return Announcement(
      id: asInt(json['id'], namespace: 'notification') ?? 0,
      title: json['title'] as String,
      content:
          json['content'] as String? ??
          json['body'] as String? ??
          json['description'] as String? ??
          '',
      createdAt: DateTime.parse(
        json['createdAt'] as String? ??
            json['created_at'] as String? ??
            DateTime.now().toIso8601String(),
      ),
      authorId: asInt(json['authorId'], namespace: 'user') ?? 0,
      authorName: json['authorName'] as String? ?? json['category'] as String?,
      classGroupId: targetGroupId,
      classGroupName:
          json['classGroupName'] as String? ??
          json['targetStudentGroupName'] as String?,
      isGlobal:
          json['isGlobal'] as bool? ??
          (targetGroupId == null &&
              (json['targetRole'] == null ||
                  (json['targetRole'] as String).trim().isEmpty)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'authorId': authorId,
      'authorName': authorName,
      'classGroupId': classGroupId,
      'classGroupName': classGroupName,
      'isGlobal': isGlobal,
    };
  }

  static int? _classGroupIdFromName(dynamic value) {
    final className = value?.toString().trim();
    if (className == null || className.isEmpty) {
      return null;
    }
    final id = RemoteIdRegistry.localId(className, namespace: 'group_name');
    RemoteIdRegistry.registerGroupName(id, className);
    return id;
  }
}
