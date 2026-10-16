import 'dart:ui';
import 'package:flutter/material.dart';

import 'design_tokens.dart';

class AppTheme {
  AppTheme._();

  // Hằng màu dùng trực tiếp trong các màn hình hiện có. Giá trị là bảng màu
  // SÁNG của prototype (xem `design_tokens.dart`). Tên giữ nguyên để không
  // phải sửa màn hình; code mới nên dùng `context.tokens` để tự đổi theo
  // chế độ sáng/tối.
  static const Color primarySeed = Color(0xFF1F5FD1); // --pri
  static const Color primaryDark = Color(0xFF0F2B5B); // --navy
  static const Color primaryLight = Color(0xFF5C8DE6);
  static const Color warmIvoryBg = Color(0xFFF3F6FB); // --bg
  static const Color cardBg = Color(0xFFFFFFFF); // --surface
  static const Color sidebarBg = Color(0xFFFFFFFF); // sidebar navy: bước 5
  static const Color widgetBg = Color(0xFFEEF3FA); // --hover
  static const Color navActiveBg = Color(0xFFE8F0FD); // --prisoft
  static const Color borderSubtle = Color(0xFFDDE4EE); // --line
  static const Color borderSidebar = Color(0xFFDDE4EE); // --line
  // Tên "gold" là di sản; giá trị vẫn là xanh primary. Màu amber thật của
  // prototype nằm ở `AppTokens.acc`.
  static const Color goldAccent = Color(0xFF1F5FD1); // --pri
  static const Color goldBright = Color(0xFF5C8DE6);
  static const Color goldText = Color(0xFF1A4FB0); // --prih
  static const Color textMain = Color(0xFF14213D); // --ink
  static const Color textMuted = Color(0xFF44546F); // --ink2
  static const Color textSubtle = Color(0xFF62728F); // --ink3

  // Màu trạng thái (nền / chữ), bảng sáng của prototype.
  static const Color greenBadgeBg = Color(0xFFE3F6EE); // --oksoft
  static const Color greenBadgeText = Color(0xFF12805C); // --ok
  static const Color yellowBadgeBg = Color(0xFFFFF3D1); // --warnsoft
  static const Color yellowBadgeText = Color(0xFF8A5600); // --warn
  static const Color redBadgeBg = Color(0xFFFDE8E8); // --badsoft
  static const Color redBadgeText = Color(0xFFC23B3B); // --bad
  static const Color blueBadgeBg = Color(0xFFE8F0FD); // --prisoft
  static const Color blueBadgeText = Color(0xFF1F5FD1); // --pri

  static ThemeData light() => _build(AppTokens.light);

  static ThemeData dark() => _build(AppTokens.dark);

  static ThemeData _build(AppTokens t) {
    final brightness = t.brightness;
    final isLight = brightness == Brightness.light;
    final heading = t.heading;

    // Chỉ ghi đè các vai trò đang được widget dùng; secondary giữ do fromSeed
    // sinh ra để không đổi giao diện các màn hiện có. Amber nằm ở tertiary.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: t.pri,
      brightness: brightness,
      primary: t.pri,
      onPrimary: t.onPri,
      primaryContainer: t.priSoft,
      onPrimaryContainer: isLight ? t.navy : t.priLink,
      tertiary: t.acc,
      onTertiary: t.onAcc,
      tertiaryContainer: t.accSoft,
      onTertiaryContainer: t.warn,
      error: t.bad,
      onError: isLight ? Colors.white : t.bg,
      errorContainer: t.badSoft,
      onErrorContainer: t.bad,
      surface: t.surface,
      onSurface: t.ink,
      onSurfaceVariant: t.ink2,
      outline: t.line,
      outlineVariant: t.line,
      surfaceContainerLowest: t.bg,
      surfaceContainerLow: t.surface,
      surfaceContainer: t.surface,
      surfaceContainerHigh: t.hover,
      surfaceContainerHighest: isLight ? const Color(0xFFE2E8F0) : t.line,
    );

    // Font đóng gói trong assets/fonts (không tải từ mạng); các font nền tảng
    // chỉ làm dự phòng cho ký tự Be Vietnam Pro không có.
    final baseTextTheme = ThemeData(brightness: brightness, useMaterial3: true)
        .textTheme
        .apply(
          fontFamily: kAppFontFamily,
          fontFamilyFallback: kAppFontFallback,
          displayColor: t.ink,
          bodyColor: t.ink,
        );

    final textTheme = baseTextTheme.copyWith(
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: heading,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: heading,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: heading,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: heading,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: heading,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: t.ink,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: t.ink, fontSize: 15),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: t.ink2,
        fontSize: 13.5,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(color: t.ink3, fontSize: 12),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: t.ink3,
      ),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    );
    const buttonText = TextStyle(fontWeight: FontWeight.w600, fontSize: 14);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 13);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: kAppFontFamily,
      fontFamilyFallback: kAppFontFallback,
      scaffoldBackgroundColor: t.bg,
      extensions: <ThemeExtension<dynamic>>[t],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: t.surface,
        foregroundColor: heading,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: heading,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: heading),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: t.line, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        color: t.surface,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: t.line2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: t.line2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: t.pri, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        labelStyle: TextStyle(color: t.ink2),
        floatingLabelStyle: TextStyle(
          color: t.priLink,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.pri,
          foregroundColor: t.onPri,
          minimumSize: const Size(0, 48),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: buttonPadding,
          side: BorderSide(color: t.line2),
          foregroundColor: heading,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: t.priLink),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        side: BorderSide(color: t.line),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        backgroundColor: t.surface,
        selectedColor: t.priSoft,
        disabledColor: t.hover,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: t.ink,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: heading,
        ),
        checkmarkColor: heading,
        iconTheme: IconThemeData(size: 16, color: heading),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(t.subtle),
        headingTextStyle: textTheme.titleSmall?.copyWith(
          color: heading,
          fontWeight: FontWeight.w700,
        ),
        dataTextStyle: textTheme.bodyMedium?.copyWith(color: t.ink),
        horizontalMargin: 16,
        columnSpacing: 20,
        dividerThickness: 0.8,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: t.line),
        ),
        elevation: 4,
        backgroundColor: t.surface,
      ),
      dividerTheme: DividerThemeData(color: t.line, thickness: 1, space: 1),
      tabBarTheme: TabBarThemeData(
        labelColor: t.priLink,
        unselectedLabelColor: t.ink2,
        indicatorColor: t.pri,
        dividerColor: t.line,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.navy,
        contentTextStyle: TextStyle(
          fontFamily: kAppFontFamily,
          fontFamilyFallback: kAppFontFallback,
          color: Colors.white,
          fontSize: 14,
        ),
        actionTextColor: t.acc,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(8),
        radius: const Radius.circular(6),
        crossAxisMargin: 2,
        mainAxisMargin: 4,
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return isLight ? t.navy : t.priLink;
          }
          if (states.contains(WidgetState.hovered)) {
            return t.pri.withAlpha(200);
          }
          return t.ink3.withAlpha(160);
        }),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? (isLight ? Colors.black : Colors.white).withAlpha(8)
              : Colors.transparent,
        ),
        trackBorderColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: t.surface, elevation: 4),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.surface,
        elevation: 2,
        indicatorColor: t.priSoft,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? t.priLink : t.ink2,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected) ? t.priLink : t.ink2,
          ),
        ),
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}
