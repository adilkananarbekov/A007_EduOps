import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_spacing.dart';
import '../core/providers/providers.dart';

class AdminLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const AdminLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  static const _navItems = [
    _NavItem('Dashboard', '/admin', Icons.dashboard_outlined, Icons.dashboard),
    _NavItem(
      'Students',
      '/admin/students',
      Icons.people_outlined,
      Icons.people,
    ),
    _NavItem('Groups', '/admin/groups', Icons.groups_outlined, Icons.groups),
    _NavItem(
      'Schedule',
      '/admin/schedule',
      Icons.calendar_today_outlined,
      Icons.calendar_today,
    ),
    _NavItem(
      'Attendance',
      '/admin/attendance',
      Icons.check_circle_outline,
      Icons.check_circle,
    ),
    _NavItem(
      'Reports',
      '/admin/reports',
      Icons.bar_chart_outlined,
      Icons.bar_chart,
    ),
    _NavItem(
      'Settings',
      '/admin/settings',
      Icons.settings_outlined,
      Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        if (isDesktop) {
          return _DesktopLayout(currentRoute: currentRoute, child: child);
        }
        return _MobileLayout(currentRoute: currentRoute, child: child);
      },
    );
  }
}

// ─── Desktop (sidebar) ──────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const _DesktopLayout({required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _Sidebar(currentRoute: currentRoute),
          const VerticalDivider(width: 1, color: AppColors.border),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final String currentRoute;

  const _Sidebar({required this.currentRoute});

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

    return SizedBox(
      width: AppSpacing.sidebarWidth,
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('EduOps', style: AppTextStyles.heading4),
              ],
            ),
          ),
          // Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.sm),
              children: AdminLayout._navItems
                  .map(
                    (item) =>
                        _SidebarNavItem(item: item, currentRoute: currentRoute),
                  )
                  .toList(),
            ),
          ),
          // User Profile
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    currentUser?.firstName.substring(0, 1).toUpperCase() ?? 'U',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.fullName ?? 'User',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currentUser?.email ?? '',
                        style: AppTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 20),
                  onPressed: () => _handleLogout(context, ref),
                  tooltip: 'Logout',
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final _NavItem item;
  final String currentRoute;

  const _SidebarNavItem({required this.item, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final isActive =
        currentRoute == item.route ||
        (item.route != '/admin' && currentRoute.startsWith(item.route));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        onTap: () => context.go(item.route),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                size: 20,
                color: isActive ? AppColors.primary : AppColors.mutedForeground,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                item.label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mobile (drawer) ────────────────────────────────────────────────────────

class _MobileLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const _MobileLayout({required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Colors.white, size: 32),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'EduOps',
                    style: AppTextStyles.heading3.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.sm),
                children: AdminLayout._navItems
                    .map(
                      (item) => ListTile(
                        leading: Icon(
                          currentRoute == item.route
                              ? item.activeIcon
                              : item.icon,
                          color: currentRoute == item.route
                              ? AppColors.primary
                              : AppColors.mutedForeground,
                        ),
                        title: Text(
                          item.label,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: currentRoute == item.route
                                ? AppColors.primary
                                : AppColors.foreground,
                          ),
                        ),
                        selected: currentRoute == item.route,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(item.route);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
            // User profile & logout
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      currentUser?.firstName.substring(0, 1).toUpperCase() ??
                          'U',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.fullName ?? 'User',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentUser?.email ?? '',
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, size: 20),
                    onPressed: () async {
                      Navigator.of(context).pop(); // close drawer
                      try {
                        await ref.read(authNotifierProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Logout failed: ${e.toString()}'),
                            ),
                          );
                        }
                      }
                    },
                    tooltip: 'Logout',
                    color: AppColors.mutedForeground,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}

// ─── Model ─────────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final String route;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem(this.label, this.route, this.icon, this.activeIcon);
}
