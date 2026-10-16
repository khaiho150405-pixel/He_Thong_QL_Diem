import 'package:flutter/material.dart';

import '../design_tokens.dart';

enum AppAvatarSize {
  sm(30, 12),
  md(36, 13),
  lg(56, 18);

  const AppAvatarSize(this.diameter, this.fontSize);
  final double diameter;
  final double fontSize;
}

/// Avatar tròn chữ cái đầu (`.avatar`), không dùng ảnh.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.size = AppAvatarSize.md,
  });

  /// Họ tên đầy đủ; hiển thị chữ cái đầu của từ đầu và từ cuối
  /// (giống hàm `initials` của prototype).
  final String name;
  final AppAvatarSize size;

  /// "Nguyễn Thị Lan" -> "NL", "Lan" -> "L", rỗng -> "".
  static String initialsOf(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    String first(String s) => String.fromCharCode(s.runes.first).toUpperCase();
    return words.length > 1
        ? first(words.first) + first(words.last)
        : first(words.first);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.priSoft,
          shape: BoxShape.circle,
          border: Border.all(color: t.priLine),
        ),
        child: SizedBox(
          width: size.diameter,
          height: size.diameter,
          child: Center(
            child: Text(
              initialsOf(name),
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: t.priLink,
                fontSize: size.fontSize,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
