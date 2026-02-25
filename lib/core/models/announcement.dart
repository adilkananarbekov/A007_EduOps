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
    return Announcement(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      authorId: json['authorId'] as int,
      authorName: json['authorName'] as String?,
      classGroupId: json['classGroupId'] as int?,
      classGroupName: json['classGroupName'] as String?,
      isGlobal: json['isGlobal'] as bool? ?? false,
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
}
