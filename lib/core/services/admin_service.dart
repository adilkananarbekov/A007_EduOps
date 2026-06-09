import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../api/api_exception.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/class_group.dart';
import '../models/subject.dart';
import '../utils/remote_id_registry.dart';

class AccessibleStudentsResult {
  final List<Student> students;

  const AccessibleStudentsResult({required this.students});
}

/// Service for admin-related operations
class AdminService {
  final ApiClient _apiClient;

  AdminService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get all users
  Future<List<dynamic>> getUsers() async {
    final response = await _apiClient.get(ApiConstants.users);
    return (response as List)
        .map((json) => json as Map<String, dynamic>)
        .toList();
  }

  /// Get all students
  Future<List<Student>> getStudents() async {
    final response = await _apiClient.get(ApiConstants.students);
    return (response as List)
        .map((json) => json as Map<String, dynamic>)
        .where((json) => _roleOf(json) == 'student')
        .map(Student.fromJson)
        .toList();
  }

  /// Get the best available student list for the signed-in user.
  ///
  /// Admins can usually call the full list endpoint. Teachers may only have
  /// access to group rosters, so this transparently falls back to aggregating
  /// students from all accessible groups.
  Future<AccessibleStudentsResult> getAccessibleStudents({
    int? classGroupId,
  }) async {
    if (classGroupId != null) {
      try {
        final students = await getStudentsByClass(classGroupId);
        return AccessibleStudentsResult(students: _sortStudents(students));
      } on ForbiddenException {
        throw ForbiddenException(
          'Your account does not have permission to view this class roster.',
          statusCode: 403,
        );
      }
    }

    try {
      final students = await getStudents();
      return AccessibleStudentsResult(students: _sortStudents(students));
    } on UnauthorizedException {
      rethrow;
    } on ForbiddenException {
      try {
        final students = await _getStudentsFromGroups();
        return AccessibleStudentsResult(students: students);
      } on UnauthorizedException {
        rethrow;
      } on ForbiddenException {
        throw ForbiddenException(
          'Your account does not have permission to view students.',
          statusCode: 403,
        );
      }
    }
  }

  /// Find a single accessible student without requiring a backend change.
  Future<Student?> getAccessibleStudentById(int studentId) async {
    try {
      final students = await getStudents();
      for (final student in students) {
        if (student.id == studentId) {
          return student;
        }
      }
    } on UnauthorizedException {
      rethrow;
    } on ForbiddenException {
      // Fall back to group roster aggregation below.
    } on ApiException {
      rethrow;
    }

    final students = await _getStudentsFromGroups();
    for (final student in students) {
      if (student.id == studentId) {
        return student;
      }
    }
    return null;
  }

  /// Get students by class
  Future<List<Student>> getStudentsByClass(int classGroupId) async {
    final className =
        RemoteIdRegistry.groupName(classGroupId) ??
        RemoteIdRegistry.remoteId(classGroupId);
    final response = await _apiClient.get(
      '/groups/${Uri.encodeComponent(className)}/students',
    );
    return (response as List)
        .map((json) => Student.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get unassigned students
  Future<List<Student>> getUnassignedStudents() async {
    final students = await getStudents();
    return students.where((student) => student.classGroupName == null).toList();
  }

  /// Update student class
  Future<void> updateStudentClass(int studentId, int classGroupId) async {
    throw UnsupportedError(
      'Changing a student group is not exposed by the current backend API.',
    );
  }

  /// Bulk assign students to class
  Future<void> bulkAssignStudents(
    List<int> studentIds,
    int classGroupId,
  ) async {
    throw UnsupportedError(
      'Bulk student reassignment is not exposed by the current backend API.',
    );
  }

  /// Get all teachers
  Future<List<Teacher>> getTeachers() async {
    final response = await _apiClient.get(ApiConstants.teachers);
    return (response as List)
        .map((json) => json as Map<String, dynamic>)
        .where((json) => _roleOf(json) == 'teacher')
        .map(Teacher.fromJson)
        .toList();
  }

  /// Update teacher subjects
  Future<void> updateTeacherSubjects(
    int teacherId,
    List<int> subjectIds,
  ) async {
    throw UnsupportedError(
      'Teacher subject assignment is not exposed by the current backend API.',
    );
  }

  /// Get all class groups
  Future<List<ClassGroup>> getClassGroups() async {
    final response = await _apiClient.get(ApiConstants.classGroups);
    final groups = (response as List)
        .map((json) => ClassGroup.fromJson(json as Map<String, dynamic>))
        .toList();
    return Future.wait(groups.map(_withStudentCount));
  }

  /// Create class group
  Future<ClassGroup> createClassGroup({
    required String name,
    int? grade,
    int? monthlyFee,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.adminClassGroups,
      body: {
        'name': name,
        'description': grade == null ? null : 'Grade $grade',
      },
    );
    return ClassGroup.fromJson(response as Map<String, dynamic>);
  }

  /// Update class group
  Future<ClassGroup> updateClassGroup(
    int id, {
    required String name,
    int? grade,
    int? monthlyFee,
  }) async {
    final response = await _apiClient.patch(
      '/management/groups/${Uri.encodeComponent(RemoteIdRegistry.remoteId(id))}',
      body: {
        'name': name,
        'description': grade == null ? null : 'Grade $grade',
      },
    );
    return ClassGroup.fromJson(response as Map<String, dynamic>);
  }

  /// Create student user (admin)
  Future<void> createStudent({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    int? classGroupId,
  }) async {
    await _apiClient.post(
      ApiConstants.users,
      body: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': 'student',
        'className': classGroupId == null
            ? null
            : RemoteIdRegistry.groupName(classGroupId),
      },
    );
  }

  /// Delete class group
  Future<void> deleteClassGroup(int id) async {
    await _apiClient.delete(
      '/management/groups/${Uri.encodeComponent(RemoteIdRegistry.remoteId(id))}',
    );
  }

  /// Get all subjects
  Future<List<Subject>> getSubjects() async {
    final response = await _apiClient.get(ApiConstants.subjects);
    return (response as List)
        .map((json) => Subject.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  String _roleOf(Map<String, dynamic> json) =>
      (json['role'] ?? '').toString().trim().toLowerCase();

  Future<ClassGroup> _withStudentCount(ClassGroup group) async {
    try {
      final students = await getStudentsByClass(group.id);
      return ClassGroup(
        id: group.id,
        name: group.name,
        grade: group.grade,
        monthlyFee: group.monthlyFee,
        studentCount: students.length,
      );
    } catch (_) {
      return group;
    }
  }

  Future<List<Student>> _getStudentsFromGroups() async {
    final groups = await getClassGroups();
    final responses = await Future.wait(
      groups.map((group) async {
        final students = await getStudentsByClass(group.id);
        return students
            .map((student) => _mergeGroupContext(student, group))
            .toList();
      }),
    );

    final studentsById = <int, Student>{};
    for (final students in responses) {
      for (final student in students) {
        studentsById.putIfAbsent(student.id, () => student);
      }
    }

    return _sortStudents(studentsById.values);
  }

  Student _mergeGroupContext(Student student, ClassGroup group) {
    if (student.classGroupId != null && student.classGroupName != null) {
      return student;
    }

    return Student(
      id: student.id,
      userId: student.userId,
      name: student.name,
      email: student.email,
      phoneNumber: student.phoneNumber,
      address: student.address,
      dateOfBirth: student.dateOfBirth,
      classGroupId: student.classGroupId ?? group.id,
      classGroupName: student.classGroupName ?? group.name,
      studentNumber: student.studentNumber,
      accountNumber: student.accountNumber,
      parentEmail: student.parentEmail,
      parentPhone: student.parentPhone,
    );
  }

  List<Student> _sortStudents(Iterable<Student> students) {
    final sorted = students.toList();
    sorted.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return sorted;
  }
}
