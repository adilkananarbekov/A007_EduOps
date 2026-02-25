import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_spacing.dart';
import '../core/providers/providers.dart';

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
      'Billing',
      '/parent/billing',
      Icons.credit_card_outlined,
      Icons.credit_card,
    ),
    _ParentNavItem(
      'Feed',
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('EduOps', style: AppTextStyles.heading4),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.mutedForeground,
                ),
                onPressed: () => context.go('/parent/announcements'),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.person_outline,
              color: AppColors.mutedForeground,
            ),
            onPressed: () => context.go('/parent/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.mutedForeground),
            onPressed: () => _handleLogout(context, ref),
            tooltip: 'Logout',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
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
    );
  }
}

class _ParentNavItem {
  final String label;
  final String route;
  final IconData icon;
  final IconData activeIcon;

  const _ParentNavItem(this.label, this.route, this.icon, this.activeIcon);
}
