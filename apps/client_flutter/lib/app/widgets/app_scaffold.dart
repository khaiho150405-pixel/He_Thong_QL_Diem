import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/profile_dialog.dart';
import '../../features/authentication/session.dart';
import '../theme.dart';
import 'app_edge_scrollbar.dart';
import 'app_sidebar.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.titleWidget,
    this.bottom,
    this.actions,
    this.floatingActionButton,
    this.currentPath,
    this.showBackButton = false,
    this.onBack,
    this.bottomBar,
  });

  final String title;
  final Widget? titleWidget;
  final PreferredSizeWidget? bottom;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final String? currentPath;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? bottomBar;

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(sessionProvider.notifier).logout();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage(e))));
        }
      }
    }
  }

  Widget? _buildMobileBottomNav(
    BuildContext context,
    String role,
    String? currentPath,
  ) {
    int selectedIndex = 0;
    final destinations =
        <({IconData icon, IconData activeIcon, String label, String route})>[];

    if (role == 'GIAO_VIEN') {
      destinations.addAll([
        (
          icon: Icons.grid_view_outlined,
          activeIcon: Icons.grid_view_rounded,
          label: 'Tổng quan',
          route: '/',
        ),
        (
          icon: Icons.table_chart_outlined,
          activeIcon: Icons.table_chart_rounded,
          label: 'Bảng điểm',
          route: '/gradebooks',
        ),
        (
          icon: Icons.calendar_month_outlined,
          activeIcon: Icons.calendar_month_rounded,
          label: 'Lịch dạy',
          route: '/timetable',
        ),
        (
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Cá nhân',
          route: '__profile__',
        ),
      ]);
      if (currentPath == '/gradebooks' ||
          (currentPath?.startsWith('/gradebooks') ?? false)) {
        selectedIndex = 1;
      } else if (currentPath == '/timetable') {
        selectedIndex = 2;
      } else {
        selectedIndex = 0;
      }
    } else if (role == 'HOC_SINH') {
      destinations.addAll([
        (
          icon: Icons.grid_view_outlined,
          activeIcon: Icons.grid_view_rounded,
          label: 'Tổng quan',
          route: '/',
        ),
        (
          icon: Icons.fact_check_outlined,
          activeIcon: Icons.fact_check_rounded,
          label: 'Điểm số',
          route: '/my-results',
        ),
        (
          icon: Icons.calendar_month_outlined,
          activeIcon: Icons.calendar_month_rounded,
          label: 'Lịch học',
          route: '/timetable',
        ),
        (
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Cá nhân',
          route: '__profile__',
        ),
      ]);
      if (currentPath == '/my-results') {
        selectedIndex = 1;
      } else if (currentPath == '/timetable') {
        selectedIndex = 2;
      } else {
        selectedIndex = 0;
      }
    } else {
      // QUAN_TRI_VIEN
      destinations.addAll([
        (
          icon: Icons.grid_view_outlined,
          activeIcon: Icons.grid_view_rounded,
          label: 'Tổng quan',
          route: '/',
        ),
        (
          icon: Icons.table_chart_outlined,
          activeIcon: Icons.table_chart_rounded,
          label: 'Bảng điểm',
          route: '/gradebooks',
        ),
        (
          icon: Icons.calendar_month_outlined,
          activeIcon: Icons.calendar_month_rounded,
          label: 'TKB',
          route: '/timetable',
        ),
        (
          icon: Icons.folder_outlined,
          activeIcon: Icons.folder_rounded,
          label: 'Danh mục',
          route: '/catalog/classes',
        ),
        (
          icon: Icons.rule_outlined,
          activeIcon: Icons.rule_rounded,
          label: 'Chính sách',
          route: '/classification-policy',
        ),
      ]);
      if (currentPath == '/gradebooks' ||
          (currentPath?.startsWith('/gradebooks') ?? false)) {
        selectedIndex = 1;
      } else if (currentPath == '/timetable') {
        selectedIndex = 2;
      } else if (currentPath?.startsWith('/catalog') ?? false) {
        selectedIndex = 3;
      } else if (currentPath == '/classification-policy') {
        selectedIndex = 4;
      } else {
        selectedIndex = 0;
      }
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.borderSidebar, width: 1),
        ),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        height: 64,
        onDestinationSelected: (idx) {
          final dest = destinations[idx];
          if (dest.route == '__profile__') {
            showDialog<void>(
              context: context,
              builder: (_) => const ProfileDialog(),
            );
            return;
          }
          if (dest.route != currentPath) {
            try {
              context.go(dest.route);
            } catch (_) {
              Navigator.of(context).pushNamed(dest.route);
            }
          }
        },
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.activeIcon, color: AppTheme.primarySeed),
              label: d.label,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 960;

    if (user == null) {
      return Scaffold(body: body);
    }

    final role = user.role.value;
    final isCollapsed = ref.watch(sidebarCollapsedProvider);
    final double sidebarWidth = isCollapsed
        ? 70.0
        : (role == 'QUAN_TRI_VIEN'
              ? 258.0
              : (role == 'GIAO_VIEN' ? 242.0 : 236.0));

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Sidebar with dynamic collapsible width
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutCubic,
              width: sidebarWidth,
              child: Material(
                color: AppTheme.sidebarBg,
                elevation: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: AppTheme.borderSidebar,
                        width: 1,
                      ),
                    ),
                  ),
                  child: AppSidebar(
                    currentPath: currentPath,
                    isCollapsed: isCollapsed,
                  ),
                ),
              ),
            ),

            // Main Content Screen
            Expanded(
              child: Scaffold(
                backgroundColor: AppTheme.warmIvoryBg,
                appBar: PreferredSize(
                  preferredSize: Size.fromHeight(
                    bottom != null ? (bottom!.preferredSize.height + 64) : 64,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.sidebarBg,
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.borderSidebar,
                          width: 1,
                        ),
                      ),
                    ),
                    child: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: (!kIsWeb && showBackButton)
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed:
                                  onBack ??
                                  () {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    } else {
                                      context.go('/');
                                    }
                                  },
                            )
                          : null,
                      automaticallyImplyLeading: false,
                      title:
                          titleWidget ??
                          Text(title, overflow: TextOverflow.ellipsis),
                      bottom: bottom,
                      actions: [
                        ...?actions,
                        IconButton(
                          tooltip: 'Đăng xuất',
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          onPressed: () => _logout(context, ref),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                body: AppEdgeScrollbar(child: body),
                bottomNavigationBar: bottomBar,
                floatingActionButton: floatingActionButton,
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Tablet layout
    return Scaffold(
      backgroundColor: AppTheme.warmIvoryBg,
      appBar: AppBar(
        leading: (!kIsWeb && showBackButton)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed:
                    onBack ??
                    () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        context.go('/');
                      }
                    },
              )
            : null,
        title: titleWidget ?? Text(title, overflow: TextOverflow.ellipsis),
        bottom: bottom,
        actions: [
          ...?actions,
          if (!showBackButton) ...[
            IconButton(
              tooltip: 'Đăng xuất',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => _logout(context, ref),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: AppSidebar(inDrawer: true, currentPath: currentPath),
        ),
      ),
      bottomNavigationBar: () {
        final mobileNav = _buildMobileBottomNav(context, role, currentPath);
        if (bottomBar != null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [bottomBar!, if (mobileNav != null) mobileNav],
          );
        }
        return mobileNav;
      }(),
      body: AppEdgeScrollbar(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
