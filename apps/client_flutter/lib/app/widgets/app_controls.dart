import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'app_select_field.dart';

export 'app_select_field.dart';

/// Kích thước chuẩn cho control trong thanh lọc và thanh thao tác.
abstract final class AppControlMetrics {
  static const double height = 48;
  static const double fieldWidth = 300;
  static const double actionWidth = 164;
  static const double radius = 10;
  static const double spacing = 12;

  /// Giữ control vừa màn hình nhỏ sau khi trừ padding trang và padding thẻ.
  static double responsiveFieldWidth(BuildContext context) {
    return math.min(fieldWidth, MediaQuery.sizeOf(context).width - 72);
  }

  static InputDecoration decoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    String? hintText,
    Widget? suffixIcon,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colors.primary,
      ),
      hintStyle: TextStyle(
        fontSize: 12,
        color: colors.onSurfaceVariant.withAlpha(150),
      ),
      isDense: true,
      prefixIcon: Icon(icon, size: 18, color: colors.primary),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 40,
        minHeight: height,
      ),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 40,
        minHeight: height,
      ),
      contentPadding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: colors.outline.withAlpha(120)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
    );
  }
}

class AppFilterDropdown<T> extends StatelessWidget {
  const AppFilterDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width,
    this.searchable = true,
    this.hintText,
  });

  final String label;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final double? width;
  final bool searchable;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final defaultWidth = math.max(
      220.0,
      AppControlMetrics.responsiveFieldWidth(context),
    );
    final resolvedWidth = width != null
        ? math.max(210.0, width!)
        : defaultWidth;
    return AppSelectField<T>(
      value: value,
      label: label,
      icon: icon,
      width: resolvedWidth,
      dense: true,
      hintText: hintText,
      items: items,
      onChanged: onChanged,
      searchable: searchable,
    );
  }
}

enum AppActionButtonKind { primary, secondary }

class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.kind = AppActionButtonKind.primary,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final AppActionButtonKind kind;

  @override
  Widget build(BuildContext context) {
    final child = kind == AppActionButtonKind.primary
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
          );
    return SizedBox(
      width: AppControlMetrics.actionWidth,
      height: AppControlMetrics.height,
      child: child,
    );
  }
}
