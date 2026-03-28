import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/attendance.dart';
import '../../core/models/class_group.dart';
import '../../core/models/schedule.dart';
import '../../core/models/student.dart';
import '../../core/models/user_role.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/page_header.dart';

class AttendanceOverviewPage extends ConsumerStatefulWidget {
  final String? groupId;

  const AttendanceOverviewPage({super.key, this.groupId});

  @override
  ConsumerState<AttendanceOverviewPage> createState() =>
      _AttendanceOverviewPageState();
}

class _AttendanceOverviewPageState
    extends ConsumerState<AttendanceOverviewPage> {
  List<ClassGroup> _groups = [];
  List<Student> _currentStudents = [];
  List<Schedule> _allSchedules = [];
  ClassGroup? _selectedGroup;
  Schedule? _selectedSchedule;
  Map<int, Attendance> _savedAttendanceByStudent = {};
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  String? _savedMarkedByName;
  DateTime? _savedMarkedAt;
  bool _limitedToTeacherSchedule = false;
  bool _isLoading = true;
  bool _isLoadingSavedAttendance = false;
  String? _errorMessage;

  static const _statuses = ['PRESENT', 'ABSENT', 'LATE', 'EXCUSED'];
  static final _statusColors = {
    'PRESENT': AppColors.greenText,
    'ABSENT': AppColors.primary,
    'LATE': AppColors.yellowText,
    'EXCUSED': AppColors.accent,
  };

  bool get _hasSavedAttendance => _savedAttendanceByStudent.isNotEmpty;

  int get _markedCount => _savedAttendanceByStudent.length;

  int get _unmarkedCount => (_currentStudents.length - _markedCount).clamp(
    0,
    9999,
  );

  bool get _isFullyMarked =>
      _hasSavedAttendance &&
      _currentStudents.isNotEmpty &&
      _markedCount >= _currentStudents.length;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = ref.read(currentUserProvider);
      final requestedGroupId = int.tryParse(widget.groupId ?? '');
      if (currentUser?.role == UserRole.TEACHER) {
        await _loadTeacherScopedData(requestedGroupId: requestedGroupId);
      } else {
        final adminService = ref.read(adminServiceProvider);
        final scheduleService = ref.read(scheduleServiceProvider);
        final groups = await adminService.getClassGroups();
        final scheduleGroups = await Future.wait(
          groups.map((group) => scheduleService.getClassSchedule(group.id)),
        );
        final allSchedules = scheduleGroups.expand((item) => item).toList()
          ..sort(_compareSchedules);
        if (!mounted) {
          return;
        }

        final selectedSchedule = _pickInitialSchedule(
          allSchedules,
          requestedGroupId: requestedGroupId,
        );
        final selectedGroup = selectedSchedule != null
            ? _findGroupById(selectedSchedule.classGroupId, groups)
            : null;

        setState(() {
          _groups = groups;
          _allSchedules = allSchedules;
          _limitedToTeacherSchedule = false;
          _selectedGroup = selectedGroup;
          _selectedSchedule = selectedSchedule;
          _errorMessage = null;
        });

        if (selectedSchedule != null) {
          await _applyScheduleSelection(selectedSchedule);
        }
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Failed to load attendance setup: ${e.toString()}';
      });
      _showSnack(_errorMessage!, backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTeacherScopedData({int? requestedGroupId}) async {
    final scheduleService = ref.read(scheduleServiceProvider);
    final schedules = await scheduleService.getWeeklySchedule()
      ..sort(_compareSchedules);
    final groupsById = <int, ClassGroup>{};

    for (final schedule in schedules) {
      groupsById[schedule.classGroupId] = ClassGroup(
        id: schedule.classGroupId,
        name: schedule.classGroupName ?? 'Group #${schedule.classGroupId}',
      );
    }

    final groups = groupsById.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final selectedSchedule = _pickInitialSchedule(
      schedules,
      requestedGroupId: requestedGroupId,
    );
    final selectedGroup = selectedSchedule != null
        ? _findGroupById(selectedSchedule.classGroupId, groups)
        : null;

    if (!mounted) {
      return;
    }

    setState(() {
      _groups = groups;
      _allSchedules = schedules;
      _selectedGroup = selectedGroup;
      _selectedSchedule = selectedSchedule;
      _limitedToTeacherSchedule = true;
      _errorMessage = null;
    });

    if (selectedSchedule != null) {
      await _applyScheduleSelection(selectedSchedule);
    }
  }

  Future<void> _applyScheduleSelection(Schedule schedule) async {
    await _applyScheduleSelectionForDate(
      schedule,
      _alignDateToSchedule(_selectedDate, schedule),
    );
  }

  Future<void> _applyScheduleSelectionForDate(
    Schedule schedule,
    DateTime date,
  ) async {
    final matchedGroup = _findGroupById(schedule.classGroupId, _groups) ??
        ClassGroup(
          id: schedule.classGroupId,
          name: schedule.classGroupName ?? 'Group #${schedule.classGroupId}',
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedSchedule = schedule;
      _selectedGroup = matchedGroup;
      _selectedDate = DateUtils.dateOnly(date);
      _currentStudents = [];
      _savedAttendanceByStudent = {};
      _savedMarkedByName = null;
      _savedMarkedAt = null;
    });

    await _loadStudentsForGroup(matchedGroup.id);
    await _loadExistingAttendance();
  }

  Future<void> _loadStudentsForGroup(int groupId) async {
    try {
      final adminService = ref.read(adminServiceProvider);
      final students = await adminService.getStudentsByClass(groupId);
      if (!mounted) {
        return;
      }
      setState(() {
        _currentStudents = students;
      });
    } catch (e) {
      _showSnack(
        'Failed to load students: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _loadExistingAttendance() async {
    final selectedSchedule = _selectedSchedule;
    if (selectedSchedule == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _savedAttendanceByStudent = {};
        _savedMarkedByName = null;
        _savedMarkedAt = null;
        _isLoadingSavedAttendance = false;
      });
      return;
    }

    final requestedScheduleId = selectedSchedule.id;
    final requestedDate = _selectedDate;

    setState(() {
      _savedAttendanceByStudent = {};
      _savedMarkedByName = null;
      _savedMarkedAt = null;
      _isLoadingSavedAttendance = true;
    });

    try {
      final attendanceService = ref.read(attendanceServiceProvider);
      final records = await attendanceService.getScheduleAttendance(
        scheduleId: requestedScheduleId,
        date: requestedDate,
      );

      if (!mounted ||
          _selectedSchedule?.id != requestedScheduleId ||
          !DateUtils.isSameDay(_selectedDate, requestedDate)) {
        return;
      }

      _applyLoadedAttendance(records);
    } on NotFoundException {
      if (!mounted ||
          _selectedSchedule?.id != requestedScheduleId ||
          !DateUtils.isSameDay(_selectedDate, requestedDate)) {
        return;
      }
      setState(() {
        _savedAttendanceByStudent = {};
        _savedMarkedByName = null;
        _savedMarkedAt = null;
        _isLoadingSavedAttendance = false;
      });
    } catch (e) {
      if (!mounted ||
          _selectedSchedule?.id != requestedScheduleId ||
          !DateUtils.isSameDay(_selectedDate, requestedDate)) {
        return;
      }
      setState(() => _isLoadingSavedAttendance = false);
      _showSnack(
        'Failed to load saved attendance: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  void _applyLoadedAttendance(List<Attendance> records) {
    final savedByStudent = <int, Attendance>{};
    DateTime? latestMarkedAt;
    String? markedByName;

    for (final record in records) {
      savedByStudent[record.studentId] = record;
      if (record.markedAt != null &&
          (latestMarkedAt == null ||
              record.markedAt!.isAfter(latestMarkedAt))) {
        latestMarkedAt = record.markedAt;
      }
      markedByName ??= record.markedByName;
    }

    setState(() {
      _savedAttendanceByStudent = savedByStudent;
      _savedMarkedAt = latestMarkedAt;
      _savedMarkedByName = markedByName;
      _isLoadingSavedAttendance = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Review attendance for date',
    );
    if (picked == null) {
      return;
    }

    await _handleDateChange(DateUtils.dateOnly(picked));
  }

  Future<void> _jumpToToday() async {
    await _handleDateChange(DateUtils.dateOnly(DateTime.now()));
  }

  Future<void> _handleDateChange(DateTime date) async {
    if (DateUtils.isSameDay(date, _selectedDate)) {
      return;
    }

    final matchedSchedule = _pickInitialSchedule(
      _allSchedules,
      requiredDayOfWeek: _weekdayName(date),
      requestedGroupId: _selectedGroup?.id,
    );

    if (matchedSchedule != null && matchedSchedule.id != _selectedSchedule?.id) {
      await _applyScheduleSelectionForDate(matchedSchedule, date);
      return;
    }

    setState(() => _selectedDate = date);
    await _loadExistingAttendance();
  }

  void _openMarkingPage() {
    final selectedSchedule = _selectedSchedule;
    final selectedGroup = _selectedGroup;
    if (selectedSchedule == null || selectedGroup == null) {
      return;
    }

    final route = Uri(
      path: '/admin/attendance/mark',
      queryParameters: {
        'scheduleId': '${selectedSchedule.id}',
        'groupId': '${selectedGroup.id}',
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      },
    ).toString();
    context.push(route);
  }

  void _showSnack(String message, {required Color backgroundColor}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  String _formattedDate(DateTime date) {
    return DateFormat('EEE, d MMM yyyy').format(date);
  }

  String _formattedTimestamp(DateTime timestamp) {
    return DateFormat('d MMM, HH:mm').format(timestamp.toLocal());
  }

  ClassGroup? _findGroupById(int id, List<ClassGroup> groups) {
    for (final group in groups) {
      if (group.id == id) {
        return group;
      }
    }
    return null;
  }

  Schedule? _pickInitialSchedule(
    List<Schedule> schedules, {
    int? requestedGroupId,
    String? requiredDayOfWeek,
  }) {
    if (schedules.isEmpty) {
      return null;
    }

    final normalizedDay = requiredDayOfWeek?.trim().toUpperCase();
    final preferredToday = _weekdayName(DateTime.now());

    final candidates = schedules.where((schedule) {
      if (requestedGroupId != null && schedule.classGroupId != requestedGroupId) {
        return false;
      }
      if (normalizedDay != null &&
          schedule.dayOfWeek.trim().toUpperCase() != normalizedDay) {
        return false;
      }
      return true;
    }).toList()
      ..sort(_compareSchedules);

    if (candidates.isNotEmpty) {
      for (final schedule in candidates) {
        if (schedule.dayOfWeek.trim().toUpperCase() == preferredToday) {
          return schedule;
        }
      }
      return candidates.first;
    }

    if (requestedGroupId != null || normalizedDay != null) {
      return _pickInitialSchedule(schedules);
    }

    return schedules.first;
  }

  int _compareSchedules(Schedule a, Schedule b) {
    final weekdayCompare = _weekdayOrder(a.dayOfWeek).compareTo(
      _weekdayOrder(b.dayOfWeek),
    );
    if (weekdayCompare != 0) {
      return weekdayCompare;
    }

    final timeCompare = a.startTime.compareTo(b.startTime);
    if (timeCompare != 0) {
      return timeCompare;
    }

    final groupCompare = (a.classGroupName ?? '')
        .toLowerCase()
        .compareTo((b.classGroupName ?? '').toLowerCase());
    if (groupCompare != 0) {
      return groupCompare;
    }

    return a.subjectName.toLowerCase().compareTo(b.subjectName.toLowerCase());
  }

  int _weekdayOrder(String value) {
    switch (value.trim().toUpperCase()) {
      case 'MONDAY':
        return DateTime.monday;
      case 'TUESDAY':
        return DateTime.tuesday;
      case 'WEDNESDAY':
        return DateTime.wednesday;
      case 'THURSDAY':
        return DateTime.thursday;
      case 'FRIDAY':
        return DateTime.friday;
      case 'SATURDAY':
        return DateTime.saturday;
      case 'SUNDAY':
        return DateTime.sunday;
      default:
        return 99;
    }
  }

  String _weekdayName(DateTime date) {
    return DateFormat('EEEE').format(date).toUpperCase();
  }

  DateTime _alignDateToSchedule(DateTime baseDate, Schedule schedule) {
    final targetWeekday = _weekdayOrder(schedule.dayOfWeek);
    if (targetWeekday == 99) {
      return baseDate;
    }

    final normalizedBase = DateUtils.dateOnly(baseDate);
    final offset = (targetWeekday - normalizedBase.weekday + 7) % 7;
    return normalizedBase.add(Duration(days: offset));
  }

  String _lessonLabel(Schedule schedule) {
    final room = (schedule.room ?? '').trim();
    final roomLabel = room.isEmpty ? '' : ' · $room';
    final groupName =
        schedule.classGroupName ??
        _findGroupById(schedule.classGroupId, _groups)?.name ??
        'Group #${schedule.classGroupId}';
    return '${schedule.dayOfWeek} · ${schedule.startTime}-${schedule.endTime} · ${schedule.subjectName} · $groupName$roomLabel';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PRESENT':
        return 'Present';
      case 'ABSENT':
        return 'Absent';
      case 'LATE':
        return 'Late';
      case 'EXCUSED':
        return 'Excused';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    return _statusColors[status] ?? AppColors.primary;
  }

  int _countSavedStatus(String status) {
    return _savedAttendanceByStudent.values
        .where((record) => record.status.name == status)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final isCompactScreen = MediaQuery.sizeOf(context).width < 720;
    final statusTitle = _selectedSchedule == null
        ? 'Select a lesson first'
        : !_hasSavedAttendance
        ? 'Group not marked yet'
        : _isFullyMarked
        ? 'Group already marked'
        : 'Group partially marked';
    final statusMessage = _selectedSchedule == null
        ? 'Pick a lesson from the schedule to see whether this group was already marked.'
        : !_hasSavedAttendance
        ? 'No saved attendance was found for this lesson and date. Open the student table to mark the group.'
        : _savedMarkedAt != null
        ? 'Marked by ${_savedMarkedByName ?? 'a staff member'} on ${_formattedTimestamp(_savedMarkedAt!)}.'
        : 'Saved attendance was already found for this lesson and date.';

    return Column(
      children: [
        PageHeader(
          title: 'Attendance',
          subtitle: isCompactScreen
              ? 'Check the group status, then open the student table on a separate page.'
              : 'Select a lesson from the schedule to see whether the group was already marked. Open the student table on a separate page only when you need to edit attendance.',
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 720;
                        final selector = DropdownButton<Schedule>(
                          value: _selectedSchedule,
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          hint: const Text('Select lesson from schedule'),
                          items: _allSchedules
                              .map(
                                (schedule) => DropdownMenuItem(
                                  value: schedule,
                                  child: Text(
                                    _lessonLabel(schedule),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _applyScheduleSelection(value);
                            }
                          },
                        );

                        if (isCompact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lesson', style: AppTextStyles.label),
                              const SizedBox(height: AppSpacing.xs),
                              selector,
                              const SizedBox(height: AppSpacing.sm),
                              if (_allSchedules.isEmpty)
                                Text(
                                  'No lessons are available in the schedule yet.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.accentStrongOf(context),
                                  ),
                                ),
                              if (_limitedToTeacherSchedule)
                                Text(
                                  'Teacher view is limited to your scheduled lessons.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Text('Lesson:', style: AppTextStyles.label),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: selector),
                          ],
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 720;
                        final groupLabel =
                            _selectedGroup?.name ?? 'Select lesson';
                        final helperText = _selectedSchedule == null
                            ? 'Choose a lesson above to load the group automatically.'
                            : 'This group comes from the selected lesson.';

                        if (isCompact) {
                          return Row(
                            children: [
                              Text('Group', style: AppTextStyles.label),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  groupLabel,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_selectedSchedule != null)
                                Text(
                                  '${_currentStudents.length} students',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textMutedOf(context),
                                  ),
                                ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Text('Group:', style: AppTextStyles.label),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    groupLabel,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    helperText,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textMutedOf(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${_currentStudents.length} students',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMutedOf(context),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 720;
                        final dateControls = Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_month_outlined),
                              label: Text(_formattedDate(_selectedDate)),
                            ),
                            TextButton(
                              onPressed:
                                  DateUtils.isSameDay(
                                    _selectedDate,
                                    DateTime.now(),
                                  )
                                  ? null
                                  : _jumpToToday,
                              child: const Text('Today'),
                            ),
                          ],
                        );

                        if (isCompact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date', style: AppTextStyles.label),
                              const SizedBox(height: AppSpacing.xs),
                              dateControls,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Text('Date:', style: AppTextStyles.label),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: dateControls),
                          ],
                        );
                      },
                    ),
                  ),
                  if (_isLoadingSavedAttendance)
                    const LinearProgressIndicator(minHeight: 2),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: _hasSavedAttendance
                            ? AppColors.primarySoftOf(context)
                            : AppColors.surfaceStrongOf(context),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(color: AppColors.borderOf(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusTitle,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimaryOf(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            statusMessage,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMutedOf(context),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              _AttendanceOverviewChip(
                                label: 'Students',
                                value: '${_currentStudents.length}',
                                color: AppColors.primaryOf(context),
                              ),
                              _AttendanceOverviewChip(
                                label: 'Marked',
                                value: '$_markedCount',
                                color: AppColors.primaryOf(context),
                              ),
                              _AttendanceOverviewChip(
                                label: 'Unmarked',
                                value: '$_unmarkedCount',
                                color: AppColors.accentOf(context),
                              ),
                              for (final status in _statuses)
                                if (_countSavedStatus(status) > 0)
                                  _AttendanceOverviewChip(
                                    label: _statusLabel(status),
                                    value: '${_countSavedStatus(status)}',
                                    color: _statusColor(status),
                                  ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _selectedSchedule == null
                                  ? null
                                  : _openMarkingPage,
                              icon: const Icon(Icons.fact_check_outlined),
                              label: const Text('Mark group'),
                            ),
                          ),
                        ],
                      ),
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

class _AttendanceOverviewChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AttendanceOverviewChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
