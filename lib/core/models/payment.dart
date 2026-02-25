/// Payment status enumeration
enum PaymentStatus {
  PENDING,
  APPROVED,
  REJECTED;

  static PaymentStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return PaymentStatus.PENDING;
      case 'APPROVED':
        return PaymentStatus.APPROVED;
      case 'REJECTED':
        return PaymentStatus.REJECTED;
      default:
        throw ArgumentError('Invalid payment status: $status');
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.PENDING:
        return 'Pending';
      case PaymentStatus.APPROVED:
        return 'Approved';
      case PaymentStatus.REJECTED:
        return 'Rejected';
    }
  }
}

/// Payment model
class Payment {
  final int id;
  final int studentId;
  final String? studentName;
  final String accountNumber;
  final String? receiptNumber;
  final double amount;
  final DateTime createdAt;
  final PaymentStatus status;
  final String? proofImageUrl;
  final String? notes;
  final DateTime? processedAt;
  final int? processedById;
  final String? processedByName;

  Payment({
    required this.id,
    required this.studentId,
    this.studentName,
    required this.accountNumber,
    this.receiptNumber,
    required this.amount,
    required this.createdAt,
    required this.status,
    this.proofImageUrl,
    this.notes,
    this.processedAt,
    this.processedById,
    this.processedByName,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    final processedByJson = json['processedBy'];
    int? processedById;
    String? processedByName;

    if (processedByJson is Map<String, dynamic>) {
      processedById = processedByJson['id'] as int?;
      final first = processedByJson['firstName'] as String? ?? '';
      final last = processedByJson['lastName'] as String? ?? '';
      processedByName = '$first $last'.trim();
      if (processedByName.isEmpty) processedByName = null;
    } else if (processedByJson is int) {
      processedById = processedByJson;
    }

    // Support both createdAt (backend) and paymentDate (legacy)
    final dateStr = json['createdAt'] as String? ?? json['paymentDate'] as String? ?? DateTime.now().toIso8601String();

    return Payment(
      id: json['id'] as int,
      studentId: json['studentId'] as int,
      studentName: json['studentName'] as String?,
      accountNumber: json['accountNumber'] as String? ?? '',
      receiptNumber: json['receiptNumber'] as String?,
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(dateStr),
      status: PaymentStatus.fromString(
        json['paymentStatus'] as String? ?? json['status'] as String? ?? 'PENDING',
      ),
      proofImageUrl: json['proofImageUrl'] as String?,
      notes: json['notes'] as String?,
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
      processedById: processedById,
      processedByName: processedByName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'accountNumber': accountNumber,
      'receiptNumber': receiptNumber,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'proofImageUrl': proofImageUrl,
      'notes': notes,
      'processedAt': processedAt?.toIso8601String(),
      'processedById': processedById,
      'processedByName': processedByName,
    };
  }

  /// Alias for backward compatibility
  DateTime get paymentDate => createdAt;
}
