import 'package:flutter/material.dart';

import '../core/config/app_runtime_config.dart';
import '../core/constants/app_spacing.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class DemoModeBanner extends StatelessWidget {
  final bool compact;
  final bool showApiHost;

  const DemoModeBanner({
    super.key,
    this.compact = false,
    this.showApiHost = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!AppRuntimeConfig.isTestMode) {
      return const SizedBox.shrink();
    }

    final primary = AppColors.primaryOf(context);
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textMuted = AppColors.textMutedOf(context);

    final label = compact
        ? AppRuntimeConfig.environmentLabel
        : '${AppRuntimeConfig.environmentLabel} · demo data only';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.science_outlined, size: compact ? 14 : 16, color: primary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              showApiHost ? '$label · ${AppRuntimeConfig.apiBaseUrl}' : label,
              style: AppTextStyles.caption.copyWith(
                color: compact ? primary : textMuted,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
