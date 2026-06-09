import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/motion_icon.dart';
import '../../widgets/page_header.dart';

class LearningPage extends ConsumerStatefulWidget {
  final bool staffMode;

  const LearningPage({super.key, this.staffMode = false});

  @override
  ConsumerState<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends ConsumerState<LearningPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _dashboard = {};
  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _tests = [];
  List<Map<String, dynamic>> _weights = [];

  @override
  void initState() {
    super.initState();
    _loadLearningData();
  }

  Future<void> _loadLearningData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final service = ref.read(learningServiceProvider);
    try {
      final results = await Future.wait([
        service.getDashboard().catchError((_) => <String, dynamic>{}),
        service.getLessons().catchError((_) => <Map<String, dynamic>>[]),
        service.getAssignments().catchError((_) => <Map<String, dynamic>>[]),
        service.getTests().catchError((_) => <Map<String, dynamic>>[]),
        service.getGradeWeights().catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as Map<String, dynamic>;
        _lessons = results[1] as List<Map<String, dynamic>>;
        _assignments = results[2] as List<Map<String, dynamic>>;
        _tests = results[3] as List<Map<String, dynamic>>;
        _weights = results[4] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load learning workspace: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.staffMode ? 'Learning Ops' : 'Learning';
    final subtitle = widget.staffMode
        ? 'Lessons, tests, assignments, and grade coefficients from the backend'
        : 'Lessons, assignments, tests, and grading rules in one place';

    return Column(
      children: [
        PageHeader(
          title: title,
          subtitle: subtitle,
          actions: [
            IconButton(
              onPressed: _loadLearningData,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh',
            ),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const MotionLoading(label: 'Loading learning workspace...')
              : _errorMessage != null
              ? _LearningError(
                  message: _errorMessage!,
                  onRetry: _loadLearningData,
                )
              : RefreshIndicator(
                  onRefresh: _loadLearningData,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _LearningHero(
                        staffMode: widget.staffMode,
                        dashboard: _dashboard,
                        lessonsCount: _lessons.length,
                        assignmentsCount: _assignments.length,
                        testsCount: _tests.length,
                        weightsCount: _weights.length,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _MetricsGrid(
                        lessonsCount: _lessons.length,
                        assignmentsCount: _assignments.length,
                        testsCount: _tests.length,
                        weightsCount: _weights.length,
                        dashboard: _dashboard,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _LearningSection(
                        title: 'Lessons',
                        emptyText: 'No lessons are available yet.',
                        icon: Icons.menu_book_outlined,
                        items: _lessons,
                        itemBuilder: (item) => _LearningItem(
                          title: _text(item, 'title', fallback: 'Lesson'),
                          meta: [
                            _text(item, 'subjectName'),
                            _text(item, 'className'),
                            _formatDate(item['lessonDate']),
                          ].where((value) => value.isNotEmpty).join(' · '),
                          description: _text(item, 'description'),
                          status: _text(item, 'teacherName'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _LearningSection(
                        title: 'Assignments',
                        emptyText: 'No assignments are available yet.',
                        icon: Icons.assignment_outlined,
                        items: _assignments,
                        itemBuilder: (item) => _LearningItem(
                          title: _text(item, 'title', fallback: 'Assignment'),
                          meta: [
                            _text(item, 'subjectName'),
                            _formatDateTime(item['dueAt'], prefix: 'Due '),
                          ].where((value) => value.isNotEmpty).join(' · '),
                          description: _text(item, 'description'),
                          status: _assignmentStatus(item),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _LearningSection(
                        title: 'Tests',
                        emptyText: 'No tests are available yet.',
                        icon: Icons.quiz_outlined,
                        items: _tests,
                        itemBuilder: (item) => _LearningItem(
                          title: _text(item, 'title', fallback: 'Test'),
                          meta: [
                            _text(item, 'subjectName'),
                            _duration(item['durationMinutes']),
                            _formatDateTime(
                              item['closesAt'],
                              prefix: 'Closes ',
                            ),
                          ].where((value) => value.isNotEmpty).join(' · '),
                          description: _text(item, 'description'),
                          status: _testStatus(item),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _LearningSection(
                        title: 'Grade Coefficients',
                        emptyText: 'No grade coefficients are configured yet.',
                        icon: Icons.percent_outlined,
                        items: _weights,
                        itemBuilder: (item) => _LearningItem(
                          title: [
                            _text(item, 'subjectName'),
                            _text(item, 'gradeType'),
                          ].where((value) => value.isNotEmpty).join(' · '),
                          meta: _coefficient(item['coefficient']),
                          description: _text(item, 'description'),
                          status: _text(item, 'className'),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  static String _text(
    Map<String, dynamic> item,
    String key, {
    String fallback = '',
  }) {
    final value = item[key]?.toString().trim();
    return value == null || value.isEmpty || value == 'null' ? fallback : value;
  }

  static String _formatDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty || raw == 'null') return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('MMM d').format(parsed);
  }

  static String _formatDateTime(dynamic value, {String prefix = ''}) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty || raw == 'null') return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '$prefix$raw';
    return '$prefix${DateFormat('MMM d, HH:mm').format(parsed.toLocal())}';
  }

  static String _duration(dynamic value) {
    final minutes = value is num ? value.toInt() : int.tryParse('$value');
    return minutes == null || minutes <= 0 ? '' : '$minutes min';
  }

  static String _coefficient(dynamic value) {
    final coefficient = value is num
        ? value.toDouble()
        : double.tryParse('$value');
    if (coefficient == null) return '';
    return 'Weight ${(coefficient * 100).round()}%';
  }

  static String _assignmentStatus(Map<String, dynamic> item) {
    final submitted = item['submitted'] == true;
    final score = item['score'];
    if (score is num) return 'Score ${score.toStringAsFixed(1)}';
    return submitted ? 'Submitted' : 'Open';
  }

  static String _testStatus(Map<String, dynamic> item) {
    final submitted = item['submitted'] == true;
    final score = item['score'];
    if (score is num) return 'Score ${score.toStringAsFixed(1)}';
    return submitted ? 'Submitted' : 'Not submitted';
  }
}

class _LearningHero extends StatelessWidget {
  final bool staffMode;
  final Map<String, dynamic> dashboard;
  final int lessonsCount;
  final int assignmentsCount;
  final int testsCount;
  final int weightsCount;

  const _LearningHero({
    required this.staffMode,
    required this.dashboard,
    required this.lessonsCount,
    required this.assignmentsCount,
    required this.testsCount,
    required this.weightsCount,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final primary = AppColors.primaryOf(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradientOf(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                staffMode ? 'TEACHING WORKSPACE' : 'STUDENT WORKSPACE',
                style: AppTextStyles.eyebrow.copyWith(color: textMuted),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                staffMode
                    ? 'Keep learning materials and assessments visible.'
                    : 'Stay on top of lessons, work, and assessments.',
                style: AppTextStyles.heading2.copyWith(color: textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Live data from lessons, tests, assignments, grade coefficients, and dashboard endpoints.',
                style: AppTextStyles.bodyMedium.copyWith(color: textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppBadge(text: '$lessonsCount lessons'),
                  AppBadge(text: '$assignmentsCount assignments'),
                  AppBadge(text: '$testsCount tests'),
                  AppBadge(text: '$weightsCount coefficients'),
                  if (dashboard['gradeAverage'] != null)
                    AppBadge(
                      text: 'Average ${dashboard['gradeAverage']}',
                      customBg: AppColors.surfaceOf(context),
                      customText: primary,
                      customBorder: AppColors.borderOf(context),
                    ),
                ],
              ),
            ],
          );

          final visual = Container(
            width: constraints.maxWidth >= 980 ? 180 : 132,
            height: constraints.maxWidth >= 980 ? 180 : 132,
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context).withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: MotionIcon(
              asset: staffMode ? MotionAssets.edit : MotionAssets.activity,
              size: constraints.maxWidth >= 980 ? 128 : 96,
            ),
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                visual,
                const SizedBox(height: AppSpacing.lg),
                copy,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: copy),
              const SizedBox(width: AppSpacing.lg),
              visual,
            ],
          );
        },
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final int lessonsCount;
  final int assignmentsCount;
  final int testsCount;
  final int weightsCount;
  final Map<String, dynamic> dashboard;

  const _MetricsGrid({
    required this.lessonsCount,
    required this.assignmentsCount,
    required this.testsCount,
    required this.weightsCount,
    required this.dashboard,
  });

  @override
  Widget build(BuildContext context) {
    final pendingTests = dashboard['pendingTests'];
    final cards = [
      (
        title: 'Lessons',
        value: '$lessonsCount',
        icon: Icons.menu_book_outlined,
      ),
      (
        title: 'Assignments',
        value: '$assignmentsCount',
        icon: Icons.assignment_outlined,
      ),
      (
        title: 'Tests',
        value: pendingTests == null
            ? '$testsCount'
            : '$testsCount / $pendingTests',
        icon: Icons.quiz_outlined,
      ),
      (
        title: 'Coefficients',
        value: '$weightsCount',
        icon: Icons.percent_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: columns == 1 ? 2.8 : 1.5,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return MetricCard(
              title: card.title,
              value: card.value,
              icon: card.icon,
              trend: 'Loaded from API',
            );
          },
        );
      },
    );
  }
}

class _LearningSection extends StatelessWidget {
  final String title;
  final String emptyText;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final Widget Function(Map<String, dynamic> item) itemBuilder;

  const _LearningSection({
    required this.title,
    required this.emptyText,
    required this.icon,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      header: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryOf(context)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ),
          AppBadge(text: items.length.toString()),
        ],
      ),
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: Text(
                  emptyText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ),
            )
          : Column(
              children: items
                  .take(8)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: itemBuilder(item),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _LearningItem extends StatelessWidget {
  final String title;
  final String meta;
  final String description;
  final String status;

  const _LearningItem({
    required this.title,
    required this.meta,
    required this.description,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final surfaceStrong = AppColors.surfaceStrongOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surfaceStrong,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isEmpty ? 'Item' : title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: AppTextStyles.bodySmall.copyWith(color: textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(color: textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          );

          final statusBadge = status.isEmpty ? null : AppBadge(text: status);
          if (constraints.maxWidth < 520 || statusBadge == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                if (statusBadge != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  statusBadge,
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: content),
              const SizedBox(width: AppSpacing.md),
              statusBadge,
            ],
          );
        },
      ),
    );
  }
}

class _LearningError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LearningError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MotionIcon(
              asset: MotionAssets.alert,
              size: 58,
              repeat: false,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
