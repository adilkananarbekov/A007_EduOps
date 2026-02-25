import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_spacing.dart';

enum BadgeVariant {
  active,
  archived,
  paid,
  unpaid,
  partial,
  present,
  absent,
  important,
  custom,
}

/// Status badge widget matching the EduOps design.
class AppBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final Color? customBg;
  final Color? customText;
  final Color? customBorder;

  const AppBadge({
    super.key,
    required this.text,
    this.variant = BadgeVariant.custom,
    this.customBg,
    this.customText,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.$3),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colors.$2,
        ),
      ),
    );
  }

  (Color bg, Color text, Color border) _getColors() {
    switch (variant) {
      case BadgeVariant.active:
        return (AppColors.greenBg, AppColors.greenText, AppColors.greenBorder);
      case BadgeVariant.archived:
        return (
          AppColors.muted,
          const Color(0xFF4B5563),
          const Color(0xFFD1D5DB),
        );
      case BadgeVariant.paid:
        return (AppColors.greenBg, AppColors.greenText, AppColors.greenBorder);
      case BadgeVariant.unpaid:
        return (AppColors.redBg, AppColors.redText, AppColors.redBorder);
      case BadgeVariant.partial:
        return (
          AppColors.yellowBg,
          AppColors.yellowText,
          AppColors.yellowBorder,
        );
      case BadgeVariant.present:
        return (AppColors.greenBg, AppColors.greenText, AppColors.greenBorder);
      case BadgeVariant.absent:
        return (AppColors.redBg, AppColors.redText, AppColors.redBorder);
      case BadgeVariant.important:
        return (AppColors.redBg, AppColors.primary, AppColors.redBorder);
      case BadgeVariant.custom:
        return (
          customBg ?? AppColors.muted,
          customText ?? AppColors.foreground,
          customBorder ?? AppColors.border,
        );
    }
  }
}
