import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/session.dart';
import '../design_tokens.dart';
import 'app_edge_scrollbar.dart';
import 'app_shell.dart';
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
    this.leading,
    this.automaticallyImplyLeading,
    this.onBeforeLeave,
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
  final Widget? leading;
  final bool? automaticallyImplyLeading;
  final Future<bool> Function()? onBeforeLeave;

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    if (onBeforeLeave != null) {
      final allow = await onBeforeLeave!();
      if (!allow) return;
    }
    if (!context.mounted) return;
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

  Widget? _backButton(BuildContext context) {
    if (kIsWeb || !showBackButton) return null;
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed:
          onBack ??
          () async {
            if (onBeforeLeave != null) {
              final allow = await onBeforeLeave!();
              if (!allow) return;
            }
            if (!context.mounted) return;
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/');
            }
          },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 960;
    final t = context.tokens;

    if (user == null) {
      return Scaffold(body: body);
    }

    final role = user.role.value;
    final isCollapsed = ref.watch(sidebarCollapsedProvider);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: t.bg,
        body: Row(
          children: [
            AppSidebarFrame(
              role: role,
              collapsed: isCollapsed,
              child: AppSidebar(
                currentPath: currentPath,
                isCollapsed: isCollapsed,
                onBeforeNavigate: onBeforeLeave,
                onLogout: () => _logout(context, ref),
              ),
            ),
            Expanded(
              child: Scaffold(
                backgroundColor: t.bg,
                body: Column(
                  children: [
                    AppTopBar(
                      role: role,
                      title: title,
                      titleWidget: titleWidget,
                      leading: leading ?? _backButton(context),
                      actions: actions,
                      bottom: bottom,
                    ),
                    Expanded(child: AppEdgeScrollbar(child: body)),
                  ],
                ),
                bottomNavigationBar: bottomBar,
                floatingActionButton: floatingActionButton,
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / tablet: AppBar + Drawer navy + thanh điều hướng đáy theo vai.
    final mobileNav = AppBottomNav(
      role: role,
      currentPath: currentPath,
      onBeforeLeave: onBeforeLeave,
    );
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        shape: Border(bottom: BorderSide(color: t.line)),
        leading: leading ?? _backButton(context),
        automaticallyImplyLeading:
            automaticallyImplyLeading ??
            (!kIsWeb && showBackButton ? false : true),
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: t.heading,
        ),
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
        backgroundColor: t.navy,
        child: SafeArea(
          child: AppSidebar(
            inDrawer: true,
            currentPath: currentPath,
            onBeforeNavigate: onBeforeLeave,
            onLogout: () => _logout(context, ref),
          ),
        ),
      ),
      bottomNavigationBar: bottomBar != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [bottomBar!, mobileNav],
            )
          : mobileNav,
      body: AppEdgeScrollbar(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
