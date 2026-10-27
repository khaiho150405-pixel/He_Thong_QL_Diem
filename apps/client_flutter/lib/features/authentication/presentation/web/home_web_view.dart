import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/design_tokens.dart';
import '../../../../app/widgets/app_edge_scrollbar.dart';
import '../../../../app/widgets/app_shell.dart';
import '../../../../app/widgets/app_sidebar.dart';
import '../../../../app/widgets/app_user_avatar_menu.dart';
import '../../../../app/widgets/theme_mode_button.dart';
import '../../profile_dialog.dart';
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
    final t = context.tokens;
    final isCollapsed = ref.watch(sidebarCollapsedProvider);

    return Scaffold(
      backgroundColor: t.bg,
      body: AppEdgeScrollbar(
        child: Row(
          children: [
            // Sidebar navy cố định bên trái (thu gọn được); đăng xuất nằm ở
            // cuối sidebar.
            AppSidebarFrame(
              role: role,
              collapsed: isCollapsed,
              child: AppSidebar(currentPath: '/', isCollapsed: isCollapsed),
            ),
            Expanded(
              child: Scaffold(
                backgroundColor: t.bg,
                body: Column(
                  children: [
                    AppTopBar(
                      role: role,
                      title: 'Tổng quan',
                      actions: [
                        const ThemeModeButton(),
                        const SizedBox(width: 8),
                        const AppUserAvatarMenu(showName: true),
                        const SizedBox(width: 6),
                      ],
                    ),
                    Expanded(
                      child: Center(
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
