import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/student.dart';
import '../../core/models/attendance.dart';
import '../../core/models/grade.dart';
import '../../core/models/invoice.dart';
import '../../core/models/schedule.dart';
import '../../core/providers/providers.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';

class StudentProfilePage extends ConsumerStatefulWidget {
  final String studentId;
  const StudentProfilePage({super.key, required this.studentId});

  @override
  ConsumerState<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends ConsumerState<StudentProfilePage> {
  bool _isLoading = true;
  String? _errorMessage;

  Student? _student;
  List<Attendance> _attendance = [];
  List<Grade> _grades = [];
  List<Invoice> _invoices = [];
  List<Schedule> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final studentIdInt = int.tryParse(widget.studentId);
    if (studentIdInt == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid student ID';
      });
      return;
    }

    try {
      final adminService = ref.read(adminServiceProvider);
      final students = await adminService.getStudents();
      final matched = students.where((s) => s.id == studentIdInt);
      if (matched.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Student not found';
        });
        return;
      }
      _student = matched.first;

      // Load related data in parallel, each can fail independently
      final results = await Future.wait([
        ref
            .read(attendanceServiceProvider)
            .getStudentAttendance(studentIdInt)
            .catchError((e) {
              debugPrint('[PROFILE] attendance error: $e');
              return <Attendance>[];
            }),
        ref
            .read(gradeServiceProvider)
            .getStudentGrades(studentIdInt)
            .catchError((e) {
              debugPrint('[PROFILE] grades error: $e');
              return <Grade>[];
            }),
        ref
            .read(invoiceServiceProvider)
            .getStudentInvoices(studentIdInt)
            .catchError((e) {
              debugPrint('[PROFILE] invoices error: $e');
              return <Invoice>[];
            }),
        _student!.classGroupId != null
            ? ref
                  .read(scheduleServiceProvider)
                  .getClassSchedule(_student!.classGroupId!)
                  .catchError((e) {
                    debugPrint('[PROFILE] schedule error: $e');
                    return <Schedule>[];
                  })
            : Future.value(<Schedule>[]),
      ]);

      if (!mounted) return;
      setState(() {
        _attendance = results[0] as List<Attendance>;
        _grades = results[1] as List<Grade>;
        _invoices = results[2] as List<Invoice>;
        _schedules = results[3] as List<Schedule>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[PROFILE] Unexpected error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load student data';
      });
    }
  }

  String get _attendanceRate {
    if (_attendance.isEmpty) return '—';
    final present = _attendance
        .where((a) => a.status == AttendanceStatus.PRESENT)
        .length;
    return '${((present / _attendance.length) * 100).round()}%';
  }

  double get _outstandingFees {
    return _invoices.fold(0.0, (sum, inv) => sum + inv.amountOutstanding);
  }

  double get _monthlyFee {
    if (_invoices.isNotEmpty) return _invoices.first.amountDue;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Back button + header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/admin/students'),
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Student Profile', style: AppTextStyles.heading3),
                const Spacer(),
                if (!_isLoading && _student != null)
                  IconButton(
                    onPressed: _loadStudentData,
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Refresh',
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.mutedForeground,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(_errorMessage!, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton(
                          onPressed: _loadStudentData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final student = _student!;
    final initials = student.name.isNotEmpty
        ? student.name
              .split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join()
        : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Card
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.muted,
                  child: Text(
                    initials,
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.fullName, style: AppTextStyles.heading3),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${student.classGroupName ?? 'No Group'} · ID: #${student.id}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.xl,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _InfoItem(Icons.email_outlined, student.email),
                          if (student.phoneNumber != null)
                            _InfoItem(
                              Icons.phone_outlined,
                              student.phoneNumber!,
                            ),
                          if (student.studentNumber != null)
                            _InfoItem(
                              Icons.badge_outlined,
                              student.studentNumber!,
                            ),
                          if (student.accountNumber != null)
                            _InfoItem(
                              Icons.account_balance_outlined,
                              'Acc: ${student.accountNumber}',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Stats
          LayoutBuilder(
            builder: (ctx, constraints) {
              final cols = constraints.maxWidth > 600 ? 3 : 1;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 2.5,
                children: [
                  _StatCard(
                    'Attendance Rate',
                    _attendanceRate,
                    _attendanceRate == '—'
                        ? AppColors.mutedForeground
                        : AppColors.greenText,
                  ),
                  _StatCard(
                    'Monthly Fee',
                    _monthlyFee > 0
                        ? NumberFormat.currency(
                            symbol: '₸ ',
                            decimalDigits: 0,
                          ).format(_monthlyFee)
                        : '—',
                    AppColors.foreground,
                  ),
                  _StatCard(
                    'Outstanding',
                    _outstandingFees > 0
                        ? NumberFormat.currency(
                            symbol: '₸ ',
                            decimalDigits: 0,
                          ).format(_outstandingFees)
                        : '₸ 0',
                    _outstandingFees > 0
                        ? AppColors.primary
                        : AppColors.greenText,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Tabs
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const TabBar(
              tabs: [
                Tab(text: 'Schedule'),
                Tab(text: 'Grades'),
                Tab(text: 'Billing'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 350,
            child: TabBarView(
              children: [
                _ScheduleTab(schedules: _schedules),
                _GradesTab(grades: _grades),
                _BillingTab(invoices: _invoices),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ─────────────────────────────────────────────────────────

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.mutedForeground),
        const SizedBox(width: AppSpacing.xs),
        Text(text, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  const _StatCard(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.heading4.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

// ─── Schedule Tab ───────────────────────────────────────────────────────────

class _ScheduleTab extends StatelessWidget {
  final List<Schedule> schedules;
  const _ScheduleTab({required this.schedules});

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No schedule data yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    // Group by day
    final grouped = <String, List<Schedule>>{};
    for (final s in schedules) {
      grouped.putIfAbsent(s.dayOfWeek, () => []).add(s);
    }

    final orderedDays = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => orderedDays.indexOf(a.key) - orderedDays.indexOf(b.key));

    return ListView(
      children: sortedEntries.map((entry) {
        final day = entry.key[0] + entry.key.substring(1).toLowerCase();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.xs,
                top: AppSpacing.sm,
              ),
              child: Text(
                day,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
            ...entry.value.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.muted,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Text(
                          '${s.startTime} – ${s.endTime}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.subjectName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (s.teacherName != null || s.room != null)
                              Text(
                                [
                                  s.teacherName,
                                  s.room,
                                ].whereType<String>().join(' · '),
                                style: AppTextStyles.caption,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ─── Grades Tab ─────────────────────────────────────────────────────────────

class _GradesTab extends StatelessWidget {
  final List<Grade> grades;
  const _GradesTab({required this.grades});

  @override
  Widget build(BuildContext context) {
    if (grades.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school_outlined,
              size: 48,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No grades yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    final sorted = List<Grade>.from(grades)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        final g = sorted[i];
        final pct = g.percentage;
        final color = pct >= 80
            ? AppColors.greenText
            : pct >= 60
            ? Colors.orange
            : AppColors.primary;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                alignment: Alignment.center,
                child: Text(
                  g.letterGrade,
                  style: AppTextStyles.heading4.copyWith(color: color),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.subjectName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${g.score.toStringAsFixed(0)}/${g.maxScore.toStringAsFixed(0)} · ${g.gradeType ?? 'Grade'}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('MMM d').format(g.date),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Billing Tab ────────────────────────────────────────────────────────────

class _BillingTab extends StatelessWidget {
  final List<Invoice> invoices;
  const _BillingTab({required this.invoices});

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No invoices yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    final sorted = List<Invoice>.from(invoices)
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        final inv = sorted[i];
        final period = DateFormat(
          'MMM yyyy',
        ).format(DateTime(inv.year, inv.month));
        final badgeVariant = switch (inv.status) {
          InvoiceStatus.PAID => BadgeVariant.paid,
          InvoiceStatus.PARTIALLY_PAID => BadgeVariant.partial,
          _ => BadgeVariant.unpaid,
        };
        final statusLabel = switch (inv.status) {
          InvoiceStatus.PAID => 'Paid',
          InvoiceStatus.PARTIALLY_PAID => 'Partial',
          InvoiceStatus.OVERDUE => 'Overdue',
          InvoiceStatus.CANCELLED => 'Cancelled',
          InvoiceStatus.UNPAID => 'Unpaid',
        };

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(period, style: AppTextStyles.bodyMedium),
                    if (inv.description != null)
                      Text(
                        inv.description!,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                NumberFormat.currency(
                  symbol: '₸ ',
                  decimalDigits: 0,
                ).format(inv.amountDue),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AppBadge(text: statusLabel, variant: badgeVariant),
            ],
          ),
        );
      },
    );
  }
}
