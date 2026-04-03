import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_constants.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_card.dart';
import '../../widgets/page_header.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authNotifierProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final dropdownTextStyle = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimaryOf(context),
    );
    final supportedModules = const [
      'Students',
      'Groups',
      'Teachers',
      'Subjects',
      'Schedule',
      'Attendance',
      'Grades',
      'Announcements',
    ];

    final accountSection = AppCard(
      header: Text('Account', style: AppTextStyles.heading4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReadOnlyRow(label: 'Name', value: currentUser?.fullName ?? '—'),
          const SizedBox(height: AppSpacing.md),
          _ReadOnlyRow(label: 'Email', value: currentUser?.email ?? '—'),
          const SizedBox(height: AppSpacing.md),
          _ReadOnlyRow(
            label: 'Role',
            value: currentUser?.role.displayName ?? '—',
          ),
          const SizedBox(height: AppSpacing.md),
          _ReadOnlyRow(
            label: 'User ID',
            value: currentUser == null ? '—' : currentUser.userId.toString(),
          ),
        ],
      ),
    );

    final backendSection = AppCard(
      header: Text('Connected Backend', style: AppTextStyles.heading4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReadOnlyRow(label: 'Base API', value: ApiConstants.baseApiUrl),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Live modules',
            style: AppTextStyles.label.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: supportedModules
                .map((module) => _SupportChip(label: module))
                .toList(),
          ),
        ],
      ),
    );

    final appearanceSection = AppCard(
      header: Text('Appearance', style: AppTextStyles.heading4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Theme', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<ThemeMode>(
            initialValue: themeMode,
            style: dropdownTextStyle,
            dropdownColor: AppColors.surfaceOf(context),
            iconEnabledColor: AppColors.textMutedOf(context),
            items: [
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Light', style: dropdownTextStyle),
              ),
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('Use device', style: dropdownTextStyle),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Dark', style: dropdownTextStyle),
              ),
            ],
            onChanged: (mode) async {
              if (mode == null) {
                return;
              }
              await ref.read(themeModeProvider.notifier).setThemeMode(mode);
            },
            decoration: const InputDecoration(),
          ),
        ],
      ),
    );

    final sessionSection = AppCard(
      header: Text('Session', style: AppTextStyles.heading4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile edits are server-managed. This screen only exposes settings that the current backend supports.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMutedOf(context),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleLogout(context, ref),
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        const PageHeader(
          title: 'Settings',
          subtitle: 'Account, appearance, and backend connection.',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1080;
                final leftColumn = Column(
                  children: [
                    accountSection,
                    const SizedBox(height: AppSpacing.lg),
                    backendSection,
                  ],
                );
                final rightColumn = Column(
                  children: [
                    appearanceSection,
                    const SizedBox(height: AppSpacing.lg),
                    sessionSection,
                  ],
                );

                if (!isWide) {
                  return Column(
                    children: [
                      leftColumn,
                      const SizedBox(height: AppSpacing.lg),
                      rightColumn,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: leftColumn),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: rightColumn),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textMutedOf(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(
            value,
            maxLines: 3,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimaryOf(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportChip extends StatelessWidget {
  final String label;

  const _SupportChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrongOf(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textPrimaryOf(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
