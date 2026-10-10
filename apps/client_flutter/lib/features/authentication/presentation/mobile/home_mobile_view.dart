import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../app/widgets/app_edge_scrollbar.dart';
import '../../../../app/widgets/app_sidebar.dart';
import '../../profile_dialog.dart';
import '../../session.dart';
import '../widgets/home_dashboard_content.dart';

class HomeMobileView extends ConsumerWidget {
  const HomeMobileView({
    super.key,
    required this.user,
    required this.role,
    required this.onChangePassword,
  });

  final SessionDto user;
  final String role;
  final Future<void> Function(BuildContext, WidgetRef) onChangePassword;

  Widget _buildMobileBottomNav(BuildContext context) {
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
    } else {
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
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.borderSidebar, width: 1),
        ),
      ),
      child: NavigationBar(
        selectedIndex: 0,
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
          if (dest.route != '/') {
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
    return Scaffold(
      backgroundColor: AppTheme.warmIvoryBg,
      appBar: AppBar(
        title: const Text('EduScore · THPT Bà Điểm'),
        actions: [
          if (role != 'QUAN_TRI_VIEN')
            IconButton(
              tooltip: 'Hồ sơ cá nhân',
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const ProfileDialog(),
              ),
              icon: const Icon(Icons.person_outline),
            ),
          if (role != 'HOC_SINH')
            IconButton(
              tooltip: 'Đổi mật khẩu',
              onPressed: () => onChangePassword(context, ref),
              icon: const Icon(Icons.password),
            ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () async {
              try {
                await ref.read(sessionProvider.notifier).logout();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(errorMessage(e))));
                }
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: const Drawer(
        child: SafeArea(child: AppSidebar(inDrawer: true, currentPath: '/')),
      ),
      bottomNavigationBar: kIsWeb ? null : _buildMobileBottomNav(context),
      body: AppEdgeScrollbar(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1140),
            child: HomeDashboardContent(
              user: user,
              role: role,
              isDesktop: false,
            ),
          ),
        ),
      ),
    );
  }
}
