import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Core brand palette from UI/src/App.tsx
  static const Color primarySeed = Color(0xFF173F43);
  static const Color primaryDark = Color(0xFF163B3F);
  static const Color warmIvoryBg = Color(0xFFECE9E1);
  static const Color cardBg = Color(0xFFF7F6F1);
  static const Color sidebarBg = Color(0xFFF6F4EE);
  static const Color widgetBg = Color(0xFFEEECE6);
  static const Color navActiveBg = Color(0xFFDFE8E2);
  static const Color borderSubtle = Color(0xFFD8D4CA);
  static const Color borderSidebar = Color(0xFFD5D0C5);
  static const Color goldAccent = Color(0xFFC69C3C);
  static const Color goldBright = Color(0xFFE7C864);
  static const Color goldText = Color(0xFF9A7222);
  static const Color textMain = Color(0xFF20383A);
  static const Color textMuted = Color(0xFF697472);
  static const Color textSubtle = Color(0xFF8B8578);

  // Status colors
  static const Color greenBadgeBg = Color(0xFFDCEBDD);
  static const Color greenBadgeText = Color(0xFF347151);
  static const Color yellowBadgeBg = Color(0xFFF5E8C9);
  static const Color yellowBadgeText = Color(0xFF9A7222);
  static const Color redBadgeBg = Color(0xFFFBE4DC);
  static const Color redBadgeText = Color(0xFF9B4430);
  static const Color blueBadgeBg = Color(0xFFDBE7F1);
  static const Color blueBadgeText = Color(0xFF3C6685);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.light,
      primary: primarySeed,
      onPrimary: Colors.white,
      primaryContainer: navActiveBg,
      onPrimaryContainer: primarySeed,
      surface: cardBg,
      onSurface: textMain,
      onSurfaceVariant: textMuted,
      outline: borderSubtle,
      outlineVariant: borderSidebar,
      surfaceContainerLowest: warmIvoryBg,
      surfaceContainerLow: cardBg,
      surfaceContainer: cardBg,
      surfaceContainerHigh: widgetBg,
      surfaceContainerHighest: const Color(0xFFE5E2D8),
    );

    // Keep typography available offline on Web, Android and iOS. Platform
    // fonts cover Vietnamese and avoid a late web-font swap that can clip text.
    final baseTextTheme = ThemeData.light(useMaterial3: true).textTheme.apply(
      fontFamilyFallback: const ['Roboto', 'Arial', 'Noto Sans', 'sans-serif'],
    );

    final textTheme = baseTextTheme.copyWith(
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primaryDark,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: primaryDark,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: primaryDark,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: primaryDark,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: primaryDark,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: textMain,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: textMain,
        fontSize: 15,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: textMuted,
        fontSize: 13.5,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: textSubtle,
        fontSize: 12,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: textSubtle,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: warmIvoryBg,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: sidebarBg,
        foregroundColor: primaryDark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: primaryDark,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: primaryDark),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        color: cardBg,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primarySeed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        labelStyle: const TextStyle(color: textMuted),
        floatingLabelStyle: const TextStyle(
          color: primarySeed,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primarySeed,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          side: const BorderSide(color: borderSubtle),
          foregroundColor: primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: borderSubtle),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        backgroundColor: Colors.white,
        selectedColor: navActiveBg,
        disabledColor: widgetBg,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textMain,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryDark,
        ),
        checkmarkColor: primaryDark,
        iconTheme: const IconThemeData(size: 16, color: primaryDark),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(widgetBg.withAlpha(180)),
        headingTextStyle: textTheme.titleSmall?.copyWith(
          color: primaryDark,
          fontWeight: FontWeight.w700,
        ),
        dataTextStyle: textTheme.bodyMedium?.copyWith(color: textMain),
        horizontalMargin: 16,
        columnSpacing: 20,
        dividerThickness: 0.8,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle),
        ),
        elevation: 4,
        backgroundColor: cardBg,
      ),
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: 1,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(8),
        radius: const Radius.circular(8),
        crossAxisMargin: 2,
        mainAxisMargin: 4,
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.dragged)
              ? primarySeed.withAlpha(190)
              : primaryDark.withAlpha(105),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: sidebarBg,
        elevation: 4,
      ),
    );
  }
}
