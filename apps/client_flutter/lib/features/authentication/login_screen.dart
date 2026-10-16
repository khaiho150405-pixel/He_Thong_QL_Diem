import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/design_tokens.dart';
import '../../app/widgets/app_edge_scrollbar.dart';
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
                  child: wide
                      ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Expanded(flex: 11, child: _LoginArtPanel()),
                              Expanded(
                                flex: 10,
                                child: _formSide(context, wide),
                              ),
                            ],
                          ),
                        )
                      : _formSide(context, wide),
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
        crossAxisAlignment: wide
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.stretch,
        children: [
          if (wide) ...[
            Text('Đăng nhập', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Dùng tài khoản do nhà trường cấp.',
              style: theme.textTheme.bodyMedium,
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
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () => context.push('/connection'),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_tethering_rounded, size: 16),
                SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    'Kiểm tra kết nối hệ thống',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Quên mật khẩu? Liên hệ quản trị viên của trường.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomPaint(
            painter: _DashedLinePainter(t.line2),
            child: const SizedBox(height: 1, width: double.infinity),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'XEM THỬ VỚI VAI TRÒ',
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: PopupMenuButton<String>(
              tooltip: 'Gợi ý tài khoản demo',
              onSelected: (role) {
                switch (role) {
                  case 'admin':
                    _autofillDemo('admin', 'Password123!');
                    break;
                  case 'teacher':
                    _autofillDemo('giaovien_toan', 'Password123!');
                    break;
                  case 'student':
                    _autofillDemo('hocsinh_a', 'Password123!');
                    break;
                }
              },
              itemBuilder: (context) => [
                _demoItem(
                  t,
                  'admin',
                  Icons.admin_panel_settings_outlined,
                  'Quản trị viên (admin)',
                ),
                _demoItem(
                  t,
                  'teacher',
                  Icons.school_outlined,
                  'Giáo viên (giaovien_toan)',
                ),
                _demoItem(
                  t,
                  'student',
                  Icons.person_outline,
                  'Học sinh (hocsinh_a)',
                ),
              ],
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: t.line2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: t.ink2,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'Gợi ý tài khoản demo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: t.ink,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 20,
                      color: t.ink2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _demoItem(
    AppTokens t,
    String value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: t.pri),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 13))),
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

/// Nửa trái nền navy (chỉ hiện từ 960): thương hiệu, tiêu đề, 3 ý tính năng
/// và tờ giấy trang trí. Toàn bộ là nội dung tĩnh, không có chức năng.
class _LoginArtPanel extends StatelessWidget {
  const _LoginArtPanel();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Container(
      color: t.navy,
      padding: const EdgeInsets.all(36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: t.onPri.withAlpha(36),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.school_rounded, size: 22, color: t.onPri),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EduScore',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: t.onPri,
                      ),
                    ),
                    Text(
                      'Trường THPT Bà Điểm · Quản lý điểm',
                      style: TextStyle(fontSize: 13, color: t.onNavy),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.xxl),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              'Nhập điểm nhanh hơn, đối chiếu rõ ràng hơn.',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 34,
                height: 44 / 34,
                color: t.onPri,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _Feature(
            icon: Icons.photo_camera_outlined,
            title: 'Chụp bảng điểm viết tay',
            body:
                'Hệ thống đọc điểm số và điểm chữ, giáo viên chỉ cần xem lại.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Feature(
            icon: Icons.checklist_rounded,
            title: 'Đối chiếu trước khi duyệt',
            body:
                'Ô nào chắc chắn hiện màu Xanh, ô cần xem lại hiện Vàng hoặc Đỏ.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Feature(
            icon: Icons.history_rounded,
            title: 'Lưu lịch sử mọi thay đổi',
            body: 'Biết ai sửa điểm nào, khi nào, từ giá trị nào.',
          ),
          const SizedBox(height: AppSpacing.xxl),
          const _PaperMini(),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: t.onPri.withAlpha(31),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: t.acc),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: t.onPri,
                ),
              ),
              const SizedBox(height: 2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  body,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 20 / 13.5,
                    color: t.onNavy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tờ giấy nghiêng -1,2 độ (prototype `.paper-mini`). Chữ "viết tay" dùng
/// Be Vietnam Pro nghiêng vì Caveat không được đóng gói.
class _PaperMini extends StatelessWidget {
  const _PaperMini();

  static const _rows = [
    ('1', 'Nguyễn Văn An', '8.5', 'tám phẩy năm'),
    ('2', 'Trần Thị Bích', '7', 'bảy'),
    ('3', 'Lê Hoàng Cường', '6.5', 'sáu phẩy năm'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final printed = TextStyle(fontSize: 12, color: t.onAcc);
    final hand = TextStyle(
      fontSize: 16,
      height: 1.2,
      fontWeight: FontWeight.w600,
      fontStyle: FontStyle.italic,
      color: t.pen,
    );
    return ExcludeSemantics(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Transform.rotate(
          angle: -1.2 * math.pi / 180,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: t.paper,
                borderRadius: BorderRadius.circular(10),
                boxShadow: t.pop,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'DANH SÁCH GHI ĐIỂM',
                      style: printed.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.66,
                      ),
                    ),
                  ),
                  for (final r in _rows)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: t.paperLine)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            child: Text(r.$1, style: printed),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: 10,
                            child: Text(
                              r.$2,
                              style: printed,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(width: 40, child: Text(r.$3, style: hand)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: 13,
                            child: Text(
                              r.$4,
                              style: hand,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(math.min(x + dash, size.width), 0),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}
