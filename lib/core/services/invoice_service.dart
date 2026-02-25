import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/invoice.dart';

/// Service for invoice-related operations
class InvoiceService {
  final ApiClient _apiClient;

  InvoiceService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Generate invoice for a student (admin)
  Future<Invoice> generateStudentInvoice({
    required int studentId,
    required int year,
    required int month,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.invoicesGenerateStudent,
      queryParams: {
        'studentId': studentId.toString(),
        'year': year.toString(),
        'month': month.toString(),
      },
    );
    return Invoice.fromJson(response as Map<String, dynamic>);
  }

  /// Generate invoices for a group (admin)
  Future<List<Invoice>> generateGroupInvoices({
    required int groupId,
    required int year,
    required int month,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.invoicesGenerateGroup,
      queryParams: {
        'groupId': groupId.toString(),
        'year': year.toString(),
        'month': month.toString(),
      },
    );
    return (response as List)
        .map((json) => Invoice.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get student invoices
  Future<List<Invoice>> getStudentInvoices(int studentId) async {
    final response = await _apiClient.get(
      ApiConstants.invoicesByStudent(studentId),
    );
    return (response as List)
        .map((json) => Invoice.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Search invoices by account number (admin/accountant)
  Future<List<Invoice>> searchInvoices(String accountNumber) async {
    final response = await _apiClient.get(
      ApiConstants.invoicesSearch,
      queryParams: {'accountNumber': accountNumber},
    );
    return (response as List)
        .map((json) => Invoice.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get student debt summary
  Future<DebtSummary> getStudentDebt(int studentId) async {
    final response = await _apiClient.get(ApiConstants.invoicesDebt(studentId));
    return DebtSummary.fromJson(response as Map<String, dynamic>);
  }
}
