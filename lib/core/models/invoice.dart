enum InvoiceStatus {
  UNPAID,
  PARTIALLY_PAID,
  PAID,
  OVERDUE,
  CANCELLED;

  static InvoiceStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'UNPAID':
        return InvoiceStatus.UNPAID;
      case 'PARTIALLY_PAID':
        return InvoiceStatus.PARTIALLY_PAID;
      case 'PAID':
        return InvoiceStatus.PAID;
      case 'OVERDUE':
        return InvoiceStatus.OVERDUE;
      case 'CANCELLED':
        return InvoiceStatus.CANCELLED;
      default:
        return InvoiceStatus.UNPAID;
    }
  }
}

/// Invoice model
class Invoice {
  final int id;
  final int? studentId;
  final String? studentName;
  final String? accountNumber;
  final double amountDue;
  final double amountPaid;
  final DateTime dueDate;
  final DateTime? paidDate;
  final InvoiceStatus status;
  final String? description;
  final int month;
  final int year;

  Invoice({
    required this.id,
    this.studentId,
    this.studentName,
    this.accountNumber,
    required this.amountDue,
    required this.amountPaid,
    required this.dueDate,
    this.paidDate,
    required this.status,
    this.description,
    required this.month,
    required this.year,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final studentJson = json['student'] as Map<String, dynamic>?;
    final dueDate = DateTime.parse(json['dueDate'] as String);
    final amountDueValue =
      (json['amountDue'] as num?) ?? (json['amount'] as num?) ?? 0;
    final amountPaid =
      ((json['amountPaid'] as num?) ??
          ((json['isPaid'] == true) ? amountDueValue : 0))
        .toDouble();

    final resolvedStudentName =
      json['studentName'] as String? ??
      studentJson?['fullName'] as String? ??
      '${studentJson?['firstName'] ?? ''} ${studentJson?['lastName'] ?? ''}'
        .trim();

    final statusString =
        json['status'] as String? ??
        ((json['isPaid'] == true) ? 'PAID' : 'UNPAID');

    return Invoice(
      id: json['id'] as int,
      studentId:
          (json['studentId'] as num?)?.toInt() ??
          (studentJson?['id'] as num?)?.toInt(),
        studentName: resolvedStudentName.isEmpty ? null : resolvedStudentName,
      accountNumber: json['accountNumber'] as String?,
        amountDue: amountDueValue.toDouble(),
      amountPaid: amountPaid,
      dueDate: dueDate,
      paidDate: json['paidDate'] != null
          ? DateTime.parse(json['paidDate'] as String)
          : null,
      status: InvoiceStatus.fromString(statusString),
      description: json['description'] as String?,
      month: (json['month'] as int?) ?? dueDate.month,
      year: (json['year'] as int?) ?? dueDate.year,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'accountNumber': accountNumber,
      'amountDue': amountDue,
      'amountPaid': amountPaid,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'status': status.name,
      'description': description,
      'month': month,
      'year': year,
    };
  }

  bool get isPaid => status == InvoiceStatus.PAID;

  bool get isOverdue =>
      status == InvoiceStatus.OVERDUE ||
      (!isPaid && DateTime.now().isAfter(dueDate));

  double get amountOutstanding =>
      (amountDue - amountPaid).clamp(0, amountDue).toDouble();
}

/// Debt summary model
class DebtSummary {
  final int studentId;
  final double totalDebt;
  final int unpaidInvoices;
  final List<Invoice> invoices;

  DebtSummary({
    required this.studentId,
    required this.totalDebt,
    required this.unpaidInvoices,
    required this.invoices,
  });

  factory DebtSummary.fromJson(Map<String, dynamic> json) {
    return DebtSummary(
      studentId: json['studentId'] as int,
      totalDebt: (json['totalDebt'] as num).toDouble(),
      unpaidInvoices: json['unpaidInvoices'] as int,
      invoices:
          (json['invoices'] as List?)
              ?.map((e) => Invoice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'totalDebt': totalDebt,
      'unpaidInvoices': unpaidInvoices,
      'invoices': invoices.map((e) => e.toJson()).toList(),
    };
  }
}
