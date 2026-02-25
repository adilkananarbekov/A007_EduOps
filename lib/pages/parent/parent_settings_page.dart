import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';

class ParentSettingsPage extends StatefulWidget {
  const ParentSettingsPage({super.key});

  @override
  State<ParentSettingsPage> createState() => _ParentSettingsPageState();
}

class _ParentSettingsPageState extends State<ParentSettingsPage> {
  final _nameController = TextEditingController(text: 'Aynura Bekova');
  final _phoneController = TextEditingController(text: '+996 700 111 222');
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  String _language = 'Russian';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Manage your account',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Avatar
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.muted,
                  child: Text(
                    'AB',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Profile section
          _SectionTitle('Profile'),
          const SizedBox(height: AppSpacing.sm),
          _SettingsField('Full Name', _nameController, Icons.person_outline),
          const SizedBox(height: AppSpacing.md),
          _SettingsField(
            'Phone Number',
            _phoneController,
            Icons.phone_outlined,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Preferences
          _SectionTitle('Preferences'),
          const SizedBox(height: AppSpacing.sm),
          _DropdownSetting('Language', _language, [
            'Russian',
            'Kyrgyz',
            'English',
          ], (v) => setState(() => _language = v!)),
          const SizedBox(height: AppSpacing.xl),

          // Notifications
          _SectionTitle('Notifications'),
          const SizedBox(height: AppSpacing.sm),
          _ToggleSetting(
            'Push Notifications',
            'Receive notifications on your device',
            _pushNotifications,
            (v) => setState(() => _pushNotifications = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ToggleSetting(
            'SMS Notifications',
            'Receive SMS for important alerts',
            _smsNotifications,
            (v) => setState(() => _smsNotifications = v),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Save
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Settings saved'))),
              child: const Text('Save Changes'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => GoRouterHelper(context).go('/login'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
extension on BuildContext {
  void go(String route) => GoRouter.of(this).go(route);
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) =>
      Text(title, style: AppTextStyles.heading4);
}

class _SettingsField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  const _SettingsField(this.label, this.controller, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.mutedForeground),
          ),
        ),
      ],
    );
  }
}

class _DropdownSetting extends StatelessWidget {
  final String label, value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  const _DropdownSetting(this.label, this.value, this.options, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          value: value,
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}

class _ToggleSetting extends StatelessWidget {
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleSetting(this.title, this.subtitle, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
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
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
