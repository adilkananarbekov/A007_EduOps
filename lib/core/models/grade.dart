/// Grade model
class Grade {
  final int id;
  final int studentId;
  final String? studentName;
  final int subjectId;
  final String subjectName;
  final double score;
  final double maxScore;
  final String? gradeType;
  final DateTime date;
  final String? notes;

  Grade({
    required this.id,
    required this.studentId,
    this.studentName,
    required this.subjectId,
    required this.subjectName,
    required this.score,
    required this.maxScore,
    this.gradeType,
    required this.date,
    this.notes,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] as int,
      studentId: json['studentId'] as int,
      studentName: json['studentName'] as String?,
      subjectId: json['subjectId'] as int,
      subjectName: json['subjectName'] as String,
      score: (json['score'] as num).toDouble(),
      maxScore: (json['maxScore'] as num).toDouble(),
      gradeType: json['gradeType'] as String?,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'score': score,
      'maxScore': maxScore,
      'gradeType': gradeType,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  /// Calculate percentage
  double get percentage => (score / maxScore) * 100;

  /// Get letter grade (A, B, C, D, F)
  String get letterGrade {
    final percent = percentage;
    if (percent >= 90) return 'A';
    if (percent >= 80) return 'B';
    if (percent >= 70) return 'C';
    if (percent >= 60) return 'D';
    return 'F';
  }
}

/// Grade averages model
class GradeAverages {
  final double overallAverage;
  final Map<String, double> subjectAverages;

  GradeAverages({required this.overallAverage, required this.subjectAverages});

  factory GradeAverages.fromJson(Map<String, dynamic> json) {
    return GradeAverages(
      overallAverage: (json['overallAverage'] as num).toDouble(),
      subjectAverages: Map<String, double>.from(
        (json['subjectAverages'] as Map).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallAverage': overallAverage,
      'subjectAverages': subjectAverages,
    };
  }
}
