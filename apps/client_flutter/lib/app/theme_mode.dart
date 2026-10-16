import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chế độ giao diện sáng/tối. Mặc định SÁNG (không theo hệ điều hành).
///
/// Chỉ là trạng thái giao diện, giống `sidebarCollapsedProvider`: KHÔNG lưu
/// lựa chọn, mở lại ứng dụng thì về sáng. Chỉ dùng hai giá trị
/// [ThemeMode.light] và [ThemeMode.dark].
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
