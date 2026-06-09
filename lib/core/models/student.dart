import '../utils/remote_id_registry.dart';

/// Student model
class Student {
  final int id;
  final int? userId;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? address;
  final DateTime? dateOfBirth;
  final int? classGroupId;
  final String? classGroupName;
  final String? studentNumber;
  final String? accountNumber;
  final String? parentEmail;
  final String? parentPhone;

  Student({
    required this.id,
    this.userId,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.address,
    this.dateOfBirth,
    this.classGroupId,
    this.classGroupName,
    this.studentNumber,
    this.accountNumber,
    this.parentEmail,
    this.parentPhone,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic value, {String namespace = 'default'}) {
      if (value == null) {
        return null;
      }
      return RemoteIdRegistry.localId(value, namespace: namespace);
    }

    final name =
        json['name'] as String? ??
        json['fullName'] as String? ??
        json['full_name'] as String? ??
        '${json['firstName'] ?? json['first_name'] ?? ''} ${json['lastName'] ?? json['last_name'] ?? ''}'
            .trim();

    final groupId =
        asInt(json['classGroupId']) ??
        asInt(json['class_group_id']) ??
        asInt(json['studentGroupId']) ??
        asInt(json['student_group_id']) ??
        _classGroupIdFromName(json['className'] ?? json['class_group_name']);

    final classGroupName =
        json['classGroupName'] as String? ??
        json['class_group_name'] as String? ??
        json['studentGroupName'] as String? ??
        json['student_group_name'] as String? ??
        json['className'] as String?;
    if (groupId != null && classGroupName != null) {
      RemoteIdRegistry.registerGroupName(groupId, classGroupName);
    }

    return Student(
      id: asInt(json['id'], namespace: 'user') ?? 0,
      userId:
          asInt(json['userId'], namespace: 'user') ??
          asInt(json['user_id'], namespace: 'user') ??
          asInt(json['id'], namespace: 'user'),
      name: name.isNotEmpty ? name : 'Unknown',
      email: json['email'] as String? ?? '',
      phoneNumber:
          json['phoneNumber'] as String? ?? json['phone_number'] as String?,
      address: json['address'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      classGroupId: groupId,
      classGroupName: classGroupName,
      studentNumber:
          json['studentNumber'] as String? ?? json['student_number'] as String?,
      accountNumber:
          json['accountNumber'] as String? ?? json['account_number'] as String?,
      parentEmail: json['parentEmail'] as String?,
      parentPhone:
          json['parentPhone'] as String? ?? json['parent_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'classGroupId': classGroupId,
      'classGroupName': classGroupName,
      'studentNumber': studentNumber,
      'accountNumber': accountNumber,
      'parentEmail': parentEmail,
      'parentPhone': parentPhone,
    };
  }

  /// Alias for backward compatibility
  String get fullName => name;

  /// First word of name
  String get firstName => name.split(' ').first;

  /// Remaining words after first name
  String get lastName => name.split(' ').skip(1).join(' ');

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
