import 'user_role.dart';

/// Authentication response from login endpoint
class AuthResponse {
  final String token;
  final String type;
  final int userId;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final int? profileId;
  final int? classGroupId;

  AuthResponse({
    required this.token,
    required this.type,
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.profileId,
    this.classGroupId,
  });

  /// Create AuthResponse from JSON
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      type: json['type'] as String? ?? 'Bearer',
      userId: json['userId'] as int,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: UserRole.fromString(json['role'] as String),
      profileId: json['profileId'] as int?,
      classGroupId: json['classGroupId'] as int?,
    );
  }

  /// Convert AuthResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'type': type,
      'userId': userId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role.name,
      'profileId': profileId,
      'classGroupId': classGroupId,
    };
  }

  /// Get full name
  String get fullName => '$firstName $lastName';

  /// Copy with optional parameter changes
  AuthResponse copyWith({
    String? token,
    String? type,
    int? userId,
    String? email,
    String? firstName,
    String? lastName,
    UserRole? role,
    int? profileId,
    int? classGroupId,
  }) {
    return AuthResponse(
      token: token ?? this.token,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      profileId: profileId ?? this.profileId,
      classGroupId: classGroupId ?? this.classGroupId,
    );
  }
}
