import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'session.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final username = TextEditingController();
  final password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .login(username.text, password.text);
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school_outlined, size: 64),
                const SizedBox(height: 24),
                Text(
                  'Quản lý điểm',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đăng nhập để làm việc với dữ liệu trong phạm vi của bạn.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: username,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    labelText: 'Tên đăng nhập',
                    border: OutlineInputBorder(),
                  ),
                  autofillHints: const [AutofillHints.username],
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nhập tên đăng nhập'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: password,
                  enabled: !busy,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    border: OutlineInputBorder(),
                  ),
                  autofillHints: const [AutofillHints.password],
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nhập mật khẩu' : null,
                  onFieldSubmitted: (_) => submit(),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Đăng nhập'),
                ),
                TextButton(
                  onPressed: () => context.push('/connection'),
                  child: const Text('Kiểm tra kết nối'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Quên mật khẩu? Liên hệ quản trị viên của trường.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
