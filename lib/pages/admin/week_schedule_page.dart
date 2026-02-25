import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../widgets/page_header.dart';

class WeekSchedulePage extends StatelessWidget {
  const WeekSchedulePage({super.key});

  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  static const _times = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
  ];

  static final _sessions = [
    _Session('Math', 'Gr.A', 'Mon', 1, 2),
    _Session('Physics', 'Gr.B', 'Tue', 2, 2),
    _Session('English', 'Gr.C', 'Wed', 1, 2),
    _Session('Chemistry', 'Gr.D', 'Mon', 4, 2),
    _Session('History', 'Gr.E', 'Thu', 2, 2),
    _Session('Biology', 'Gr.F', 'Fri', 3, 2),
    _Session('Math', 'Gr.B', 'Wed', 4, 2),
    _Session('Physics', 'Gr.A', 'Fri', 1, 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageHeader(
          title: 'Week Schedule',
          subtitle: 'Full weekly timetable view',
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    // Day headers
                    Row(
                      children: [
                        const SizedBox(width: 60),
                        ..._days.map(
                          (d) => Container(
                            width: 140,
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: Text(d, style: AppTextStyles.label),
                          ),
                        ),
                      ],
                    ),
                    // Time rows
                    ..._times.asMap().entries.map((te) {
                      final timeIdx = te.key;
                      final time = te.value;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 60,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.xs,
                              ),
                              child: Text(time, style: AppTextStyles.caption),
                            ),
                          ),
                          ..._days.map((day) {
                            final dayIdx = _days.indexOf(day);
                            final dayAbbr = [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                            ][dayIdx];
                            final session = _sessions
                                .where(
                                  (s) =>
                                      s.day == dayAbbr &&
                                      s.startSlot == timeIdx,
                                )
                                .firstOrNull;
                            return Container(
                              width: 140,
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.border.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: session != null
                                  ? Container(
                                      margin: const EdgeInsets.all(2),
                                      padding: const EdgeInsets.all(
                                        AppSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.08,
                                        ),
                                        border: Border.all(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            session.subject,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primary,
                                                ),
                                          ),
                                          Text(
                                            session.group,
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    )
                                  : null,
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Session {
  final String subject, group, day;
  final int startSlot, duration;
  const _Session(
    this.subject,
    this.group,
    this.day,
    this.startSlot,
    this.duration,
  );
}
