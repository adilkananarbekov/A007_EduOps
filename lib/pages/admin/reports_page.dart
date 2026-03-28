import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/models/attendance.dart';
import '../../core/models/class_group.dart';
import '../../core/models/grade.dart';
import '../../core/models/student.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/async_batch.dart';
import '../../widgets/app_card.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/page_header.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<String> _loadWarnings = [];
  List<_GroupReport> _groupReports = [];
  _GroupReport? _selectedGroupReport;
  double _overallAttendance = 0;
  int _studentsTracked = 0;
  int _failedStudents = 0;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loadWarnings = [];
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final attendanceService = ref.read(attendanceServiceProvider);
      final gradeService = ref.read(gradeServiceProvider);
      final warnings = <String>[];

      final classGroups = await adminService.getClassGroups();
      final groupReports = await runInBatches(
        classGroups,
        batchSize: 3,
        operation: (group) async {
          try {
            final students = await adminService.getStudentsByClass(group.id);
            final studentReports = await runInBatches(
              students,
              batchSize: 6,
              operation: (student) async {
                final attendance = await attendanceService
                    .getStudentAttendance(student.id)
                    .catchError((error) {
                      warnings.add(
                        'Attendance could not be loaded for ${student.fullName} in ${group.name}.',
                      );
                      debugPrint(
                        '[REPORTS] attendance load failed group=${group.name} student=${student.id} error=$error',
                      );
                      return <Attendance>[];
                    });
                final grades = await gradeService
                    .getStudentGrades(student.id)
                    .catchError((error) {
                      warnings.add(
                        'Grades could not be loaded for ${student.fullName} in ${group.name}.',
                      );
                      debugPrint(
                        '[REPORTS] grades load failed group=${group.name} student=${student.id} error=$error',
                      );
                      return <Grade>[];
                    });

                final sortedAttendance = attendance.toList()
                  ..sort((a, b) => b.date.compareTo(a.date));
                final loadedGrades = grades;
                final presentCount = sortedAttendance
                    .where(
                      (record) => record.status == AttendanceStatus.PRESENT,
                    )
                    .length;
                final attendanceRate = sortedAttendance.isEmpty
                    ? null
                    : (presentCount / sortedAttendance.length) * 100;
                final averageGrade = loadedGrades.isEmpty
                    ? null
                    : loadedGrades
                              .map((grade) => grade.percentage)
                              .reduce((a, b) => a + b) /
                          loadedGrades.length;

                return _StudentReport(
                  student: student,
                  attendanceRate: attendanceRate,
                  attendanceRecords: sortedAttendance.length,
                  averageGrade: averageGrade,
                  gradeCount: loadedGrades.length,
                  latestAttendanceStatus: sortedAttendance.isEmpty
                      ? null
                      : sortedAttendance.first.status,
                );
              },
            );

            var groupPresent = 0;
            var groupTotal = 0;
            var failedStudents = 0;
            var perfectAttendance = 0;

            for (final studentReport in studentReports) {
              if (studentReport.attendanceRate != null) {
                final attendanceRate = studentReport.attendanceRate!;
                groupPresent +=
                    ((attendanceRate / 100) * studentReport.attendanceRecords)
                        .round();
                groupTotal += studentReport.attendanceRecords;
                if (attendanceRate >= 99.5) {
                  perfectAttendance++;
                }
              }

              if (studentReport.isFailed) {
                failedStudents++;
              }
            }

            final attendanceRate = groupTotal == 0
                ? 0.0
                : (groupPresent / groupTotal) * 100;

            studentReports.sort(
              (a, b) => a.student.fullName.toLowerCase().compareTo(
                b.student.fullName.toLowerCase(),
              ),
            );

            return _GroupReport(
              group: group,
              studentReports: studentReports,
              attendanceRate: attendanceRate,
              failedStudents: failedStudents,
              perfectAttendanceStudents: perfectAttendance,
            );
          } catch (error) {
            warnings.add('Group ${group.name} could not be loaded.');
            debugPrint(
              '[REPORTS] group load failed group=${group.name} id=${group.id} error=$error',
            );
            return _GroupReport(
              group: group,
              studentReports: const [],
              attendanceRate: 0,
              failedStudents: 0,
              perfectAttendanceStudents: 0,
              loadError:
                  'This group could not be loaded from the backend for reports.',
            );
          }
        },
      );

      final selectedGroupId = _selectedGroupReport?.group.id;
      var globalPresent = 0;
      var globalTotal = 0;
      var trackedStudents = 0;
      var failedStudents = 0;

      for (final groupReport in groupReports) {
        trackedStudents += groupReport.studentReports.length;
        failedStudents += groupReport.failedStudents;

        for (final studentReport in groupReport.studentReports) {
          if (studentReport.attendanceRate == null) {
            continue;
          }
          globalPresent +=
              ((studentReport.attendanceRate! / 100) *
                      studentReport.attendanceRecords)
                  .round();
          globalTotal += studentReport.attendanceRecords;
        }
      }

      _GroupReport? selectedGroupReport;
      if (selectedGroupId != null) {
        for (final groupReport in groupReports) {
          if (groupReport.group.id == selectedGroupId) {
            selectedGroupReport = groupReport;
            break;
          }
        }
      }
      selectedGroupReport ??= groupReports.isNotEmpty ? groupReports.first : null;

      if (!mounted) return;
      setState(() {
        _groupReports = groupReports;
        _selectedGroupReport = selectedGroupReport;
        _overallAttendance = globalTotal == 0
            ? 0
            : (globalPresent / globalTotal) * 100;
        _studentsTracked = trackedStudents;
        _failedStudents = failedStudents;
        _loadWarnings = warnings.toSet().toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load reports: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _exportReport() async {
    final selectedGroup = _selectedGroupReport;
    if (selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No report data available to export')),
      );
      return;
    }

    final buffer = StringBuffer(
      'Group,Student,Attendance %,Attendance Records,Average Grade %,Grades,Status\n',
    );
    for (final report in selectedGroup.studentReports) {
      buffer.writeln(
        '${selectedGroup.group.name},${report.student.fullName},${report.formattedAttendanceRate},${report.attendanceRecords},${report.formattedAverageGrade},${report.gradeCount},${report.statusLabel}',
      );
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Student report for ${selectedGroup.group.name} copied to clipboard',
        ),
      ),
    );
  }

  void _openStudentReport(_StudentReport report) {
    context.push('/admin/students/${report.student.id}');
  }

  @override
  Widget build(BuildContext context) {
    final selectedGroup = _selectedGroupReport;

    return Column(
      children: [
        PageHeader(
          title: 'Reports',
          subtitle:
              'Open a group to inspect attendance and performance by student.',
          actions: [
            OutlinedButton.icon(
              onPressed: _exportReport,
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Export group'),
            ),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cols = constraints.maxWidth > 960
                              ? 3
                              : constraints.maxWidth > 600
                              ? 2
                              : 1;
                          return GridView.count(
                            crossAxisCount: cols,
                            shrinkWrap: true,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                            childAspectRatio: cols == 1 ? 2.7 : 2.1,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              MetricCard(
                                title: 'Overall Attendance',
                                value: '${_overallAttendance.round()}%',
                                icon: Icons.trending_up_outlined,
                                trend: 'Across all tracked groups',
                              ),
                              MetricCard(
                                title: 'Tracked Students',
                                value: _studentsTracked.toString(),
                                icon: Icons.people_outline,
                                trend: '${_groupReports.length} groups',
                              ),
                              MetricCard(
                                title: 'Failed Students',
                                value: _failedStudents.toString(),
                                icon: Icons.gpp_bad_outlined,
                                trend: 'Attendance below 70%',
                                trendUp: false,
                                highlight: true,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (_loadWarnings.isNotEmpty) ...[
                        AppCard(
                          backgroundColor: AppColors.accentSoftOf(context),
                          borderColor: AppColors.dangerBorderOf(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Some report data could not be loaded',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimaryOf(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                _loadWarnings.join(' '),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMutedOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      Text(
                        'Groups',
                        style: AppTextStyles.heading4.copyWith(
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Choose a group to open detailed student reports.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_groupReports.isEmpty)
                        AppCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              'No group report data available yet.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textMutedOf(context),
                              ),
                            ),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cols = constraints.maxWidth > 1280
                                ? 4
                                : constraints.maxWidth > 920
                                ? 3
                                : constraints.maxWidth > 620
                                ? 2
                                : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              itemCount: _groupReports.length,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    crossAxisSpacing: AppSpacing.md,
                                    mainAxisSpacing: AppSpacing.md,
                                    childAspectRatio: cols == 1 ? 1.55 : 1.28,
                                  ),
                              itemBuilder: (context, index) {
                                final groupReport = _groupReports[index];
                                final isSelected =
                                    selectedGroup?.group.id ==
                                    groupReport.group.id;
                                return _GroupReportCard(
                                  report: groupReport,
                                  isSelected: isSelected,
                                  onTap: () => setState(
                                    () => _selectedGroupReport = groupReport,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        selectedGroup == null
                            ? 'Student Reports'
                            : 'Student Reports · ${selectedGroup.group.name}',
                        style: AppTextStyles.heading4.copyWith(
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        selectedGroup == null
                            ? 'Select a group above to inspect students.'
                            : 'Tap a student row to open the full profile.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (selectedGroup != null) ...[
                        _SelectedGroupSummary(report: selectedGroup),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (selectedGroup == null)
                        AppCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Text(
                              'No group selected yet.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textMutedOf(context),
                              ),
                            ),
                          ),
                        )
                      else if (selectedGroup.studentReports.isEmpty)
                        AppCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Text(
                              'No student reports found for this group.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textMutedOf(context),
                              ),
                            ),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 860) {
                              return _StudentReportTable(
                                reports: selectedGroup.studentReports,
                                onOpenStudent: _openStudentReport,
                              );
                            }
                            return _StudentReportList(
                              reports: selectedGroup.studentReports,
                              onOpenStudent: _openStudentReport,
                            );
                          },
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _GroupReport {
  final ClassGroup group;
  final List<_StudentReport> studentReports;
  final double attendanceRate;
  final int failedStudents;
  final int perfectAttendanceStudents;
  final String? loadError;

  const _GroupReport({
    required this.group,
    required this.studentReports,
    required this.attendanceRate,
    required this.failedStudents,
    required this.perfectAttendanceStudents,
    this.loadError,
  });
}

class _StudentReport {
  final Student student;
  final double? attendanceRate;
  final int attendanceRecords;
  final double? averageGrade;
  final int gradeCount;
  final AttendanceStatus? latestAttendanceStatus;

  const _StudentReport({
    required this.student,
    required this.attendanceRate,
    required this.attendanceRecords,
    required this.averageGrade,
    required this.gradeCount,
    required this.latestAttendanceStatus,
  });

  bool get isFailed => attendanceRate != null && attendanceRate! < 70;

  bool get needsAttention =>
      !isFailed &&
      ((attendanceRate != null && attendanceRate! < 85) ||
          (averageGrade != null && averageGrade! < 75));

  String get statusLabel {
    if (isFailed) {
      return 'Failed';
    }
    if (needsAttention) {
      return 'Watch';
    }
    return 'Stable';
  }

  String get formattedAttendanceRate => attendanceRate == null
      ? '—'
      : '${attendanceRate!.round()}%';

  String get formattedAverageGrade => averageGrade == null
      ? '—'
      : '${averageGrade!.round()}%';
}

class _GroupReportCard extends StatelessWidget {
  final _GroupReport report;
  final bool isSelected;
  final VoidCallback onTap;

  const _GroupReportCard({
    required this.report,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = isSelected
        ? AppColors.primaryOf(context)
        : AppColors.borderOf(context);
    final surface = isSelected
        ? AppColors.primarySoftOf(context)
        : AppColors.surfaceOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final accent = report.attendanceRate >= 80
        ? AppColors.primaryStrongOf(context)
        : AppColors.accentStrongOf(context);

    return AppCard(
      backgroundColor: surface,
      borderColor: border,
      borderWidth: isSelected ? 1.4 : 1,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.group.name,
                  style: AppTextStyles.heading4.copyWith(color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.24)),
                ),
                child: Text(
                  '${report.attendanceRate.round()}%',
                  style: AppTextStyles.caption.copyWith(color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${report.studentReports.length} students',
            style: AppTextStyles.bodyMedium.copyWith(color: textMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            report.loadError ??
                '${report.failedStudents} failed · ${report.perfectAttendanceStudents} perfect attendance',
            style: AppTextStyles.bodySmall.copyWith(color: textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: report.attendanceRate / 100,
                    minHeight: 10,
                    backgroundColor: AppColors.surfaceStrongOf(context),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isSelected ? 'Opened' : 'Open',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryOf(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedGroupSummary extends StatelessWidget {
  final _GroupReport report;

  const _SelectedGroupSummary({required this.report});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          _SummaryPill(
            label: 'Attendance',
            value: '${report.attendanceRate.round()}%',
            color: AppColors.primaryOf(context),
          ),
          _SummaryPill(
            label: 'Students',
            value: '${report.studentReports.length}',
            color: AppColors.textPrimaryOf(context),
          ),
          _SummaryPill(
            label: 'Failed',
            value: '${report.failedStudents}',
            color: AppColors.accentStrongOf(context),
          ),
          _SummaryPill(
            label: 'Perfect',
            value: '${report.perfectAttendanceStudents}',
            color: AppColors.primaryStrongOf(context),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimaryOf(context),
          ),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentReportTable extends StatelessWidget {
  final List<_StudentReport> reports;
  final ValueChanged<_StudentReport> onOpenStudent;

  const _StudentReportTable({
    required this.reports,
    required this.onOpenStudent,
  });

  @override
  Widget build(BuildContext context) {
    final border = AppColors.borderOf(context);
    final surfaceStrong = AppColors.surfaceStrongOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: surfaceStrong,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusLg),
                topRight: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Student',
                    style: AppTextStyles.label.copyWith(color: textMuted),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Attendance',
                    style: AppTextStyles.label.copyWith(color: textMuted),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Average grade',
                    style: AppTextStyles.label.copyWith(color: textMuted),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: AppTextStyles.label.copyWith(color: textMuted),
                  ),
                ),
                const SizedBox(width: 90),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          ...reports.asMap().entries.map((entry) {
            final report = entry.value;
            return Column(
              children: [
                InkWell(
                  onTap: () => onOpenStudent(report),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.student.fullName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${report.attendanceRecords} attendance records · ${report.gradeCount} grades',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            report.formattedAttendanceRate,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            report.formattedAverageGrade,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _RiskBadge(report: report),
                        ),
                        SizedBox(
                          width: 90,
                          child: TextButton(
                            onPressed: () => onOpenStudent(report),
                            child: const Text('Open'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (entry.key < reports.length - 1)
                  Divider(height: 1, color: border),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _StudentReportList extends StatelessWidget {
  final List<_StudentReport> reports;
  final ValueChanged<_StudentReport> onOpenStudent;

  const _StudentReportList({
    required this.reports,
    required this.onOpenStudent,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reports.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final report = reports[index];
        return AppCard(
          onTap: () => onOpenStudent(report),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.student.fullName,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _SummaryPill(
                    label: 'Attendance',
                    value: report.formattedAttendanceRate,
                    color: AppColors.primaryOf(context),
                  ),
                  _SummaryPill(
                    label: 'Grade',
                    value: report.formattedAverageGrade,
                    color: AppColors.textPrimaryOf(context),
                  ),
                  _SummaryPill(
                    label: 'Status',
                    value: report.statusLabel,
                    color: report.isFailed
                        ? AppColors.accentStrongOf(context)
                        : report.needsAttention
                        ? AppColors.accentOf(context)
                        : AppColors.primaryStrongOf(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${report.attendanceRecords} attendance records · ${report.gradeCount} grades',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMutedOf(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final _StudentReport report;

  const _RiskBadge({required this.report});

  @override
  Widget build(BuildContext context) {
    final color = report.isFailed
        ? AppColors.accentStrongOf(context)
        : report.needsAttention
        ? AppColors.accentOf(context)
        : AppColors.primaryStrongOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        report.statusLabel,
        style: AppTextStyles.caption.copyWith(color: color),
      ),
    );
  }
}
