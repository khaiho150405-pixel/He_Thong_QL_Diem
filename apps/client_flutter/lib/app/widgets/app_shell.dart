import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/profile_dialog.dart';
import '../design_tokens.dart';

/// Nhãn vai trò dùng ở dòng nhỏ phía trên tiêu đề topbar (`.eyebrow`).
String appRoleLabel(String role) => switch (role) {
  'QUAN_TRI_VIEN' => 'Quản trị viên',
  'GIAO_VIEN' => 'Giáo viên',
  _ => 'Học sinh',
};

/// Độ rộng sidebar: 258 (quản trị), 242 (giáo viên), 236 (học sinh); 70 khi
/// thu gọn.
double appSidebarWidth(String role, {required bool collapsed}) {
  if (collapsed) return 70;
  return switch (role) {
    'QUAN_TRI_VIEN' => 258,
    'GIAO_VIEN' => 242,
    _ => 236,
  };
}

/// Khung co giãn bao quanh [child] (thường là `AppSidebar`).
class AppSidebarFrame extends StatelessWidget {
  const AppSidebarFrame({
    super.key,
    required this.role,
    required this.collapsed,
    required this.child,
  });

  final String role;
  final bool collapsed;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeInOutCubic,
    width: appSidebarWidth(role, collapsed: collapsed),
    child: child,
  );
}

/// Topbar màn rộng (`.top` của prototype): dòng nhỏ vai trò, tiêu đề trang,
/// nền surface, viền dưới `line`.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.role,
    required this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottom,
    this.yearLabel,
  });

  final String role;
  final String title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final String? yearLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.line)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 68),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            [
                              appRoleLabel(role).toUpperCase(),
                              if (yearLabel != null && yearLabel!.isNotEmpty)
                                yearLabel!,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 14 / 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.66,
                              color: t.ink3,
                            ),
                          ),
                          titleWidget ??
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 22 / 16,
                                  fontWeight: FontWeight.w700,
                                  color: t.heading,
                                ),
                              ),
                        ],
                      ),
                    ),
                    if (actions != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      ...actions!,
                    ],
                  ],
                ),
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}

/// Thanh điều hướng đáy theo vai trên màn hẹp (`.tabbar` của prototype):
/// tab đang chọn màu primary, nhãn 12px.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.role,
    this.currentPath,
    this.onBeforeLeave,
  });

  final String role;
  final String? currentPath;
  final Future<bool> Function()? onBeforeLeave;

  static const _profileRoute = '__profile__';

  List<({IconData icon, IconData activeIcon, String label, String route})>
  get _destinations {
    const home = (
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Tổng quan',
      route: '/',
    );
    const profile = (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Cá nhân',
      route: _profileRoute,
    );
    if (role == 'GIAO_VIEN') {
      return const [
        home,
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
        profile,
      ];
    }
    if (role == 'HOC_SINH') {
      return const [
        home,
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
        profile,
      ];
    }
    return const [
      home,
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
    ];
  }

  int get _selectedIndex {
    final path = currentPath;
    final gradebooks = path != null && path.startsWith('/gradebooks');
    if (role == 'GIAO_VIEN') {
      if (gradebooks) return 1;
      if (path == '/timetable') return 2;
      return 0;
    }
    if (role == 'HOC_SINH') {
      if (path == '/my-results') return 1;
      if (path == '/timetable') return 2;
      return 0;
    }
    if (gradebooks) return 1;
    if (path == '/timetable') return 2;
    if (path != null && path.startsWith('/catalog')) return 3;
    if (path == '/classification-policy') return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final destinations = _destinations;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: t.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          indicatorColor: Colors.transparent,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected) ? t.priLink : t.ink3,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? t.priLink : t.ink3,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          height: 64,
          onDestinationSelected: (idx) async {
            if (onBeforeLeave != null) {
              final allow = await onBeforeLeave!();
              if (!allow) return;
            }
            if (!context.mounted) return;
            final dest = destinations[idx];
            if (dest.route == _profileRoute) {
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
                if (context.mounted) {
                  Navigator.of(context).pushNamed(dest.route);
                }
              }
            }
          },
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.activeIcon),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}
