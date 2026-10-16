import 'package:flutter/material.dart';

import '../design_tokens.dart';

/// Biến thể màu của [AppBadge] (class `.badge.ok/.warn/.bad/.info/.neu`).
enum AppBadgeTone { ok, warn, bad, info, neutral }

/// Nhãn trạng thái dạng pill: nền nhạt, viền, chữ 12, có chấm tròn đầu dòng.
class AppBadge extends StatelessWidget {
  const AppBadge(
    this.label, {
    super.key,
    this.tone = AppBadgeTone.neutral,
    this.dot = true,
  });

  const AppBadge.ok(this.label, {super.key, this.dot = true})
    : tone = AppBadgeTone.ok;
  const AppBadge.warn(this.label, {super.key, this.dot = true})
    : tone = AppBadgeTone.warn;
  const AppBadge.bad(this.label, {super.key, this.dot = true})
    : tone = AppBadgeTone.bad;
  const AppBadge.info(this.label, {super.key, this.dot = true})
    : tone = AppBadgeTone.info;

  final String label;
  final AppBadgeTone tone;

  /// Tắt chấm tròn đầu dòng (`.badge.nodot`).
  final bool dot;

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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              DecoratedBox(
                key: const ValueKey('app-badge-dot'),
                decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
                child: const SizedBox(width: 6, height: 6),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: base?.copyWith(
                  color: fg,
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
