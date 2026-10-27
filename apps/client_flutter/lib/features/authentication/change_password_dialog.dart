import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/design_tokens.dart';
import 'session.dart';

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ChangePasswordDialog(),
      );

  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNext = true;
  bool _obscureConfirm = true;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nextText = _next.text;
    final confirmText = _confirm.text;

    if (_current.text.isEmpty) {
      setState(() => _error = 'Vui lòng nhập mật khẩu hiện tại.');
      return;
    }
    if (nextText.length < 12) {
      setState(() => _error = 'Mật khẩu mới cần ít nhất 12 ký tự.');
      return;
    }
    if (nextText != confirmText) {
      setState(() => _error = 'Mật khẩu xác nhận không khớp.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(apiProvider).getIdentityApi().identityPassword(
            passwordInput: PasswordInput(
              currentPassword: _current.text,
              newPassword: nextText,
            ),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đổi mật khẩu thành công! Vui lòng đăng nhập lại.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      ref.read(sessionProvider.notifier).clear();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = errorMessage(e);
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: t.priSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.lock_reset_rounded, color: t.priLink, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Đổi mật khẩu',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: t.heading,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mật khẩu mới yêu cầu tối thiểu 12 ký tự. Sau khi đổi thành công, bạn sẽ cần đăng nhập lại.',
                style: TextStyle(color: t.ink3, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _current,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _next,
                obscureText: _obscureNext,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: const Icon(Icons.key_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNext
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureNext = !_obscureNext),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _confirm,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: t.badSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: t.badLine),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, size: 16, color: t.bad),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: t.bad,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Đổi mật khẩu'),
        ),
      ],
    );
  }
}
