import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/class_group.dart';
import '../../core/models/student.dart';
import '../../core/models/attendance.dart';
import '../../core/models/schedule.dart';
import '../../core/providers/providers.dart';
import '../../widgets/page_header.dart';

class AttendanceMarkingPage extends ConsumerStatefulWidget {
  final String? groupId;
  const AttendanceMarkingPage({super.key, this.groupId});

  @override
  ConsumerState<AttendanceMarkingPage> createState() =>
      _AttendanceMarkingPageState();
}

class _AttendanceMarkingPageState extends ConsumerState<AttendanceMarkingPage> {
  List<ClassGroup> _groups = [];
  List<Student> _currentStudents = [];
  List<Schedule> _groupSchedules = [];
  ClassGroup? _selectedGroup;
  Schedule? _selectedSchedule;
  final Map<int, String> _attendance = {}; // studentId -> status
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  static const _statuses = ['PRESENT', 'ABSENT', 'LATE', 'EXCUSED'];
  static final _statusColors = {
    'PRESENT': AppColors.greenText,
    'ABSENT': AppColors.primary,
    'LATE': AppColors.yellowText,
    'EXCUSED': AppColors.accent,
  };

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
        _isLoading = false;
        _errorMessage = null;
      });
      if (_selectedGroup != null) {
        await _loadSchedulesForGroup(_selectedGroup!.id);
        await _loadStudentsForGroup(_selectedGroup!.id);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load groups: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadStudentsForGroup(int groupId) async {
    try {
      final adminService = ref.read(adminServiceProvider);
      final students = await adminService.getStudentsByClass(groupId);
      setState(() {
        _currentStudents = students;
        _attendance.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load students: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadSchedulesForGroup(int groupId) async {
    try {
      final scheduleService = ref.read(scheduleServiceProvider);
      final schedules = await scheduleService.getClassSchedule(groupId);
      setState(() {
        _groupSchedules = schedules;
        _selectedSchedule = schedules.isNotEmpty ? schedules.first : null;
      });
    } catch (e) {
      setState(() {
        _groupSchedules = [];
        _selectedSchedule = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load schedules: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedGroup == null ||
        _attendance.isEmpty ||
        _selectedSchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a lesson and attendance for at least one student',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final attendanceService = ref.read(attendanceServiceProvider);
      final scheduleId = _selectedSchedule!.id;

      for (final entry in _attendance.entries) {
        final studentId = entry.key;
        final status = entry.value;

        await attendanceService.markAttendance(
          studentId: studentId,
          scheduleId: scheduleId,
          date: DateTime.now(),
          status: AttendanceStatus.values.firstWhere(
            (e) => e.name == status,
            orElse: () => AttendanceStatus.PRESENT,
          ),
          notes: null,
        );
      }

      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance saved for ${_selectedGroup!.name}'),
            backgroundColor: AppColors.greenText,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save attendance: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'Mark Attendance',
          subtitle: 'Select group and mark attendance for today',
          actions: [
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAttendance,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 16),
              label: const Text('Save'),
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
                // Group selector
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Text('Group:', style: AppTextStyles.label),
                      const SizedBox(width: AppSpacing.md),
                      DropdownButton<ClassGroup>(
                        value: _selectedGroup,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
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
                            _loadSchedulesForGroup(v.id);
                            _loadStudentsForGroup(v.id);
                          }
                        },
                      ),
                      const Spacer(),
                      Text(
                        '${_currentStudents.length} students',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Text('Lesson:', style: AppTextStyles.label),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: DropdownButton<Schedule>(
                          value: _selectedSchedule,
                          isExpanded: true,
                          hint: const Text('Select lesson'),
                          items: _groupSchedules
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    '${s.dayOfWeek} · ${s.startTime}-${s.endTime} · ${s.subjectName}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedSchedule = v),
                        ),
                      ),
                    ],
                  ),
                ),
                // Legend
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: _statuses
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.md,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _statusColors[s],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(s, style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                // Students list
                Expanded(
                  child: _currentStudents.isEmpty
                      ? Center(
                          child: Text(
                            'No students in this group',
                            style: AppTextStyles.bodyMedium,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: _currentStudents.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (_, i) {
                            final student = _currentStudents[i];
                            final current = _attendance[student.id];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.muted,
                                    child: Text(
                                      student.firstName[0].toUpperCase(),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.fullName,
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        Text(
                                          student.phoneNumber ?? 'N/A',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color:
                                                    AppColors.mutedForeground,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Wrap(
                                    spacing: AppSpacing.xs,
                                    children: _statuses.map((s) {
                                      final isSelected = current == s;
                                      return ChoiceChip(
                                        label: Text(
                                          s,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isSelected
                                                ? Colors.white
                                                : _statusColors[s],
                                          ),
                                        ),
                                        selected: isSelected,
                                        onSelected: (_) => setState(
                                          () => _attendance[student.id] = s,
                                        ),
                                        selectedColor: _statusColors[s],
                                        backgroundColor: _statusColors[s]!
                                            .withValues(alpha: 0.08),
                                        side: BorderSide(
                                          color: _statusColors[s]!.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
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
