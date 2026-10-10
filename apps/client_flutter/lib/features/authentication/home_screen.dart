import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/mobile/home_mobile_view.dart';
import 'presentation/web/home_web_view.dart';
import 'session.dart';

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
              const SizedBox(height: 12),
              TextField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới',
                  helperText:
                      'Ít nhất 12 ký tự. Cần đăng nhập lại sau khi đổi.',
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
              ],
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

    final role = user.role.value;
    final width = MediaQuery.sizeOf(context).width;

    // Chuẩn Responsive UI/UX đa màn hình:
    // - Màn hình lớn (width >= 960): Giao diện Web Desktop chuyên dụng với Sidebar cố định và bảng điều khiển rộng.
    // - Màn hình vừa và nhỏ (width < 960): Giao diện Mobile/Tablet linh hoạt với Drawer và Bottom Navigation, tự động thích ứng mượt mà khi co giãn trình duyệt.
    if (width >= 960) {
      return HomeWebView(
        user: user,
        role: role,
        onChangePassword: changePassword,
      );
    }

    return HomeMobileView(
      user: user,
      role: role,
      onChangePassword: changePassword,
    );
  }
}
