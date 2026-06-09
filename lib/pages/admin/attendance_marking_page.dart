import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/attendance.dart';
import '../../core/models/class_group.dart';
import '../../core/models/schedule.dart';
import '../../core/models/student.dart';
import '../../core/models/user_role.dart';
import '../../core/providers/providers.dart';
import '../../core/services/attendance_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AttendanceMarkingPage extends ConsumerStatefulWidget {
  final String? groupId;
  final int? initialScheduleId;
  final DateTime? initialDate;

  const AttendanceMarkingPage({
    super.key,
    this.groupId,
    this.initialScheduleId,
    this.initialDate,
  });

  @override
  ConsumerState<AttendanceMarkingPage> createState() =>
      _AttendanceMarkingPageState();
}

class _AttendanceMarkingPageState extends ConsumerState<AttendanceMarkingPage> {
  List<ClassGroup> _groups = [];
  List<Student> _currentStudents = [];
  ClassGroup? _selectedGroup;
  Schedule? _selectedSchedule;
  final Map<int, String> _attendance = {};
  Map<int, Attendance> _savedAttendanceByStudent = {};
  late DateTime _selectedDate;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingSavedAttendance = false;
  String? _errorMessage;
  late final StateController<AdminRouteLeaveGuard?> _leaveGuardController;

  static const _statuses = ['PRESENT', 'ABSENT', 'LATE', 'EXCUSED'];
  static final _statusColors = {
    'PRESENT': AppColors.greenText,
    'ABSENT': AppColors.primary,
    'LATE': AppColors.yellowText,
    'EXCUSED': AppColors.accent,
  };

  bool get _hasSavedAttendance => _savedAttendanceByStudent.isNotEmpty;
  bool get _hasUnsavedChanges {
    final trackedStudentIds = <int>{
      ..._attendance.keys,
      ..._savedAttendanceByStudent.keys,
    };

    for (final studentId in trackedStudentIds) {
      if (_attendance[studentId] !=
          _savedAttendanceByStudent[studentId]?.status.name) {
        return true;
      }
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.initialDate ?? DateTime.now());
    _leaveGuardController = ref.read(adminRouteLeaveGuardProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _leaveGuardController.state = _routeLeaveGuard;
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = ref.read(currentUserProvider);
      final requestedGroupId = int.tryParse(widget.groupId ?? '');
      final requestedScheduleId = widget.initialScheduleId;
      if (currentUser?.role == UserRole.TEACHER) {
        await _loadTeacherScopedData(
          requestedGroupId: requestedGroupId,
          requestedScheduleId: requestedScheduleId,
        );
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
          requestedScheduleId: requestedScheduleId,
        );
        final selectedGroup = selectedSchedule != null
            ? _findGroupById(selectedSchedule.classGroupId, groups)
            : null;

        setState(() {
          _groups = groups;
          _selectedGroup = selectedGroup;
          _selectedSchedule = selectedSchedule;
          _errorMessage = null;
        });

        if (selectedSchedule != null) {
          await _applyScheduleSelection(
            selectedSchedule,
            confirmDiscard: false,
          );
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

  Future<void> _loadTeacherScopedData({
    int? requestedGroupId,
    int? requestedScheduleId,
  }) async {
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
      requestedScheduleId: requestedScheduleId,
    );
    final selectedGroup = selectedSchedule != null
        ? _findGroupById(selectedSchedule.classGroupId, groups)
        : null;

    if (!mounted) {
      return;
    }

    setState(() {
      _groups = groups;
      _selectedGroup = selectedGroup;
      _selectedSchedule = selectedSchedule;
      _errorMessage = null;
    });

    if (selectedSchedule != null) {
      await _applyScheduleSelection(selectedSchedule, confirmDiscard: false);
    }
  }

  Future<void> _applyScheduleSelection(
    Schedule schedule, {
    bool confirmDiscard = true,
  }) async {
    final alignedDate = _alignDateToSchedule(_selectedDate, schedule);
    final isSameSchedule = schedule.id == _selectedSchedule?.id;
    final isSameDate = DateUtils.isSameDay(alignedDate, _selectedDate);

    if (confirmDiscard && isSameSchedule && isSameDate) {
      return;
    }

    if (confirmDiscard && !await _confirmDiscardChanges()) {
      return;
    }

    await _applyScheduleSelectionForDate(schedule, alignedDate);
  }

  Future<void> _applyScheduleSelectionForDate(
    Schedule schedule,
    DateTime date,
  ) async {
    final matchedGroup =
        _findGroupById(schedule.classGroupId, _groups) ??
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
      _attendance.clear();
      _savedAttendanceByStudent = {};
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
        _attendance.clear();
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
        _attendance.clear();
        _savedAttendanceByStudent = {};
        _isLoadingSavedAttendance = false;
      });
      return;
    }

    final requestedScheduleId = selectedSchedule.id;
    final requestedDate = _selectedDate;

    setState(() {
      _attendance.clear();
      _savedAttendanceByStudent = {};
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
        _attendance.clear();
        _savedAttendanceByStudent = {};
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

    _attendance.clear();
    for (final record in records) {
      savedByStudent[record.studentId] = record;
      _attendance[record.studentId] = record.status.name;
    }

    setState(() {
      _savedAttendanceByStudent = savedByStudent;
      _isLoadingSavedAttendance = false;
    });
  }

  Future<bool> _routeLeaveGuard(String _) {
    return _confirmDiscardChanges();
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges || !mounted) {
      return true;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave without saving?'),
        content: const Text(
          'You have unsaved attendance changes. Do you want to leave this page without saving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Leave without saving'),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
  }

  void _setAttendanceForAll(String status) {
    if (_currentStudents.isEmpty) {
      return;
    }

    setState(() {
      for (final student in _currentStudents) {
        _attendance[student.id] = status;
      }
    });
  }

  void _restoreSavedAttendance() {
    setState(() {
      _attendance.clear();
      for (final entry in _savedAttendanceByStudent.entries) {
        _attendance[entry.key] = entry.value.status.name;
      }
    });
  }

  void _clearDraft() {
    setState(() => _attendance.clear());
  }

  Future<void> _saveAttendance() async {
    if (_selectedGroup == null ||
        _attendance.isEmpty ||
        _selectedSchedule == null) {
      _showSnack(
        'Please select a lesson and mark at least one student.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final attendanceService = ref.read(attendanceServiceProvider);
      final records = await attendanceService.markAttendance(
        scheduleId: _selectedSchedule!.id,
        date: _selectedDate,
        records: _attendance.entries
            .map(
              (entry) => AttendanceMarkingRecord(
                studentId: entry.key,
                status: AttendanceStatus.values.firstWhere(
                  (value) => value.name == entry.value,
                  orElse: () => AttendanceStatus.PRESENT,
                ),
              ),
            )
            .toList(),
      );

      if (!mounted) {
        return;
      }

      _applyLoadedAttendance(records);
      setState(() => _isSaving = false);
      _showSnack(
        'Attendance saved for ${_selectedGroup!.name} on ${_formattedDate(_selectedDate)}.',
        backgroundColor: AppColors.greenText,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      _showSnack(
        'Failed to save attendance: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
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
    int? requestedScheduleId,
    String? requiredDayOfWeek,
  }) {
    if (schedules.isEmpty) {
      return null;
    }

    if (requestedScheduleId != null) {
      for (final schedule in schedules) {
        if (schedule.id == requestedScheduleId) {
          return schedule;
        }
      }
    }

    final normalizedDay = requiredDayOfWeek?.trim().toUpperCase();
    final preferredToday = _weekdayName(DateTime.now());

    final candidates = schedules.where((schedule) {
      if (requestedGroupId != null &&
          schedule.classGroupId != requestedGroupId) {
        return false;
      }
      if (normalizedDay != null &&
          schedule.dayOfWeek.trim().toUpperCase() != normalizedDay) {
        return false;
      }
      return true;
    }).toList()..sort(_compareSchedules);

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
    final weekdayCompare = _weekdayOrder(
      a.dayOfWeek,
    ).compareTo(_weekdayOrder(b.dayOfWeek));
    if (weekdayCompare != 0) {
      return weekdayCompare;
    }

    final timeCompare = a.startTime.compareTo(b.startTime);
    if (timeCompare != 0) {
      return timeCompare;
    }

    final groupCompare = (a.classGroupName ?? '').toLowerCase().compareTo(
      (b.classGroupName ?? '').toLowerCase(),
    );
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

  @override
  Widget build(BuildContext context) {
    final isCompactScreen = MediaQuery.sizeOf(context).width < 720;

    return Column(
      children: [
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
                if (_isLoadingSavedAttendance)
                  const LinearProgressIndicator(minHeight: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: isCompactScreen
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _currentStudents.isEmpty
                                    ? null
                                    : () => _setAttendanceForAll('PRESENT'),
                                icon: const Icon(
                                  Icons.done_all_outlined,
                                  size: 16,
                                ),
                                label: const Text('All present'),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              OutlinedButton.icon(
                                onPressed: _attendance.isEmpty
                                    ? null
                                    : _clearDraft,
                                icon: const Icon(
                                  Icons.layers_clear_outlined,
                                  size: 16,
                                ),
                                label: const Text('Clear draft'),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              OutlinedButton.icon(
                                onPressed: _hasSavedAttendance
                                    ? _restoreSavedAttendance
                                    : null,
                                icon: const Icon(
                                  Icons.history_outlined,
                                  size: 16,
                                ),
                                label: const Text('Restore saved'),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              ElevatedButton.icon(
                                onPressed: _isSaving ? null : _saveAttendance,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined, size: 16),
                                label: const Text('Save'),
                              ),
                            ],
                          ),
                        )
                      : Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _currentStudents.isEmpty
                                  ? null
                                  : () => _setAttendanceForAll('PRESENT'),
                              icon: const Icon(
                                Icons.done_all_outlined,
                                size: 16,
                              ),
                              label: const Text('All present'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _attendance.isEmpty
                                  ? null
                                  : _clearDraft,
                              icon: const Icon(
                                Icons.layers_clear_outlined,
                                size: 16,
                              ),
                              label: const Text('Clear draft'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _hasSavedAttendance
                                  ? _restoreSavedAttendance
                                  : null,
                              icon: const Icon(
                                Icons.history_outlined,
                                size: 16,
                              ),
                              label: const Text('Restore saved'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isSaving ? null : _saveAttendance,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined, size: 16),
                              label: const Text('Save'),
                            ),
                          ],
                        ),
                ),
                Expanded(
                  child: _currentStudents.isEmpty
                      ? Center(
                          child: Text(
                            'No students in this group',
                            style: AppTextStyles.bodyMedium,
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 920) {
                              return _AttendanceCompactTable(
                                students: _currentStudents,
                                attendance: _attendance,
                                savedAttendanceByStudent:
                                    _savedAttendanceByStudent,
                                statuses: _statuses,
                                statusLabel: _statusLabel,
                                statusColor: _statusColor,
                                onSelectStatus: (studentId, status) {
                                  setState(
                                    () => _attendance[studentId] = status,
                                  );
                                },
                              );
                            }

                            return _AttendanceMobileList(
                              students: _currentStudents,
                              attendance: _attendance,
                              savedAttendanceByStudent:
                                  _savedAttendanceByStudent,
                              statuses: _statuses,
                              statusLabel: _statusLabel,
                              statusColor: _statusColor,
                              onSelectStatus: (studentId, status) {
                                setState(() => _attendance[studentId] = status);
                              },
                              onResetStatus: (studentId) {
                                setState(() {
                                  final savedRecord =
                                      _savedAttendanceByStudent[studentId];
                                  if (savedRecord != null) {
                                    _attendance[studentId] =
                                        savedRecord.status.name;
                                  } else {
                                    _attendance.remove(studentId);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AttendanceSummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AttendanceSummaryChip({
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

class _AttendanceCompactTable extends StatelessWidget {
  final List<Student> students;
  final Map<int, String> attendance;
  final Map<int, Attendance> savedAttendanceByStudent;
  final List<String> statuses;
  final String Function(String) statusLabel;
  final Color Function(String) statusColor;
  final void Function(int studentId, String status) onSelectStatus;

  const _AttendanceCompactTable({
    required this.students,
    required this.attendance,
    required this.savedAttendanceByStudent,
    required this.statuses,
    required this.statusLabel,
    required this.statusColor,
    required this.onSelectStatus,
  });

  @override
  Widget build(BuildContext context) {
    final border = AppColors.borderOf(context);
    final surfaceStrong = AppColors.surfaceStrongOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
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
                    flex: 4,
                    child: Text(
                      'Student',
                      style: AppTextStyles.label.copyWith(color: textMuted),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Previous',
                      style: AppTextStyles.label.copyWith(color: textMuted),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      'Mark',
                      style: AppTextStyles.label.copyWith(color: textMuted),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),
            ...students.asMap().entries.map((entry) {
              final student = entry.value;
              final currentStatus = attendance[student.id];
              final savedRecord = savedAttendanceByStudent[student.id];
              final previousLabel =
                  savedRecord?.status.displayName ?? 'Not marked';
              final previousColor = savedRecord != null
                  ? statusColor(savedRecord.status.name)
                  : AppColors.accentOf(context);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: surfaceStrong,
                                child: Text(
                                  student.firstName[0].toUpperCase(),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.fullName,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if ((student.phoneNumber ?? '')
                                        .trim()
                                        .isNotEmpty)
                                      Text(
                                        student.phoneNumber!,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: textMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _AttendanceSummaryChip(
                              label: savedRecord != null ? 'Saved' : 'New',
                              value: previousLabel,
                              color: previousColor,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: statuses.map((status) {
                              final isSelected = currentStatus == status;
                              final color = statusColor(status);
                              return _AttendanceStatusButton(
                                label: statusLabel(status),
                                color: color,
                                selected: isSelected,
                                onTap: () => onSelectStatus(student.id, status),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.key < students.length - 1)
                    Divider(height: 1, color: border),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AttendanceMobileList extends StatelessWidget {
  final List<Student> students;
  final Map<int, String> attendance;
  final Map<int, Attendance> savedAttendanceByStudent;
  final List<String> statuses;
  final String Function(String) statusLabel;
  final Color Function(String) statusColor;
  final void Function(int studentId, String status) onSelectStatus;
  final void Function(int studentId) onResetStatus;

  const _AttendanceMobileList({
    required this.students,
    required this.attendance,
    required this.savedAttendanceByStudent,
    required this.statuses,
    required this.statusLabel,
    required this.statusColor,
    required this.onSelectStatus,
    required this.onResetStatus,
  });

  Future<void> _showStatusSheet(BuildContext context, Student student) async {
    final currentStatus = attendance[student.id];
    final savedRecord = savedAttendanceByStudent[student.id];
    final canReset = savedRecord != null || currentStatus != null;
    final sheetContext = context;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final textPrimary = AppColors.textPrimaryOf(context);
        final textMuted = AppColors.textMutedOf(context);

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select attendance status',
                style: AppTextStyles.heading4.copyWith(color: textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                student.fullName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                savedRecord != null
                    ? 'Saved: ${savedRecord.status.displayName}'
                    : 'No saved record for this date yet.',
                style: AppTextStyles.bodySmall.copyWith(color: textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  final buttonWidth =
                      (constraints.maxWidth - AppSpacing.sm) / 2;
                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: statuses.map((status) {
                      final color = statusColor(status);
                      return SizedBox(
                        width: buttonWidth,
                        child: _AttendanceBottomSheetButton(
                          label: statusLabel(status),
                          color: color,
                          selected: currentStatus == status,
                          onTap: () {
                            Navigator.of(context).pop();
                            onSelectStatus(student.id, status);
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: canReset
                      ? () {
                          Navigator.of(context).pop();
                          onResetStatus(student.id);
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                savedRecord != null
                                    ? 'Restored saved status for ${student.fullName}.'
                                    : 'Cleared draft mark for ${student.fullName}.',
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: Icon(
                    savedRecord != null
                        ? Icons.history_outlined
                        : Icons.layers_clear_outlined,
                  ),
                  label: Text(
                    savedRecord != null
                        ? 'Restore saved status'
                        : 'Clear current mark',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final border = AppColors.borderOf(context);
    final surface = AppColors.surfaceOf(context);
    final surfaceStrong = AppColors.surfaceStrongOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      itemCount: students.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final student = students[index];
        final currentStatus = attendance[student.id];
        final savedRecord = savedAttendanceByStudent[student.id];
        final currentColor = currentStatus != null
            ? statusColor(currentStatus)
            : AppColors.primaryOf(context);
        final currentLabel = currentStatus != null
            ? statusLabel(currentStatus)
            : 'Tap to mark';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showStatusSheet(context, student),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Ink(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: surface,
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: surfaceStrong,
                    child: Text(
                      student.firstName[0].toUpperCase(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _AttendanceSummaryChip(
                              label: 'Saved',
                              value:
                                  savedRecord?.status.displayName ??
                                  'Not marked',
                              color: savedRecord != null
                                  ? statusColor(savedRecord.status.name)
                                  : AppColors.accentOf(context),
                            ),
                            _AttendanceSummaryChip(
                              label: 'Now',
                              value: currentLabel,
                              color: currentColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Tap anywhere on this row to change the status.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.chevron_right_rounded, color: textMuted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AttendanceBottomSheetButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _AttendanceBottomSheetButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceStatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _AttendanceStatusButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
