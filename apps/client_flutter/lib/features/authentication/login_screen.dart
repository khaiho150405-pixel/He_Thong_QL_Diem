
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/design_tokens.dart';
import '../../app/widgets/app_edge_scrollbar.dart';
import '../../app/widgets/theme_mode_button.dart';
import 'login_art_panel.dart';
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

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.surface,
      body: SafeArea(
        child: AppEdgeScrollbar(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Breakpoint 960 giống màn Trang chủ: từ 960 trở lên có nửa trái.
              final wide = constraints.maxWidth >= 960;
              return SingleChildScrollView(
                primary: true,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    minWidth: constraints.maxWidth,
                  ),
                  // Nút đổi sáng/tối nằm góc trên phải, cuộn cùng nội dung.
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      if (wide)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 11,
                                child: LoginArtPanel(
                                  horizontalMockup:
                                      constraints.maxWidth * 11 / 21 -
                                          LoginArtPanel.horizontalPadding >=
                                      LoginArtPanel.horizontalMinWidth,
                                ),
                              ),
                              Expanded(
                                flex: 10,
                                child: _formSide(context, wide),
                              ),
                            ],
                          ),
                        )
                      else
                        _formSide(context, wide),
                      const Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: ThemeModeButton(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _formSide(BuildContext context, bool wide) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: wide ? AppSpacing.xxxl : AppSpacing.xxl,
          vertical: AppSpacing.xxxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: _buildForm(context, wide),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool wide) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Form(
      key: form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Kéo giãn hết cột form (tối đa 380) ở mọi breakpoint để ô nhập và
        // hai nút luôn rộng bằng nhau; tiêu đề màn rộng vẫn căn trái.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide) ...[
            Text(
              'Đăng nhập',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Dùng tài khoản do nhà trường cấp.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.start,
            ),
          ] else
            _CompactBrand(tokens: t),
          SizedBox(height: wide ? AppSpacing.xxl : AppSpacing.xl),
          TextFormField(
            controller: username,
            enabled: !busy,
            decoration: InputDecoration(
              labelText: 'Tên đăng nhập',
              prefixIcon: Icon(Icons.person_outline_rounded, color: t.pri),
            ),
            autofillHints: const [AutofillHints.username],
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nhập tên đăng nhập' : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: password,
            enabled: !busy,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: Icon(Icons.lock_outline_rounded, color: t.pri),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: t.ink3,
                ),
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              ),
            ),
            autofillHints: const [AutofillHints.password],
            validator: (v) => v == null || v.isEmpty ? 'Nhập mật khẩu' : null,
            onFieldSubmitted: (_) => submit(),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: t.badSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: t.badLine),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, size: 18, color: t.bad),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: t.bad,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: busy ? null : submit,
            child: busy
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: t.onPri,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text('Đăng nhập')),
                      SizedBox(width: AppSpacing.sm),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Quên mật khẩu? Liên hệ quản trị viên của trường.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Đầu trang rút gọn khi màn hẹp (prototype `.m-login`): logo, tên, trường.
class _CompactBrand extends StatelessWidget {
  const _CompactBrand({required this.tokens});
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: t.navy,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.navyLine),
          ),
          child: Icon(Icons.school_rounded, size: 32, color: t.onPri),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'EduScore',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Hệ thống quản lý điểm',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        Text(
          'Trường THPT Bà Điểm',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
