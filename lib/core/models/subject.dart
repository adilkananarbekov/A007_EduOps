import '../utils/remote_id_registry.dart';

/// Subject model
class Subject {
  final int id;
  final String name;
  final String? code;
  final String? description;

  Subject({required this.id, required this.name, this.code, this.description});

  factory Subject.fromJson(Map<String, dynamic> json) {
    final id = RemoteIdRegistry.localId(json['id'], namespace: 'subject');
    final name = json['name'] as String? ?? 'Subject #$id';
    RemoteIdRegistry.registerSubjectName(id, name);
    return Subject(
      id: id,
      name: name,
      code: json['code'] as String? ?? json['shortName'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code, 'description': description};
  }
}
