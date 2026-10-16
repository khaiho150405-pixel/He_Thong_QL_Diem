import 'dart:io';

import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/features/connection/connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('token khớp prototype', () {
    test('bảng sáng', () {
      const t = AppTokens.light;
      expect(t.bg, const Color(0xFFF3F6FB));
      expect(t.pri, const Color(0xFF1F5FD1));
      expect(t.navy, const Color(0xFF0F2B5B));
      expect(t.acc, const Color(0xFFF2A900));
      expect(t.ok, const Color(0xFF12805C));
      expect(t.okSoft, const Color(0xFFE3F6EE));
      expect(t.warn, const Color(0xFF8A5600));
      expect(t.warnSoft, const Color(0xFFFFF3D1));
      expect(t.bad, const Color(0xFFC23B3B));
      expect(t.badSoft, const Color(0xFFFDE8E8));
      expect(t.neu, const Color(0xFF5B6B86));
      expect(t.neuSoft, const Color(0xFFEAEFF6));
    });

    test('bảng tối', () {
      const t = AppTokens.dark;
      expect(t.bg, const Color(0xFF0B1220));
      expect(t.surface, const Color(0xFF111B2E));
      expect(t.pri, const Color(0xFF2F6FE4));
      expect(t.navy, const Color(0xFF0A1A3A));
      expect(t.acc, const Color(0xFFF2A900));
      expect(t.ok, const Color(0xFF4FD1A0));
      expect(t.okSoft, const Color(0xFF0F2D26));
      expect(t.warn, const Color(0xFFF2B84B));
      expect(t.warnSoft, const Color(0xFF33270B));
      expect(t.bad, const Color(0xFFFF8E8E));
      expect(t.badSoft, const Color(0xFF3A1717));
      expect(t.neu, const Color(0xFFAAB8D1));
      expect(t.neuSoft, const Color(0xFF1B2842));
    });
  });

  group('ThemeData', () {
    for (final entry in {
      Brightness.light: AppTheme.light(),
      Brightness.dark: AppTheme.dark(),
    }.entries) {
      final brightness = entry.key;
      final theme = entry.value;
      final tokens = brightness == Brightness.light
          ? AppTokens.light
          : AppTokens.dark;

      test('$brightness: Material 3, màu, font, token', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.brightness, brightness);
        expect(theme.scaffoldBackgroundColor, tokens.bg);
        expect(theme.colorScheme.primary, tokens.pri);
        expect(theme.colorScheme.tertiary, tokens.acc);
        expect(theme.colorScheme.error, tokens.bad);
        expect(theme.colorScheme.surface, tokens.surface);
        expect(theme.extension<AppTokens>(), same(tokens));
        expect(theme.textTheme.bodyLarge?.fontFamily, kAppFontFamily);
        expect(theme.textTheme.titleLarge?.fontFamily, kAppFontFamily);
        // Chiều cao control chuẩn 48 không đổi.
        expect(
          theme.filledButtonTheme.style?.minimumSize?.resolve({}),
          const Size(0, 48),
        );
      });
    }
  });

  group('font Be Vietnam Pro', () {
    test('4 file nằm trong assets và được khai báo trong pubspec', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('family: $kAppFontFamily'));
      for (final name in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        final path = 'assets/fonts/BeVietnamPro-$name.ttf';
        expect(File(path).existsSync(), isTrue, reason: path);
        expect(pubspec, contains('asset: $path'));
      }
      expect(File('assets/fonts/OFL.txt').existsSync(), isTrue);
    });

    testWidgets('chữ tiếng Việt có dấu dựng bằng Be Vietnam Pro', (
      tester,
    ) async {
      const sample = 'Quản lý điểm: Đặng Thị Ngọc Ánh, Nguyễn Hữu Ðức';
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: Text(sample)),
        ),
      );
      final style = tester
          .widget<RichText>(find.byType(RichText).first)
          .text
          .style;
      expect(style?.fontFamily, kAppFontFamily);
      expect(find.text(sample), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('GradebookApp', () {
    for (final brightness in Brightness.values) {
      testWidgets('mặc định sáng dù hệ thống: $brightness', (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [connectionProvider.overrideWith((ref) async {})],
            child: const GradebookApp(initialLocation: '/connection'),
          ),
        );
        await tester.pumpAndSettle();

        final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(app.themeMode, ThemeMode.light);
        expect(app.theme?.brightness, Brightness.light);
        expect(app.darkTheme?.brightness, Brightness.dark);

        final context = tester.element(find.text('Kết nối thành công'));
        expect(Theme.of(context).brightness, Brightness.light);
        expect(context.tokens.brightness, Brightness.light);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
