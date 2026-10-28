import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/timetable/timetable_screen.dart';
import 'package:client_flutter/features/timetable/web/timetable_block.dart';
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
        // Thứ Hai cố định: dữ liệu giả có tiết ở Thứ Hai.
        home: TimetableScreen(today: DateTime(2031, 9, 8)),
      ),
    ),
  );
  await tester.pumpAndSettle();
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
          if (width < 600) {
            // Màn hẹp: chế độ Ngày (thẻ), không còn bảng 7 cột.
            expect(find.text('Ngày'), findsOneWidget);
            expect(find.text('TIẾT'), findsNothing);
          } else {
            // Lưới theo buổi: hai hàng Sáng/Chiều.
            expect(find.text('Sáng'), findsWidgets);
            expect(find.text('Chiều'), findsWidgets);
            expect(find.text('Buổi'), findsWidgets);
          }
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
          if (width >= 600) expect(find.byType(TimetableBlock), findsWidgets);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('thẻ ngày của học sinh ẩn phòng học, $brightness', (
      tester,
    ) async {
      await _pump(tester, role: 'HOC_SINH', width: 390, brightness: brightness);
      expect(find.text('Toán'), findsOneWidget);
      expect(find.textContaining('P.10A'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('thẻ ngày của giáo viên hiện phòng học, $brightness', (
      tester,
    ) async {
      await _pump(
        tester,
        role: 'GIAO_VIEN',
        width: 390,
        brightness: brightness,
      );
      expect(find.text('Toán'), findsOneWidget);
      expect(find.textContaining('P.10A'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
