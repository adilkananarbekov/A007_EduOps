/// User role enumeration matching backend roles
enum UserRole {
  STUDENT,
  TEACHER,
  ADMIN,
  ACCOUNTANT;

  /// Convert string to UserRole
  static UserRole fromString(String role) {
    switch (role.toUpperCase()) {
      case 'STUDENT':
        return UserRole.STUDENT;
      case 'TEACHER':
        return UserRole.TEACHER;
      case 'ADMIN':
        return UserRole.ADMIN;
      case 'ACCOUNTANT':
        return UserRole.ACCOUNTANT;
      default:
        throw ArgumentError('Invalid role: $role');
    }
  }

  /// Get display name for role
  String get displayName {
    switch (this) {
      case UserRole.STUDENT:
        return 'Student';
      case UserRole.TEACHER:
        return 'Teacher';
      case UserRole.ADMIN:
        return 'Administrator';
      case UserRole.ACCOUNTANT:
        return 'Accountant';
    }
  }
}
