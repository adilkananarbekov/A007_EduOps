import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/providers.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/page_header.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  bool _isLoading = true;
  int _totalStudents = 0;
  int _activeGroups = 0;
  String _todayAttendance = '—';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final adminService = ref.read(adminServiceProvider);
      final attendanceService = ref.read(attendanceServiceProvider);

      // Run API calls in parallel so one failure doesn't block others
      final results = await Future.wait([
        adminService.getStudents().then<dynamic>((v) => v).catchError((e) {
          debugPrint('[DASHBOARD] getStudents error: $e');
          return <dynamic>[];
        }),
        adminService.getClassGroups().then<dynamic>((v) => v).catchError((e) {
          debugPrint('[DASHBOARD] getClassGroups error: $e');
          return <dynamic>[];
        }),
        attendanceService
            .getAttendanceByRange(
              startDate: DateTime.now(),
              endDate: DateTime.now(),
            )
            .then<dynamic>((v) => v)
            .catchError((e) {
              debugPrint('[DASHBOARD] getAttendanceByRange error: $e');
              return <dynamic>[];
            }),
      ]);

      final students = results[0] as List;
      final groups = results[1] as List;
      final todayAttendance = results[2] as List;

      final presentCount = todayAttendance
          .where((record) => record.status.name == 'PRESENT')
          .length;
      final attendanceRate = todayAttendance.isEmpty
          ? '—'
          : '${((presentCount / todayAttendance.length) * 100).round()}%';

      setState(() {
        _totalStudents = students.length;
        _activeGroups = groups.length;
        _todayAttendance = attendanceRate;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('[DASHBOARD] Unexpected error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        title: 'Total Students',
        value: _isLoading ? '...' : _totalStudents.toString(),
        icon: Icons.people,
        trend: '',
        trendUp: true,
      ),
      (
        title: "Today's Attendance",
        value: _isLoading ? '...' : _todayAttendance,
        icon: Icons.check_circle_outline,
        trend: 'Attendance tracking',
        trendUp: true,
      ),
      (
        title: 'Active Groups',
        value: _isLoading ? '...' : _activeGroups.toString(),
        icon: Icons.groups_outlined,
        trend: '',
        trendUp: true,
      ),
      (
        title: 'Outstanding Fees',
        value: '—',
        icon: Icons.credit_card_outlined,
        trend: 'Check billing',
        trendUp: false,
      ),
    ];

    return Column(
      children: [
        PageHeader(
          title: 'Dashboard',
          subtitle: 'Overview of your educational institution',
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.go('/admin/reports'),
              icon: const Icon(Icons.bar_chart, size: 16),
              label: const Text('Reports'),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metrics Grid
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    final cols = constraints.maxWidth > 600 ? 4 : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                      ),
                      itemCount: metrics.length,
                      itemBuilder: (ctx, i) {
                        final m = metrics[i];
                        return MetricCard(
                          title: m.title,
                          value: m.value,
                          icon: m.icon,
                          trend: m.trend,
                          trendUp: m.trendUp,
                          highlight: i == 3,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Quick Actions
                Text('Quick Actions', style: AppTextStyles.heading4),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _QuickAction(
                      'Mark Attendance',
                      Icons.check_circle_outline,
                      () => context.go('/admin/attendance'),
                    ),
                    _QuickAction(
                      'View Schedule',
                      Icons.calendar_today_outlined,
                      () => context.go('/admin/schedule'),
                    ),
                    _QuickAction(
                      'Student List',
                      Icons.people_outlined,
                      () => context.go('/admin/students'),
                    ),
                    _QuickAction(
                      'Billing',
                      Icons.credit_card_outlined,
                      () => context.go('/admin/billing'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction(this.label, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}
