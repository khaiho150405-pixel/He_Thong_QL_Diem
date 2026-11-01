import 'package:flutter/material.dart';

import '../design_tokens.dart';

/// Biến thể màu của [AppBadge] (class `.badge.ok/.warn/.bad/.info/.neu`).
enum AppBadgeTone { ok, warn, bad, info, neutral }

/// Nhãn trạng thái dạng pill: nền nhạt, viền, chữ 12, căn giữa.
///
/// Không có chấm tròn đầu dòng. Nhãn trạng thái (mặc định, [dot] = true) có cùng
/// chiều rộng tối thiểu [AppBadge.minWidth] nên các ô trạng thái trong một cột
/// luôn bằng nhau dù chữ dài hay ngắn; chữ dài hơn thì nhãn nở ra, không bao
/// giờ bị cắt. Nhãn thông tin như số lượng, tên lớp truyền `dot: false` để vừa
/// khít chữ.
class AppBadge extends StatelessWidget {
  const AppBadge(
    this.label, {
    super.key,
    this.tone = AppBadgeTone.neutral,
    this.dot = true,
    this.width,
  });

  const AppBadge.ok(this.label, {super.key, this.dot = true, this.width})
    : tone = AppBadgeTone.ok;
  const AppBadge.warn(this.label, {super.key, this.dot = true, this.width})
    : tone = AppBadgeTone.warn;
  const AppBadge.bad(this.label, {super.key, this.dot = true, this.width})
    : tone = AppBadgeTone.bad;
  const AppBadge.info(this.label, {super.key, this.dot = true, this.width})
    : tone = AppBadgeTone.info;

  /// Chiều rộng tối thiểu chung của mọi nhãn trạng thái.
  static const double minWidth = 112;

  final String label;
  final AppBadgeTone tone;

  /// Không còn vẽ chấm tròn. `true` (mặc định) = nhãn trạng thái, rộng tối thiểu
  /// [minWidth]; `false` = nhãn thông tin, vừa khít chữ.
  final bool dot;

  /// Chiều rộng cố định, thay cho [minWidth] khi cần (chữ vẫn không bị cắt
  /// nếu vượt quá: nhãn co chữ về một dòng bằng `FittedBox`).
  final double? width;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (bg, fg, line) = switch (tone) {
      AppBadgeTone.ok => (t.okSoft, t.ok, t.okLine),
      AppBadgeTone.warn => (t.warnSoft, t.warn, t.warnLine),
      AppBadgeTone.bad => (t.badSoft, t.bad, t.badLine),
      AppBadgeTone.info => (t.priSoft, t.priLink, t.priLine),
      AppBadgeTone.neutral => (t.neuSoft, t.neu, t.line),
    };
    final base = Theme.of(context).textTheme.bodySmall;
    final text = Text(
      label,
      maxLines: 1,
      softWrap: false,
      textAlign: TextAlign.center,
      style: base?.copyWith(
        color: fg,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
      ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: width ?? (dot ? minWidth : 0),
        maxWidth: width ?? double.infinity,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: line),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: width == null
                ? text
                : FittedBox(fit: BoxFit.scaleDown, child: text),
          ),
        ),
      ),
    );
  }
}
