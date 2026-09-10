import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Hồ sơ cá nhân'),
    content: SizedBox(
      width: 440,
      child: loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error != null) Text(error!),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                  ),
                  if (teacher)
                    TextField(
                      controller: email,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                  if (teacher)
                    TextField(
                      controller: phone,
                      decoration: const InputDecoration(
                        labelText: 'Điện thoại',
                      ),
                    ),
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
      FilledButton(
        onPressed: loading || busy ? null : save,
        child: const Text('Lưu'),
      ),
    ],
  );
}
