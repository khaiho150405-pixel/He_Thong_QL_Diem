import 'dart:ui';
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Core White - Blue palette
  static const Color primarySeed = Color(0xFF1A56DB); // Vibrant Royal Blue
  static const Color primaryDark = Color(0xFF1E3A8A); // Deep Navy Blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color warmIvoryBg = Color(
    0xFFF8FAFC,
  ); // Clean ice-white background
  static const Color cardBg = Color(0xFFFFFFFF); // Pure white card
  static const Color sidebarBg = Color(0xFFFFFFFF); // Clean white sidebar
  static const Color widgetBg = Color(0xFFF1F5F9); // Slate-100 container
  static const Color navActiveBg = Color(0xFFEFF6FF); // Soft blue-50 highlight
  static const Color borderSubtle = Color(
    0xFFE2E8F0,
  ); // Subtle slate-200 border
  static const Color borderSidebar = Color(0xFFE2E8F0);
  static const Color goldAccent = Color(0xFF2563EB); // Modern blue accent
  static const Color goldBright = Color(0xFF60A5FA);
  static const Color goldText = Color(0xFF1D4ED8);
  static const Color textMain = Color(0xFF0F172A); // Sharp dark slate text
  static const Color textMuted = Color(0xFF475569); // Slate-600
  static const Color textSubtle = Color(0xFF64748B); // Slate-500

  // Status colors
  static const Color greenBadgeBg = Color(0xFFDCFCE7);
  static const Color greenBadgeText = Color(0xFF15803D);
  static const Color yellowBadgeBg = Color(0xFFFEF3C7);
  static const Color yellowBadgeText = Color(0xFFB45309);
  static const Color redBadgeBg = Color(0xFFFEE2E2);
  static const Color redBadgeText = Color(0xFFB91C1C);
  static const Color blueBadgeBg = Color(0xFFDBEAFE);
  static const Color blueBadgeText = Color(0xFF1D4ED8);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.light,
      primary: primarySeed,
      onPrimary: Colors.white,
      primaryContainer: navActiveBg,
      onPrimaryContainer: primaryDark,
      surface: cardBg,
      onSurface: textMain,
      onSurfaceVariant: textMuted,
      outline: borderSubtle,
      outlineVariant: borderSidebar,
      surfaceContainerLowest: warmIvoryBg,
      surfaceContainerLow: cardBg,
      surfaceContainer: cardBg,
      surfaceContainerHigh: widgetBg,
      surfaceContainerHighest: const Color(0xFFE2E8F0),
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
        radius: const Radius.circular(6),
        crossAxisMargin: 2,
        mainAxisMargin: 4,
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return primaryDark;
          }
          if (states.contains(WidgetState.hovered)) {
            return primarySeed.withAlpha(200);
          }
          return const Color(0xFF94A3B8).withAlpha(160);
        }),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? Colors.black.withAlpha(8)
              : Colors.transparent,
        ),
        trackBorderColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: sidebarBg,
        elevation: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 2,
        indicatorColor: navActiveBg,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? primarySeed
                : textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? primarySeed
                : textMuted,
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
