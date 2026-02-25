import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../storage/secure_storage_service.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../services/attendance_service.dart';
import '../services/grade_service.dart';
import '../services/schedule_service.dart';
import '../services/announcement_service.dart';
import '../services/payment_service.dart';
import '../services/invoice_service.dart';
import '../models/auth_response.dart';
import 'auth_notifier.dart';

// Core infrastructure providers
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

// Service providers
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    apiClient: ref.watch(apiClientProvider),
    storageService: ref.watch(secureStorageProvider),
  );
});

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(apiClient: ref.watch(apiClientProvider));
});

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService(apiClient: ref.watch(apiClientProvider));
});

final gradeServiceProvider = Provider<GradeService>((ref) {
  return GradeService(apiClient: ref.watch(apiClientProvider));
});

final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService(apiClient: ref.watch(apiClientProvider));
});

final announcementServiceProvider = Provider<AnnouncementService>((ref) {
  return AnnouncementService(apiClient: ref.watch(apiClientProvider));
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(apiClient: ref.watch(apiClientProvider));
});

final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  return InvoiceService(apiClient: ref.watch(apiClientProvider));
});

// Auth state management
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthResponse?>>((ref) {
      final notifier = AuthNotifier(ref.watch(authServiceProvider));
      ref
          .read(apiClientProvider)
          .setUnauthorizedHandler(notifier.handleUnauthorized);
      return notifier;
    });

// Current user provider
final currentUserProvider = Provider<AuthResponse?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.value;
});

// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
