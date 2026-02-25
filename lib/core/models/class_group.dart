/// Class group (class) model
class ClassGroup {
  final int id;
  final String name;
  final int? grade;
  final int? monthlyFee;
  final int? studentCount;

  ClassGroup({
    required this.id,
    required this.name,
    this.grade,
    this.monthlyFee,
    this.studentCount,
  });

  factory ClassGroup.fromJson(Map<String, dynamic> json) {
    return ClassGroup(
      id: json['id'] as int,
      name: json['name'] as String,
      grade: json['grade'] as int?,
      monthlyFee: json['monthlyFee'] as int?,
      studentCount: (json['studentCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'monthlyFee': monthlyFee,
      'studentCount': studentCount,
    };
  }
}
