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
          const ThemeModeButton(),
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
