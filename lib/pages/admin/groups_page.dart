import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/class_group.dart';
import '../../core/providers/providers.dart';
import '../../widgets/page_header.dart';
import '../../widgets/app_badge.dart';

class GroupsPage extends ConsumerStatefulWidget {
  const GroupsPage({super.key});

  @override
  ConsumerState<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends ConsumerState<GroupsPage> {
  List<ClassGroup> _groups = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      final adminService = ref.read(adminServiceProvider);
      final groups = await adminService.getClassGroups();
      setState(() {
        _groups = groups;
        _isLoading = false;
        _errorMessage = null;
      });
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

  Future<void> _showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final gradeController = TextEditingController();
    final monthlyFeeController = TextEditingController();

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Group Name'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: gradeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Grade'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: monthlyFeeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monthly Fee (₸)'),
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
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (shouldCreate != true || !mounted) return;
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Group name is required')));
      return;
    }

    try {
      final adminService = ref.read(adminServiceProvider);
      await adminService.createClassGroup(
        name: nameController.text.trim(),
        grade: int.tryParse(gradeController.text.trim()),
        monthlyFee: int.tryParse(monthlyFeeController.text.trim()),
      );
      await _loadGroups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'Groups',
          subtitle: '${_groups.length} total groups',
          actions: [
            ElevatedButton.icon(
              onPressed: _showCreateGroupDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Group'),
            ),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _groups.isEmpty
              ? Center(
                  child: Text(
                    'No groups found',
                    style: AppTextStyles.bodyMedium,
                  ),
                )
              : LayoutBuilder(
                  builder: (ctx, constraints) {
                    final cols = constraints.maxWidth > 900
                        ? 3
                        : constraints.maxWidth > 600
                        ? 2
                        : 1;
                    return GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        childAspectRatio: 1.6,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                      ),
                      itemCount: _groups.length,
                      itemBuilder: (_, i) => _GroupCard(group: _groups[i]),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final ClassGroup group;
  const _GroupCard({required this.group});

  String _formatFee(int? fee) {
    if (fee == null) return '₸0';
    return NumberFormat.currency(symbol: '₸', decimalDigits: 0).format(fee);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        color: AppColors.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  group.name,
                  style: AppTextStyles.heading4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppBadge(text: 'Active', variant: BadgeVariant.active),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Grade ${group.grade?.toString() ?? '-'} · ${_formatFee(group.monthlyFee)}/month',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.mutedForeground,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                size: 14,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${group.studentCount ?? 0} students',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
