import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/config/app_runtime_config.dart';
import '../core/constants/app_spacing.dart';
import '../core/providers/providers.dart';
import '../core/router/app_back_navigation.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/demo_mode_banner.dart';

class ParentLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const ParentLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  static const _navItems = [
    _ParentNavItem('Home', '/parent', Icons.home_outlined, Icons.home),
    _ParentNavItem(
      'Schedule',
      '/parent/schedule',
      Icons.calendar_today_outlined,
      Icons.calendar_today,
    ),
    _ParentNavItem(
      'Records',
      '/parent/records',
      Icons.school_outlined,
      Icons.school,
    ),
    _ParentNavItem(
      'Learning',
      '/parent/learning',
      Icons.menu_book_outlined,
      Icons.menu_book,
    ),
    _ParentNavItem(
      'Updates',
      '/parent/announcements',
      Icons.message_outlined,
      Icons.message,
    ),
  ];

  int get _currentIndex {
    for (int i = 0; i < _navItems.length; i++) {
      if (currentRoute == _navItems[i].route ||
          (_navItems[i].route != '/parent' &&
              currentRoute.startsWith(_navItems[i].route))) {
        return i;
      }
    }
    return 0;
  }

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
    final canGoBack = AppBackNavigation.canGoBack(context, currentRoute);
    final fallbackRoute = AppBackNavigation.fallbackFor(currentRoute);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showBottomLabels = screenWidth >= 390;
    final surface = AppColors.surfaceOf(context);
    final canvas = AppColors.canvasOf(context);
    final border = AppColors.borderOf(context);
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);

    if (screenWidth >= 1024) {
      return _ParentDesktopLayout(currentRoute: currentRoute, child: child);
    }

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && fallbackRoute != null) {
          context.go(fallbackRoute);
        }
      },
      child: Scaffold(
        backgroundColor: canvas,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: canGoBack
              ? IconButton(
                  onPressed: () =>
                      AppBackNavigation.handleBack(context, currentRoute),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  tooltip: 'Back',
                )
              : null,
          titleSpacing: AppSpacing.md,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoftOf(context),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(Icons.school_rounded, color: primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EduOps',
                      style: AppTextStyles.heading4.copyWith(
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Family portal',
                      style: AppTextStyles.caption.copyWith(color: textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (AppRuntimeConfig.isTestMode && screenWidth >= 520)
              const Padding(
                padding: EdgeInsets.only(right: AppSpacing.sm),
                child: Center(child: DemoModeBanner(compact: true)),
              ),
            IconButton(
              icon: Icon(Icons.campaign_outlined, color: textMuted),
              onPressed: currentRoute == '/parent/announcements'
                  ? null
                  : () => context.push('/parent/announcements'),
            ),
            IconButton(
              icon: Icon(Icons.person_outline, color: textMuted),
              onPressed: currentRoute == '/parent/settings'
                  ? null
                  : () => context.push('/parent/settings'),
            ),
            IconButton(
              icon: Icon(Icons.logout, color: textMuted),
              onPressed: () => _handleLogout(context, ref),
              tooltip: 'Logout',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: border),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: child,
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowOf(context).withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              showSelectedLabels: showBottomLabels,
              showUnselectedLabels: showBottomLabels,
              onTap: (index) => context.go(_navItems[index].route),
              items: _navItems
                  .map(
                    (item) => BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      activeIcon: Icon(item.activeIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParentDesktopLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const _ParentDesktopLayout({required this.child, required this.currentRoute});

  bool _isActive(String route) {
    return currentRoute == route ||
        (route != '/parent' && currentRoute.startsWith(route));
  }

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
    final canvas = AppColors.canvasOf(context);
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final primary = AppColors.primaryOf(context);
    final railForeground = AppColors.railForegroundOf(context);

    return Scaffold(
      backgroundColor: canvas,
      body: Row(
        children: [
          Container(
            width: 284,
            color: canvas,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              0,
              AppSpacing.md,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.railGradientOf(context),
                  border: Border.all(color: border),
                ),
                child: SafeArea(
                  minimum: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: surface.withValues(alpha: 0.86),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoftOf(context),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.school_rounded,
                                    color: primary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'EduOps',
                                        style: AppTextStyles.heading4.copyWith(
                                          color: railForeground,
                                        ),
                                      ),
                                      Text(
                                        'Family portal',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: railForeground.withValues(
                                            alpha: 0.72,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (AppRuntimeConfig.isTestMode) ...[
                              const SizedBox(height: AppSpacing.sm),
                              const DemoModeBanner(compact: true),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ...ParentLayout._navItems.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ParentDesktopNavTile(
                            item: item,
                            isActive: _isActive(item.route),
                            onTap: () => context.go(item.route),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: surface.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primarySoftOf(context),
                              child: Text(
                                _userInitial(
                                  currentUser?.firstName,
                                  currentUser?.email,
                                ),
                                style: AppTextStyles.label.copyWith(
                                  color: primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentUser?.fullName ?? 'Student',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: railForeground,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    currentUser?.email ?? '',
                                    style: AppTextStyles.caption.copyWith(
                                      color: railForeground.withValues(
                                        alpha: 0.72,
                                      ),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _handleLogout(context, ref),
                              icon: Icon(Icons.logout, color: railForeground),
                              tooltip: 'Logout',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              minimum: const EdgeInsets.all(AppSpacing.md),
              child: Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowOf(
                        context,
                      ).withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentDesktopNavTile extends StatelessWidget {
  final _ParentNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _ParentDesktopNavTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final border = AppColors.borderOf(context);
    final railForeground = AppColors.railForegroundOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primarySoftOf(context)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: isActive ? border : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                size: 20,
                color: isActive
                    ? primary
                    : railForeground.withValues(alpha: 0.76),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isActive
                        ? primary
                        : railForeground.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _userInitial(String? name, String? email) {
  final candidates = [name, email];
  for (final candidate in candidates) {
    final trimmed = candidate?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return trimmed.substring(0, 1).toUpperCase();
    }
  }
  return 'U';
}

class _ParentNavItem {
  final String label;
  final String route;
  final IconData icon;
  final IconData activeIcon;

  const _ParentNavItem(this.label, this.route, this.icon, this.activeIcon);
}
