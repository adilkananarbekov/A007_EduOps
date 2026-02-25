import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/invoice.dart';
import '../../core/providers/providers.dart';
import '../../widgets/app_badge.dart';

class MobileBillingPage extends ConsumerStatefulWidget {
  const MobileBillingPage({super.key});

  @override
  ConsumerState<MobileBillingPage> createState() => _MobileBillingPageState();
}

class _MobileBillingPageState extends ConsumerState<MobileBillingPage> {
  List<Invoice> _invoices = [];
  DebtSummary? _debtSummary;
  bool _isLoading = true;
  bool _isPaying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBillingData();
  }

  Future<void> _loadBillingData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      final studentId = user?.profileId;
      if (studentId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Student profile not found for current user.';
        });
        return;
      }

      final invoiceService = ref.read(invoiceServiceProvider);
      final invoices = await invoiceService.getStudentInvoices(studentId);
      final debt = await invoiceService.getStudentDebt(studentId);

      invoices.sort((a, b) => b.dueDate.compareTo(a.dueDate));

      setState(() {
        _invoices = invoices;
        _debtSummary = debt;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load billing data: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _payNow() async {
    final unpaidInvoice = _invoices
        .where(
          (invoice) =>
              invoice.amountOutstanding > 0 &&
              invoice.status != InvoiceStatus.CANCELLED,
        )
        .firstOrNull;
    if (unpaidInvoice == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No unpaid invoices found')));
      return;
    }

    setState(() => _isPaying = true);
    try {
      if (unpaidInvoice.accountNumber == null ||
          unpaidInvoice.accountNumber!.isEmpty) {
        throw Exception('Invoice account number is missing');
      }

      final paymentService = ref.read(paymentServiceProvider);
      await paymentService.submitPayment(
        accountNumber: unpaidInvoice.accountNumber!,
        amount: unpaidInvoice.amountOutstanding,
        paymentDate: DateTime.now(),
        notes: 'Submitted from mobile app',
      );
      await _loadBillingData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit payment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPaying = false);
      }
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '₸ ', decimalDigits: 0).format(amount);
  }

  String _formatPeriod(Invoice invoice) {
    return DateFormat(
      'MMMM yyyy',
    ).format(DateTime(invoice.year, invoice.month));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final studentName = user?.firstName ?? 'Student';
    final unpaidInvoice = _invoices
        .where(
          (invoice) =>
              invoice.amountOutstanding > 0 &&
              invoice.status != InvoiceStatus.CANCELLED,
        )
        .firstOrNull;

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
        ? Center(child: Text(_errorMessage!, style: AppTextStyles.bodyMedium))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Billing', style: AppTextStyles.heading3),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "$studentName's payment history",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.credit_card_outlined,
                            color: Colors.white54,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Outstanding Balance',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _formatCurrency(_debtSummary?.totalDebt ?? 0),
                        style: AppTextStyles.heading1.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        unpaidInvoice != null
                            ? 'Due: ${DateFormat('MMMM yyyy').format(unpaidInvoice.dueDate)}'
                            : 'No pending payments',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isPaying ? null : _payNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                          ),
                          child: _isPaying
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Pay Now'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Payment History', style: AppTextStyles.heading4),
                const SizedBox(height: AppSpacing.md),
                if (_invoices.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Text(
                      'No invoices found',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._invoices.map((invoice) {
                    final variant = switch (invoice.status) {
                      InvoiceStatus.PAID => BadgeVariant.paid,
                      InvoiceStatus.PARTIALLY_PAID => BadgeVariant.partial,
                      _ => BadgeVariant.unpaid,
                    };
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: invoice.status == InvoiceStatus.PAID
                                  ? AppColors.greenBg
                                  : AppColors.redBg,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusLg,
                              ),
                            ),
                            child: Icon(
                              invoice.status == InvoiceStatus.PAID
                                  ? Icons.check_circle_outline
                                  : Icons.pending_outlined,
                              color: invoice.status == InvoiceStatus.PAID
                                  ? AppColors.greenText
                                  : AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatPeriod(invoice),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  invoice.description ?? 'Monthly tuition fee',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatCurrency(invoice.amountDue),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AppBadge(
                                text: invoice.status.name
                                    .toLowerCase()
                                    .replaceAll('_', ' '),
                                variant: variant,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
