import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/payment.dart';

/// Service for payment-related operations
class PaymentService {
  final ApiClient _apiClient;

  PaymentService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Submit payment (student)
  Future<Payment> submitPayment({
    required String accountNumber,
    required double amount,
    required DateTime paymentDate,
    String? proofImageUrl,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.paymentSubmit,
      body: {
        'accountNumber': accountNumber,
        'amount': amount,
        'paymentDate': paymentDate.toIso8601String().split('T')[0],
        'proofImageUrl': proofImageUrl,
        'notes': notes,
      },
    );
    return Payment.fromJson(response as Map<String, dynamic>);
  }

  /// Get pending payments (accountant/admin)
  Future<List<Payment>> getPendingPayments() async {
    final response = await _apiClient.get(ApiConstants.paymentPending);
    return (response as List)
        .map((json) => Payment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Search payments by account number (accountant/admin)
  Future<List<Payment>> searchPayments(String accountNumber) async {
    final response = await _apiClient.get(
      ApiConstants.paymentSearch,
      queryParams: {'accountNumber': accountNumber},
    );
    return (response as List)
        .map((json) => Payment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Approve payment (accountant/admin)
  Future<Payment> approvePayment(int id) async {
    final response = await _apiClient.post(ApiConstants.paymentApprove(id));
    return Payment.fromJson(response as Map<String, dynamic>);
  }

  /// Reject payment (accountant/admin)
  Future<Payment> rejectPayment(int id, {String? reason}) async {
    final response = await _apiClient.post(
      ApiConstants.paymentReject(id),
      body: reason != null ? {'reason': reason} : null,
    );
    return Payment.fromJson(response as Map<String, dynamic>);
  }
}
