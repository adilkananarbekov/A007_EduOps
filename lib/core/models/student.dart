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
    // Backend sends "name" as combined name; fall back to firstName+lastName
    final name =
        json['name'] as String? ??
        '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim();
    return Student(
      id: json['id'] as int,
      userId: json['userId'] as int?,
      name: name.isNotEmpty ? name : 'Unknown',
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      classGroupId: json['classGroupId'] as int?,
      classGroupName: json['classGroupName'] as String?,
      studentNumber: json['studentNumber'] as String?,
      accountNumber: json['accountNumber'] as String?,
      parentEmail: json['parentEmail'] as String?,
      parentPhone: json['parentPhone'] as String?,
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
}
