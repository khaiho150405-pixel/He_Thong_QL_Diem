import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/authentication/change_password_dialog.dart';
import '../../features/authentication/profile_dialog.dart';
import '../../features/authentication/session.dart';
import '../design_tokens.dart';
import 'app_avatar.dart';

/// Hộp thoại xác nhận đăng xuất thống nhất toàn hệ thống
Future<void> confirmLogout(
  BuildContext context,
  WidgetRef ref, [
  Future<void> Function()? onLogout,
]) async {
  final t = context.tokens;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: t.badSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.logout_rounded, color: t.bad, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text(
              'Xác nhận đăng xuất',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: const Text(
        'Bạn có chắc chắn muốn đăng xuất khỏi hệ thống EduScore?',
        style: TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: t.bad,
            foregroundColor: t.onPri,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Đăng xuất'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    if (onLogout != null) {
      await onLogout();
      return;
    }
    try {
      await ref.read(sessionProvider.notifier).logout();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage(e))),
        );
      }
    }
  }
}

/// Menu Avatar gom toàn bộ thao tác tài khoản:
/// 1. Thông tin cá nhân (ad, gv)
/// 2. Đổi mật khẩu (ad, gv)
/// 3. Đăng xuất (có hỏi trước khi đăng xuất)
class AppUserAvatarMenu extends ConsumerWidget {
  const AppUserAvatarMenu({
    super.key,
    this.size = AppAvatarSize.sm,
    this.showName = false,
    this.textColor,
    this.onLogout,
  });

  final AppAvatarSize size;
  final bool showName;
  final Color? textColor;
  final Future<void> Function()? onLogout;

  static String _roleLabel(String role) => switch (role) {
    'QUAN_TRI_VIEN' => 'Quản trị viên',
    'GIAO_VIEN' => 'Giáo viên',
    _ => 'Học sinh',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    if (user == null) return const SizedBox.shrink();

    final t = context.tokens;
    final role = user.role.value;
    final isStaff = role == 'QUAN_TRI_VIEN' || role == 'GIAO_VIEN';

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: t.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: t.line),
          ),
          elevation: 6,
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Tài khoản: ${user.username}',
        offset: const Offset(0, 44),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 180, maxWidth: 230),
        onSelected: (val) async {
          if (val == 'profile') {
            showDialog<void>(
              context: context,
              builder: (_) => const ProfileDialog(),
            );
          } else if (val == 'password') {
            ChangePasswordDialog.show(context);
          } else if (val == 'logout') {
            confirmLogout(context, ref, onLogout);
          }
        },
        itemBuilder: (ctx) => [
          // Header tóm tắt tài khoản
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    AppAvatar(name: user.username, size: AppAvatarSize.sm),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.username,
                            style: TextStyle(
                              color: t.heading,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _roleLabel(role),
                            style: TextStyle(
                              color: t.ink3,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: t.line),
              ],
            ),
          ),
          // 1. Thông tin cá nhân (ad, gv)
          if (isStaff)
            PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.badge_outlined, size: 19, color: t.priLink),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Thông tin cá nhân',
                      style: TextStyle(fontSize: 13.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          // 2. Đổi mật khẩu (ad, gv)
          if (isStaff)
            PopupMenuItem<String>(
              value: 'password',
              child: Row(
                children: [
                  Icon(Icons.lock_reset_rounded, size: 19, color: t.priLink),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Đổi mật khẩu',
                      style: TextStyle(fontSize: 13.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (isStaff)
            const PopupMenuDivider(height: 1),
          // 3. Đăng xuất (có hỏi trước khi đăng xuất)
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout_rounded, size: 19, color: t.bad),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đăng xuất',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: t.bad,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: showName ? 6 : 2,
              vertical: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppAvatar(name: user.username, size: size),
                if (showName) ...[
                  const SizedBox(width: 8),
                  Text(
                    user.username,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? t.heading,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: textColor ?? t.ink3,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
