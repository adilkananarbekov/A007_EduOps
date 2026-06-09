import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/constants/app_spacing.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class MotionAssets {
  MotionAssets._();

  static const activity = 'assets/animations/activity.json';
  static const alert = 'assets/animations/alertTriangle.json';
  static const calendar = 'assets/animations/calendar.json';
  static const checkmark = 'assets/animations/checkmark.json';
  static const edit = 'assets/animations/edit.json';
  static const help = 'assets/animations/help.json';
  static const loading = 'assets/animations/loading.json';
  static const lock = 'assets/animations/lock.json';
  static const notification = 'assets/animations/notification.json';
  static const settings = 'assets/animations/settings.json';
  static const userPlus = 'assets/animations/userPlus.json';
}

class MotionIcon extends StatelessWidget {
  final String asset;
  final double size;
  final bool repeat;
  final bool animate;
  final BoxFit fit;

  const MotionIcon({
    super.key,
    required this.asset,
    this.size = 42,
    this.repeat = true,
    this.animate = true,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Lottie.asset(
        asset,
        repeat: repeat,
        animate: animate,
        fit: fit,
        frameRate: FrameRate.max,
      ),
    );
  }
}

class MotionLoading extends StatelessWidget {
  final String label;
  final double size;

  const MotionLoading({
    super.key,
    this.label = 'Loading workspace...',
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MotionIcon(asset: MotionAssets.loading, size: size),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMutedOf(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
