import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/class_group.dart';
import '../../core/models/student.dart';
import '../../core/providers/providers.dart';
import '../../widgets/page_header.dart';

class StudentsListPage extends ConsumerStatefulWidget {
  const StudentsListPage({super.key});

  @override
  ConsumerState<StudentsListPage> createState() => _StudentsListPageState();
}

class _StudentsListPageState extends ConsumerState<StudentsListPage> {
  final _searchController = TextEditingController();
  List<Student> _students = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final adminService = ref.read(adminServiceProvider);
      final students = await adminService.getStudents();
      setState(() {
        _students = students;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load students: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Student> get _filtered {
    var list = _students;
    // Note: Backend doesn't have "active" field, so we show all students
    final q = _searchController.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (s) =>
                s.fullName.toLowerCase().contains(q) ||
                (s.classGroupName?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    return list;
  }

  void _handleAddStudent() {
    _showAddStudentDialog();
  }

  Future<void> _showAddStudentDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    int? selectedClassGroupId;

    final adminService = ref.read(adminServiceProvider);
    List<ClassGroup> groups = [];
    try {
      groups = await adminService.getClassGroups();
    } catch (_) {
      // Allow creating student without group if groups fail to load.
    }

    if (!mounted) return;

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<int?>(
                  initialValue: selectedClassGroupId,
                  decoration: const InputDecoration(
                    labelText: 'Class Group (optional)',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Unassigned'),
                    ),
                    ...groups.map(
                      (group) => DropdownMenuItem<int?>(
                        value: group.id,
                        child: Text(group.name),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedClassGroupId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (shouldCreate != true) return;

    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All required fields must be filled')),
        );
      }
      return;
    }

    try {
      await adminService.createStudent(
        email: emailController.text.trim(),
        password: passwordController.text,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        classGroupId: selectedClassGroupId,
      );
      await _loadStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create student: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'Students',
          subtitle: '${_students.length} total students',
          actions: [
            ElevatedButton.icon(
              onPressed: _handleAddStudent,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Student'),
            ),
          ],
        ),
        // Search + Filter
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search students…',
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.mutedForeground,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
              ? Center(
                  child: Text(
                    'No students found',
                    style: AppTextStyles.bodyMedium,
                  ),
                )
              : LayoutBuilder(
                  builder: (ctx, constraints) {
                    if (constraints.maxWidth > 700) {
                      return _DesktopStudentTable(students: _filtered);
                    }
                    return _MobileStudentList(students: _filtered);
                  },
                ),
        ),
      ],
    );
  }
}

class _DesktopStudentTable extends StatelessWidget {
  final List<Student> students;
  const _DesktopStudentTable({required this.students});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            children: [
              // Header
              Container(
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
                    Expanded(
                      flex: 3,
                      child: Text('Name', style: AppTextStyles.label),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Group', style: AppTextStyles.label),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Phone', style: AppTextStyles.label),
                    ),
                    const SizedBox(width: 60),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              ...students.asMap().entries.map((e) {
                final s = e.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.muted,
                                  child: Text(
                                    s.firstName[0].toUpperCase(),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    s.fullName,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              s.classGroupName ?? 'No Group',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              s.phoneNumber ?? 'N/A',
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: TextButton(
                              onPressed: () =>
                                  context.go('/admin/students/${s.id}'),
                              child: const Text('View'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (e.key < students.length - 1)
                      const Divider(height: 1, color: AppColors.border),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileStudentList extends StatelessWidget {
  final List<Student> students;
  const _MobileStudentList({required this.students});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        final s = students[i];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.muted,
                child: Text(
                  s.firstName[0].toUpperCase(),
                  style: AppTextStyles.bodyLarge.copyWith(
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
                      s.fullName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      s.classGroupName ?? 'No Group',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.go('/admin/students/${s.id}'),
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
