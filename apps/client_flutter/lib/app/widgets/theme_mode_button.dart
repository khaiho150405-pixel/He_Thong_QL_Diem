import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme_mode.dart';

/// Nút đổi giao diện sáng/tối. Chỉ chuyển qua lại giữa sáng và tối; mặc định
/// là sáng, không lưu lựa chọn (xem [themeModeProvider]). Nhãn trợ năng lấy từ
/// `tooltip` của [IconButton].
class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return IconButton(
      key: const ValueKey('theme-mode-toggle'),
      tooltip: isDark
          ? 'Chuyển sang giao diện sáng'
          : 'Chuyển sang giao diện tối',
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => ref.read(themeModeProvider.notifier).state = isDark
          ? ThemeMode.light
          : ThemeMode.dark,
    );
  }
}
