import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/class_group.dart';
import '../../core/models/invoice.dart';
import '../../core/providers/providers.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/app_badge.dart';

class BillingPage extends ConsumerStatefulWidget {
  const BillingPage({super.key});

  @override
  ConsumerState<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends ConsumerState<BillingPage> {
  String _filter = 'all';
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _errorMessage;
  List<_InvoiceView> _invoices = [];
  List<ClassGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final invoiceService = ref.read(invoiceServiceProvider);

      final students = await adminService.getStudents();
      final groups = await adminService.getClassGroups();

      final allInvoices = <_InvoiceView>[];
      for (final student in students) {
        try {
          final studentInvoices = await invoiceService.getStudentInvoices(
            student.id,
          );
          for (final invoice in studentInvoices) {
            allInvoices.add(
              _InvoiceView.fromInvoice(invoice, student.classGroupName),
            );
          }
        } catch (_) {
          // Skip individual student failures; continue loading others.
        }
      }

      allInvoices.sort((a, b) => b.dueDate.compareTo(a.dueDate));

      setState(() {
        _groups = groups;
        _invoices = allInvoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load invoices: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createGroupInvoice() async {
    if (_groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No groups available for invoice creation'),
        ),
      );
      return;
    }

    ClassGroup selectedGroup = _groups.first;
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Invoice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ClassGroup>(
                initialValue: selectedGroup,
                decoration: const InputDecoration(labelText: 'Group'),
                items: _groups
                    .map(
                      (g) => DropdownMenuItem<ClassGroup>(
                        value: g,
                        child: Text(g.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedGroup = value);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedMonth,
                      decoration: const InputDecoration(labelText: 'Month'),
                      items: List.generate(12, (i) => i + 1)
                          .map(
                            (m) => DropdownMenuItem<int>(
                              value: m,
                              child: Text(
                                DateFormat('MMMM').format(DateTime(2024, m)),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedMonth = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      initialValue: selectedYear.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Year'),
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed != null) {
                          selectedYear = parsed;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );

    if (shouldCreate != true) return;

    setState(() => _isGenerating = true);
    try {
      final invoiceService = ref.read(invoiceServiceProvider);
      await invoiceService.generateGroupInvoices(
        groupId: selectedGroup.id,
        year: selectedYear,
        month: selectedMonth,
      );
      await _loadInvoices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoices generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate invoices: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  List<_InvoiceView> get _filtered {
    if (_filter == 'all') return _invoices;
    return _invoices.where((invoice) => invoice.status == _filter).toList();
  }

  double get _totalCollected =>
      _invoices.fold(0.0, (sum, invoice) => sum + invoice.amountPaid);

  double get _outstanding =>
      _invoices.fold(0.0, (sum, invoice) => sum + invoice.amountOutstanding);

  int get _unpaidCount => _invoices
      .where(
        (invoice) => invoice.status != 'paid' && invoice.status != 'cancelled',
      )
      .length;

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '₸ ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'Billing',
          subtitle: 'Manage student payments',
          actions: [
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _createGroupInvoice,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add, size: 16),
              label: const Text('New Invoice'),
            ),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!, style: AppTextStyles.bodyMedium),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          final cols = constraints.maxWidth > 600 ? 3 : 1;
                          return GridView.count(
                            crossAxisCount: cols,
                            shrinkWrap: true,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                            childAspectRatio: 2.2,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              MetricCard(
                                title: 'Total Collected',
                                value: _formatCurrency(_totalCollected),
                                icon: Icons.check_circle_outline,
                                trend: 'All paid invoices',
                              ),
                              MetricCard(
                                title: 'Outstanding',
                                value: _formatCurrency(_outstanding),
                                icon: Icons.warning_outlined,
                                trend: '$_unpaidCount unpaid',
                                trendUp: false,
                                highlight: true,
                              ),
                              MetricCard(
                                title: 'Total Invoices',
                                value: _invoices.length.toString(),
                                icon: Icons.receipt_long_outlined,
                                trend: 'Across all students',
                                trendUp: true,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Text('Invoices', style: AppTextStyles.heading4),
                          const Spacer(),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'all', label: Text('All')),
                              ButtonSegment(value: 'paid', label: Text('Paid')),
                              ButtonSegment(
                                value: 'unpaid',
                                label: Text('Unpaid'),
                              ),
                              ButtonSegment(
                                value: 'partially_paid',
                                label: Text('Partial'),
                              ),
                              ButtonSegment(
                                value: 'overdue',
                                label: Text('Overdue'),
                              ),
                            ],
                            selected: {_filter},
                            onSelectionChanged: (s) =>
                                setState(() => _filter = s.first),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_filtered.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                          ),
                          child: Text(
                            'No invoices found',
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                          ),
                          child: Column(
                            children: [
                              const _TableHeader(),
                              ..._filtered.asMap().entries.map(
                                (entry) => Column(
                                  children: [
                                    _InvoiceRow(invoice: entry.value),
                                    if (entry.key < _filtered.length - 1)
                                      const Divider(
                                        height: 1,
                                        color: AppColors.border,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusLg),
          topRight: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('Invoice', style: AppTextStyles.label)),
          Expanded(flex: 2, child: Text('Student', style: AppTextStyles.label)),
          Expanded(flex: 1, child: Text('Group', style: AppTextStyles.label)),
          Expanded(flex: 1, child: Text('Amount', style: AppTextStyles.label)),
          Expanded(flex: 1, child: Text('Period', style: AppTextStyles.label)),
          Expanded(flex: 1, child: Text('Status', style: AppTextStyles.label)),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final _InvoiceView invoice;
  const _InvoiceRow({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final variant = switch (invoice.status) {
      'paid' => BadgeVariant.paid,
      'partially_paid' => BadgeVariant.partial,
      _ => BadgeVariant.unpaid,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              invoice.id,
              style: AppTextStyles.bodySmall.copyWith(fontFamily: 'monospace'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              invoice.student,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(invoice.group, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            flex: 1,
            child: Text(
              invoice.amountText,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(invoice.period, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            flex: 1,
            child: AppBadge(text: invoice.statusLabel, variant: variant),
          ),
        ],
      ),
    );
  }
}

class _InvoiceView {
  final String id;
  final String student;
  final String group;
  final double amountDue;
  final double amountPaid;
  final double amountOutstanding;
  final String amountText;
  final String status;
  final String statusLabel;
  final String period;
  final DateTime dueDate;

  const _InvoiceView({
    required this.id,
    required this.student,
    required this.group,
    required this.amountDue,
    required this.amountPaid,
    required this.amountOutstanding,
    required this.amountText,
    required this.status,
    required this.statusLabel,
    required this.period,
    required this.dueDate,
  });

  factory _InvoiceView.fromInvoice(Invoice invoice, String? groupName) {
    final periodDate = DateTime(invoice.year, invoice.month);
    final status = invoice.status.name.toLowerCase();
    final statusLabel = switch (invoice.status) {
      InvoiceStatus.UNPAID => 'Unpaid',
      InvoiceStatus.PARTIALLY_PAID => 'Partially Paid',
      InvoiceStatus.PAID => 'Paid',
      InvoiceStatus.OVERDUE => 'Overdue',
      InvoiceStatus.CANCELLED => 'Cancelled',
    };

    return _InvoiceView(
      id: 'INV-${invoice.id}',
      student: invoice.studentName ?? 'Student #${invoice.studentId ?? '-'}',
      group: groupName ?? '-',
      amountDue: invoice.amountDue,
      amountPaid: invoice.amountPaid,
      amountOutstanding: invoice.amountOutstanding,
      amountText: NumberFormat.currency(
        symbol: '₸ ',
        decimalDigits: 0,
      ).format(invoice.amountDue),
      status: status,
      statusLabel: statusLabel,
      period: DateFormat('MMM yyyy').format(periodDate),
      dueDate: invoice.dueDate,
    );
  }
}
