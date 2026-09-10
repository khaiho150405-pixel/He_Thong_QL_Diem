import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../academic_catalog/fields.dart';
import 'session.dart';
import 'profile_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  Future<void> changePassword(BuildContext context, WidgetRef ref) async {
    final current = TextEditingController(), next = TextEditingController();
    String? error;
    bool busy = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                ),
              ),
              TextField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới',
                  helperText:
                      'Ít nhất 12 ký tự. Cần đăng nhập lại sau khi đổi.',
                ),
              ),
              if (error != null) Text(error!),
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (next.text.length < 12) {
                        setState(
                          () => error = 'Mật khẩu mới cần ít nhất 12 ký tự.',
                        );
                        return;
                      }
                      setState(() => busy = true);
                      try {
                        await ref
                            .read(apiProvider)
                            .getIdentityApi()
                            .identityPassword(
                              passwordInput: PasswordInput(
                                currentPassword: current.text,
                                newPassword: next.text,
                              ),
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                        ref.read(sessionProvider.notifier).clear();
                      } catch (e) {
                        if (ctx.mounted) {
                          setState(() {
                            error = errorMessage(e);
                            busy = false;
                          });
                        }
                      }
                    },
              child: const Text('Đổi mật khẩu'),
            ),
          ],
        ),
      ),
    );
    current.dispose();
    next.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    if (user == null) return const SizedBox.shrink();
    final visible = resources.where(
      (r) =>
          user.role.value == 'QUAN_TRI_VIEN' ||
          (user.role.value == 'GIAO_VIEN' && r.key != 'accounts') ||
          (user.role.value == 'HOC_SINH' && r.key == 'students'),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý điểm'),
        actions: [
          if (user.role.value != 'QUAN_TRI_VIEN')
            IconButton(
              tooltip: 'Hồ sơ cá nhân',
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const ProfileDialog(),
              ),
              icon: const Icon(Icons.person_outline),
            ),
          IconButton(
            tooltip: 'Đổi mật khẩu',
            onPressed: () => changePassword(context, ref),
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Xin chào, ${user.username}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(roleLabel(user.role.value)),
              const SizedBox(height: 24),
              Text(
                user.role.value == 'HOC_SINH'
                    ? 'Hồ sơ của bạn'
                    : 'Danh mục học vụ',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, box) => Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final r in visible)
                      SizedBox(
                        width: box.maxWidth < 650
                            ? box.maxWidth
                            : (box.maxWidth - 32) / 3,
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(20),
                            leading: const Icon(Icons.folder_outlined),
                            title: Text(r.label),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.go('/catalog/${r.key}'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
