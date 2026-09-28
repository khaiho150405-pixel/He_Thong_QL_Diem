import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/widgets/role_badge.dart';
import 'session.dart';

class ProfileDialog extends ConsumerStatefulWidget {
  const ProfileDialog({super.key});
  @override
  ConsumerState<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends ConsumerState<ProfileDialog> {
  final name = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController();
  bool loading = true, busy = false;
  String? error;
  bool get teacher => ref.read(sessionProvider)?.role.value == 'GIAO_VIEN';

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final profile =
          (await ref.read(apiProvider).getIdentityApi().identityProfile())
              .data!;
      name.text = profile.name;
      email.text = profile.email ?? '';
      phone.text = profile.phone ?? '';
    } catch (e) {
      error = errorMessage(e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      setState(() => error = 'Nhập họ và tên.');
      return;
    }
    setState(() => busy = true);
    try {
      await ref
          .read(apiProvider)
          .getIdentityApi()
          .identityUpdateProfile(
            profileDto: ProfileDto(
              name: name.text.trim(),
              email: teacher && email.text.isNotEmpty ? email.text : null,
              phone: teacher && phone.text.isNotEmpty ? phone.text : null,
            ),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(sessionProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primary.withAlpha(25),
            child: Icon(
              Icons.badge_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hồ sơ cá nhân',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: RoleBadge(role: user.role.value, compact: true),
                  ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: loading
            ? const SizedBox(
                height: 100,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Đang tải thông tin hồ sơ…'),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withAlpha(120),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorScheme.error.withAlpha(80),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                error!,
                                style: TextStyle(
                                  color: colorScheme.error,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                        ),
                      ),
                    ),
                    if (teacher) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: email,
                        decoration: const InputDecoration(
                          labelText: 'Email liên hệ',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: phone,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        if (error != null)
          TextButton(onPressed: load, child: const Text('Thử lại')),
        FilledButton.icon(
          onPressed: loading || busy ? null : save,
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded, size: 18),
          label: Text(busy ? 'Đang lưu…' : 'Lưu thay đổi'),
        ),
      ],
    );
  }
}
