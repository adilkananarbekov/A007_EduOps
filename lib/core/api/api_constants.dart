/// API constants for EduOps backend integration
class ApiConstants {
  // Base configuration
  static const String baseUrl = 'http://136.116.64.6';
  static const String apiPrefix = '/api';
  static const String baseApiUrl = '$baseUrl$apiPrefix';

  // Timeout configuration
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Authentication endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String registerInitial = '/auth/register/initial';

  // Admin endpoints
  static const String users = '/admin/users';
  static const String students = '/admin/students';
  static const String studentsUnassigned = '/admin/students/unassigned';
  static String studentsByClass(int classGroupId) =>
      '/admin/students/class/$classGroupId';
  static String updateStudentClass(int studentId) =>
      '/admin/students/$studentId/class';
  static const String studentsBulkAssign = '/admin/students/bulk-assign';
  static const String teachers = '/admin/teachers';
  static String updateTeacherSubjects(int teacherId) =>
      '/admin/teachers/$teacherId/subjects';
  static const String classGroups = '/admin/class-groups';
  static String classGroup(int id) => '/admin/class-groups/$id';
  static const String subjects = '/admin/subjects';

  // Announcement endpoints
  static const String announcements = '/announcements';
  static const String announcementsAll = '/announcements/all';
  static String announcementById(int id) => '/announcements/$id';

  // Attendance endpoints
  static const String attendance = '/attendance';
  static const String attendanceRange = '/attendance/range';
  static const String attendanceStats = '/attendance/stats';
  static String attendanceByStudent(int studentId) =>
      '/attendance/student/$studentId';
  static String attendanceBySchedule(int scheduleId) =>
      '/attendance/schedule/$scheduleId';

  // Grade endpoints
  static const String grades = '/grades';
  static String gradesBySubject(int subjectId) => '/grades/subject/$subjectId';
  static const String gradesAverages = '/grades/averages';
  static String gradesByStudent(int studentId) => '/grades/student/$studentId';
  static String gradeById(int id) => '/grades/$id';

  // Invoice endpoints
  static const String invoicesGenerateStudent = '/invoices/generate/student';
  static const String invoicesGenerateGroup = '/invoices/generate/group';
  static String invoicesByStudent(int studentId) =>
      '/invoices/student/$studentId';
  static const String invoicesSearch = '/invoices/search';
  static String invoicesDebt(int studentId) => '/invoices/debt/$studentId';

  // Payment endpoints
  static const String paymentSubmit = '/payment/submit';
  static const String paymentPending = '/payment/pending';
  static const String paymentSearch = '/payment/search';
  static String paymentApprove(int id) => '/payment/$id/approve';
  static String paymentReject(int id) => '/payment/$id/reject';

  // Schedule endpoints
  static const String scheduleWeek = '/schedule/week';
  static String scheduleByClass(int classGroupId) =>
      '/schedule/class/$classGroupId';
  static String scheduleByTeacher(int teacherId) =>
      '/schedule/teacher/$teacherId';
  static const String schedule = '/schedule';
  static const String scheduleGenerate = '/schedule/generate';
  static String scheduleById(int id) => '/schedule/$id';

  // Headers
  static const String authorizationHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String contentTypeJson = 'application/json';

  // Token prefix
  static const String bearerPrefix = 'Bearer ';
}
