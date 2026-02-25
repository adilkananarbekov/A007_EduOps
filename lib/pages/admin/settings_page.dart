import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../widgets/page_header.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _orgName = TextEditingController(text: 'EduOps Academy');
  final _email = TextEditingController(text: 'admin@eduops.kg');
  final _phone = TextEditingController(text: '+996 700 000 000');
  String _timezone = 'Asia/Bishkek (GMT+6)';
  String _currency = 'KGS (₸)';
  String _language = 'Russian';
  int _attendanceWindow = 15;
  bool _notifyAttendance = true;
  bool _notifyPayments = true;
  bool _notifySchedule = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'Settings',
          subtitle: 'Configure your institution settings',
          actions: [
            ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved successfully')),
              ),
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Save'),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Section(
                    title: 'Organization',
                    children: [
                      _Field(
                        'Institution Name',
                        _orgName,
                        Icons.business_outlined,
                      ),
                      _Field('Email', _email, Icons.email_outlined),
                      _Field('Phone', _phone, Icons.phone_outlined),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _Section(
                    title: 'Regional',
                    children: [
                      _DropdownField('Timezone', _timezone, [
                        'Asia/Bishkek (GMT+6)',
                        'UTC',
                        'Europe/Moscow (GMT+3)',
                      ], (v) => setState(() => _timezone = v!)),
                      _DropdownField('Currency', _currency, [
                        'KGS (₸)',
                        'USD (\$)',
                        'EUR (€)',
                      ], (v) => setState(() => _currency = v!)),
                      _DropdownField('Language', _language, [
                        'Russian',
                        'Kyrgyz',
                        'English',
                      ], (v) => setState(() => _language = v!)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _Section(
                    title: 'Attendance',
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attendance Window (minutes)',
                              style: AppTextStyles.label,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Teachers can mark attendance $_attendanceWindow min after class starts',
                              style: AppTextStyles.bodySmall,
                            ),
                            Slider(
                              value: _attendanceWindow.toDouble(),
                              min: 5,
                              max: 60,
                              divisions: 11,
                              label: '$_attendanceWindow min',
                              activeColor: AppColors.primary,
                              onChanged: (v) =>
                                  setState(() => _attendanceWindow = v.round()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _Section(
                    title: 'Notifications',
                    children: [
                      _Toggle(
                        'Attendance Alerts',
                        'Notify when attendance drops below threshold',
                        _notifyAttendance,
                        (v) => setState(() => _notifyAttendance = v),
                      ),
                      _Toggle(
                        'Payment Reminders',
                        'Send reminders for unpaid invoices',
                        _notifyPayments,
                        (v) => setState(() => _notifyPayments = v),
                      ),
                      _Toggle(
                        'Schedule Changes',
                        'Notify on schedule updates',
                        _notifySchedule,
                        (v) => setState(() => _notifySchedule = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.heading4),
        const SizedBox(height: AppSpacing.md),
        ...children.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: c,
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  const _Field(this.label, this.controller, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
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

class _DropdownField extends StatelessWidget {
  final String label, value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  const _DropdownField(this.label, this.value, this.options, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
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

class _Toggle extends StatelessWidget {
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle(this.title, this.subtitle, this.value, this.onChanged);

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
