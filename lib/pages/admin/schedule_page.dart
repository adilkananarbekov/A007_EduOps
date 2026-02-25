import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/class_group.dart';
import '../../core/models/schedule.dart';
import '../../core/providers/providers.dart';
import '../../widgets/page_header.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  bool _isWeekView = false;
  List<Schedule> _allSchedules = [];
  List<ClassGroup> _groups = [];
  ClassGroup? _selectedGroup;
  bool _isLoading = true;
  String? _errorMessage;

  static const _days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY'];
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final adminService = ref.read(adminServiceProvider);
      final groups = await adminService.getClassGroups();
      setState(() {
        _groups = groups;
        if (groups.isNotEmpty) {
          _selectedGroup = groups[0];
        }
      });

      if (_selectedGroup != null) {
        await _loadScheduleForGroup(_selectedGroup!.id);
      } else {
        await _loadWeeklyScheduleFallback();
      }
    } catch (e) {
      await _loadWeeklyScheduleFallback(
        warningMessage: 'Class groups unavailable, showing weekly schedule.',
      );
    }
  }

  Future<void> _loadWeeklyScheduleFallback({String? warningMessage}) async {
    try {
      final scheduleService = ref.read(scheduleServiceProvider);
      final schedules = await scheduleService.getWeeklySchedule();
      setState(() {
        _allSchedules = schedules;
        _groups = [];
        _selectedGroup = null;
        _isLoading = false;
        _errorMessage = null;
      });
      if (warningMessage != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(warningMessage)));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadScheduleForGroup(int groupId) async {
    try {
      final scheduleService = ref.read(scheduleServiceProvider);
      final schedules = await scheduleService.getClassSchedule(groupId);
      setState(() {
        _allSchedules = schedules;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load schedule: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleAddLesson() {
    context.go('/admin/week-schedule');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Use week schedule to add a lesson.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'Schedule',
          subtitle: 'Manage class schedules',
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.go('/admin/week-schedule'),
              icon: const Icon(Icons.calendar_view_week_outlined, size: 16),
              label: const Text('Week View'),
            ),
            ElevatedButton.icon(
              onPressed: _handleAddLesson,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Lesson'),
            ),
          ],
        ),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_errorMessage != null)
          Expanded(
            child: Center(
              child: Text(_errorMessage!, style: AppTextStyles.bodyMedium),
            ),
          )
        else
          Expanded(
            child: Column(
              children: [
                // Group selector + Toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      if (_groups.isNotEmpty) ...[
                        Text('Group:', style: AppTextStyles.label),
                        const SizedBox(width: AppSpacing.md),
                        DropdownButton<ClassGroup>(
                          value: _selectedGroup,
                          items: _groups
                              .map(
                                (g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(g.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedGroup = v);
                              _loadScheduleForGroup(v.id);
                            }
                          },
                        ),
                        const Spacer(),
                      ],
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Day View')),
                          ButtonSegment(value: true, label: Text('All Days')),
                        ],
                        selected: {_isWeekView},
                        onSelectionChanged: (s) =>
                            setState(() => _isWeekView = s.first),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isWeekView
                      ? _WeekView(
                          schedules: _allSchedules,
                          days: _days,
                          dayLabels: _dayLabels,
                        )
                      : _DayView(schedules: _allSchedules),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayView extends StatelessWidget {
  final List<Schedule> schedules;
  const _DayView({required this.schedules});

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
              'No schedule entries yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    final grouped = <String, List<Schedule>>{};
    for (final s in schedules) {
      grouped.putIfAbsent(s.dayOfWeek, () => []).add(s);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: grouped.entries.map((e) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.sm,
                top: AppSpacing.md,
              ),
              child: Text(e.key, style: AppTextStyles.heading4),
            ),
            ...e.value.map(
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
                        width: 4,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${s.classGroupName ?? 'Class'} · ${s.room ?? 'Room'}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${s.startTime} – ${s.endTime}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
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

class _WeekView extends StatelessWidget {
  final List<Schedule> schedules;
  final List<String> days;
  final List<String> dayLabels;
  const _WeekView({
    required this.schedules,
    required this.days,
    required this.dayLabels,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(days.length, (idx) {
            final day = days[idx];
            final dayLabel = dayLabels[idx];
            final daySchedules = schedules
                .where((s) => s.dayOfWeek.toUpperCase() == day)
                .toList();

            return Container(
              width: 200,
              margin: const EdgeInsets.only(right: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Center(
                      child: Text(dayLabel, style: AppTextStyles.label),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (daySchedules.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Text('No classes', style: AppTextStyles.caption),
                    )
                  else
                    ...daySchedules.map(
                      (s) => Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.subjectName,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              s.classGroupName ?? 'Class',
                              style: AppTextStyles.caption,
                            ),
                            Text(
                              '${s.startTime} – ${s.endTime}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
