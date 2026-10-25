import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/design_tokens.dart';
import '../../../../app/widgets/app_edge_scrollbar.dart';
import '../../../../app/widgets/app_shell.dart';
import '../../../../app/widgets/app_sidebar.dart';
import '../../../../app/widgets/theme_mode_button.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        shape: Border(bottom: BorderSide(color: t.line)),
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: t.heading,
        ),
        title: const Text(
          'EduScore',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          const ThemeModeButton(),
          PopupMenuButton<String>(
            tooltip: 'Tài khoản & Thao tác',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) async {
              if (val == 'profile') {
                showDialog<void>(
                  context: context,
                  builder: (_) => const ProfileDialog(),
                );
              } else if (val == 'password') {
                onChangePassword(context, ref);
              } else if (val == 'logout') {
                try {
                  await ref.read(sessionProvider.notifier).logout();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMessage(e))),
                    );
                  }
                }
              }
            },
            itemBuilder: (ctx) => [
              if (role != 'QUAN_TRI_VIEN')
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Hồ sơ cá nhân'),
                    ],
                  ),
                ),
              if (role != 'HOC_SINH')
                const PopupMenuItem(
                  value: 'password',
                  child: Row(
                    children: [
                      Icon(Icons.password, size: 20),
                      SizedBox(width: 8),
                      Text('Đổi mật khẩu'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: t.navy,
        child: const SafeArea(
          child: AppSidebar(inDrawer: true, currentPath: '/'),
        ),
      ),
      bottomNavigationBar: kIsWeb
          ? null
          : AppBottomNav(role: role, currentPath: '/'),
      body: AppEdgeScrollbar(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1140),
            child: HomeDashboardContent(user: user, role: role),
          ),
        ),
      ),
    );
  }
}
