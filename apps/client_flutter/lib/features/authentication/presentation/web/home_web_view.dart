import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../app/widgets/app_edge_scrollbar.dart';
import '../../../../app/widgets/app_sidebar.dart';
import '../../profile_dialog.dart';
import '../../session.dart';
import '../widgets/home_dashboard_content.dart';

class HomeWebView extends ConsumerWidget {
  const HomeWebView({
    super.key,
    required this.user,
    required this.role,
    required this.onChangePassword,
  });

  final SessionDto user;
  final String role;
  final Future<void> Function(BuildContext, WidgetRef) onChangePassword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = ref.watch(sidebarCollapsedProvider);
    final double sidebarWidth = isCollapsed
        ? 70.0
        : (role == 'QUAN_TRI_VIEN'
              ? 258.0
              : (role == 'GIAO_VIEN' ? 242.0 : 236.0));

    return Scaffold(
      backgroundColor: AppTheme.warmIvoryBg,
      body: AppEdgeScrollbar(
        child: Row(
          children: [
            // 1. Persistent Left Sidebar (Collapsible)
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
                  child: AppSidebar(currentPath: '/', isCollapsed: isCollapsed),
                ),
              ),
            ),

            // 2. Main Dashboard Content on the right
            Expanded(
              child: Scaffold(
                backgroundColor: AppTheme.warmIvoryBg,
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(64),
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
                      automaticallyImplyLeading: false,
                      title: const Text(
                        'EduScore · THPT Bà Điểm',
                        overflow: TextOverflow.ellipsis,
                      ),
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(errorMessage(e))),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.logout),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                body: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1140),
                    child: HomeDashboardContent(
                      user: user,
                      role: role,
                      isDesktop: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
