import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/timetable/timetable_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'timetable_layout_test.dart' show TimetableFakeServer;

Future<void> _pump(
  WidgetTester tester, {
  required String role,
  required double width,
  required Brightness brightness,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final api = ApiClientDart(
    dio: Dio()..httpClientAdapter = TimetableFakeServer(role: role),
  );
  final container = ProviderContainer(
    overrides: [apiProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  await tester.runAsync(
    () => container
        .read(sessionProvider.notifier)
        .login('user', 'password-for-test'),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: const TimetableScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool _hasColoredBox(WidgetTester tester, Color color) {
  return find
      .byWidgetPredicate((widget) {
        if (widget is! Container) return false;
        final decoration = widget.decoration;
        return decoration is BoxDecoration && decoration.color == color;
      })
      .evaluate()
      .isNotEmpty;
}

void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final width in [390.0, 1280.0]) {
      for (final role in ['QUAN_TRI_VIEN', 'GIAO_VIEN', 'HOC_SINH']) {
        testWidgets('thời khóa biểu $role ở $width, $brightness: '
            'không overflow, đúng quyền xem phòng học', (tester) async {
          await _pump(tester, role: role, width: width, brightness: brightness);
          expect(tester.takeException(), isNull);
          expect(find.text('Toán'), findsWidgets);
          expect(find.text('TIẾT'), findsWidgets);
          expect(find.text('BUỔI SÁNG'), findsWidgets);
          expect(find.text('BUỔI CHIỀU'), findsWidgets);
          // Dải tiết 1-10 không bị thu hẹp.
          expect(find.text('T10'), findsWidgets);
          if (role == 'HOC_SINH') {
            expect(find.textContaining('P.10A'), findsNothing);
            expect(find.text('Thêm môn'), findsNothing);
            expect(find.text('Thêm'), findsNothing);
          } else {
            expect(find.textContaining('P.10A'), findsWidgets);
          }
          if (role == 'QUAN_TRI_VIEN') {
            expect(find.text('Thêm môn vào lịch'), findsOneWidget);
          } else {
            expect(find.text('Thêm môn vào lịch'), findsNothing);
          }
          // Chip tiết dùng token đúng chế độ: nền priSoft (GV/QTV) hoặc hover (HS).
          final tokens = brightness == Brightness.dark
              ? AppTokens.dark
              : AppTokens.light;
          final chipBg = role == 'HOC_SINH' ? tokens.hover : tokens.priSoft;
          expect(_hasColoredBox(tester, chipBg), isTrue);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('xem theo ngày của học sinh ẩn phòng học, $brightness', (
      tester,
    ) async {
      await _pump(tester, role: 'HOC_SINH', width: 390, brightness: brightness);
      await tester.tap(find.text('Theo ngày'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thứ Hai'));
      await tester.pumpAndSettle();
      expect(find.text('Toán'), findsOneWidget);
      expect(find.textContaining('P.10A'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('xem theo ngày của giáo viên hiện phòng học, $brightness', (
      tester,
    ) async {
      await _pump(
        tester,
        role: 'GIAO_VIEN',
        width: 390,
        brightness: brightness,
      );
      await tester.tap(find.text('Theo ngày'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thứ Hai'));
      await tester.pumpAndSettle();
      expect(find.text('Toán'), findsOneWidget);
      expect(find.textContaining('P.10A'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
