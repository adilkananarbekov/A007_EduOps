import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, teacher, admin, unknown }

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? className;
  final bool enabled;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.className,
    this.enabled = true,
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      role: _parseRole(data['role']),
      className: data['className'],
      enabled: data['enabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role.name.toUpperCase(),
      'className': className,
      'enabled': enabled,
    };
  }

  static UserRole _parseRole(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'TEACHER':
        return UserRole.teacher;
      case 'STUDENT':
        return UserRole.student;
      default:
        return UserRole.unknown;
    }
  }
}
