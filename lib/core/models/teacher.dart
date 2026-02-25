/// Teacher model
class Teacher {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
  final List<String>? subjects;

  Teacher({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.subjects,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    // Backend may send "name" or "firstName"/"lastName"
    final name =
        json['name'] as String? ??
        '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim();
    return Teacher(
      id: json['id'] as int,
      name: name.isNotEmpty ? name : 'Unknown',
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      subjects: json['subjects'] != null
          ? List<String>.from(json['subjects'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'subjects': subjects,
    };
  }

  String get fullName => name;
  String get firstName => name.split(' ').first;
  String get lastName => name.split(' ').skip(1).join(' ');
}
