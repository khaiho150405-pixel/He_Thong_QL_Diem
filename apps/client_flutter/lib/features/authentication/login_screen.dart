import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
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
  bool obscurePassword = true;
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

  void _autofillDemo(String u, String p) {
    setState(() {
      username.text = u;
      password.text = p;
      error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.warmIvoryBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Brand Header
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppTheme.primarySeed,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primarySeed.withAlpha(55),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'E',
                        style: TextStyle(
                          color: Color(0xFFF2D775),
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'EduScore',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'serif',
                      letterSpacing: -0.5,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'HỌC ĐƯỜNG SỐ · THPT BÀ ĐIỂM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: Color(0xFF9B9588),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hệ thống Quản lý Điểm & Đánh giá Học sinh Đa nền tảng',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Login Form Card
                  Card(
                    elevation: 1.5,
                    color: AppTheme.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: AppTheme.borderSubtle,
                        width: 1.2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 30,
                      ),
                      child: Form(
                        key: form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.navActiveBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 18,
                                    color: AppTheme.primarySeed,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Đăng nhập tài khoản',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'serif',
                                          color: AppTheme.primaryDark,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Nhập thông tin được cấp để truy cập',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Username input
                            TextFormField(
                              controller: username,
                              enabled: !busy,
                              decoration: const InputDecoration(
                                labelText: 'Tên đăng nhập',
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  color: AppTheme.primarySeed,
                                ),
                              ),
                              autofillHints: const [AutofillHints.username],
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Nhập tên đăng nhập'
                                  : null,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),

                            // Password input
                            TextFormField(
                              controller: password,
                              enabled: !busy,
                              obscureText: obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppTheme.primarySeed,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                    color: AppTheme.textMuted,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              autofillHints: const [AutofillHints.password],
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Nhập mật khẩu'
                                  : null,
                              onFieldSubmitted: (_) => submit(),
                            ),

                            // Error alert
                            if (error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.redBadgeBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFF0B8AA),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 18,
                                      color: AppTheme.redBadgeText,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        error!,
                                        style: const TextStyle(
                                          color: AppTheme.redBadgeText,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),

                            // Submit button
                            FilledButton(
                              onPressed: busy ? null : submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primarySeed,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: busy
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Đăng nhập',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 12),

                            // Connection check button
                            OutlinedButton(
                              onPressed: () => context.push('/connection'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.wifi_tethering_rounded, size: 16),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Kiểm tra kết nối hệ thống',
                                      style: TextStyle(fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Subtle popup for demo autofill (discreet & professional)
                            Center(
                              child: PopupMenuButton<String>(
                                tooltip: 'Gợi ý tài khoản demo',
                                onSelected: (role) {
                                  switch (role) {
                                    case 'admin':
                                      _autofillDemo('admin', 'Password123!');
                                      break;
                                    case 'teacher':
                                      _autofillDemo(
                                        'giaovien_toan',
                                        'Password123!',
                                      );
                                      break;
                                    case 'student':
                                      _autofillDemo(
                                        'hocsinh_a',
                                        'Password123!',
                                      );
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'admin',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.admin_panel_settings_outlined,
                                          size: 18,
                                          color: AppTheme.primarySeed,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Quản trị viên (admin)',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'teacher',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.school_outlined,
                                          size: 18,
                                          color: AppTheme.primarySeed,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Giáo viên (giaovien_toan)',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'student',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 18,
                                          color: AppTheme.primarySeed,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Học sinh (hocsinh_a)',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline_rounded,
                                        size: 14,
                                        color: colorScheme.onSurfaceVariant
                                            .withAlpha(150),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Gợi ý tài khoản demo ▼',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: colorScheme.onSurfaceVariant
                                                .withAlpha(170),
                                            decoration:
                                                TextDecoration.underline,
                                            decorationStyle:
                                                TextDecorationStyle.dotted,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Help footer
                            Text(
                              'Quên mật khẩu hoặc cần cấp tài khoản? Vui lòng liên hệ quản trị viên nhà trường.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withAlpha(
                                  160,
                                ),
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'THPT Bà Điểm · Hệ thống Quản lý Điểm EduScore · Đa nền tảng',
                    style: TextStyle(fontSize: 11, color: Color(0xFFA0A49E)),
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
}
