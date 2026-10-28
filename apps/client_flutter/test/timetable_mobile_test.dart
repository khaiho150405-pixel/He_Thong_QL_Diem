import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/timetable/timetable_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Học kỳ 03/09/2031 – 30/09/2031. Hôm nay cố định: thứ Hai 08/09/2031.
const _semester = {
  'id': 1,
  'name': 'Học kỳ I',
  'yearName': '2031-2032',
  'startDate': '2031-09-03',
  'endDate': '2031-09-30',
};
final _today = DateTime(2031, 9, 8, 9);

class _Server implements HttpClientAdapter {
  _Server(this.role);
  final String role;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final Object body;
    if (options.path.endsWith('/identity/login')) {
      body = {
        'id': 1,
        'username': 'u',
        'role': role,
        'active': true,
        'token': 'token',
        'csrf': 'csrf',
      };
    } else if (options.path.endsWith('/timetable')) {
      body = {
        'items': [
          // Thứ Hai: Ngữ văn tiết 1-3 (gộp), Toán tiết 4, Hóa tiết 7 (chiều).
          for (final p in [1, 2, 3]) _slot(p, 'Ngữ văn', 2, p, 'P.101'),
          _slot(4, 'Toán', 2, 4, 'P.102'),
          _slot(7, 'Hóa học', 2, 7, null),
        ],
        'total': 5,
        'semester': _semester,
      };
    } else if (options.path.contains('/catalog/')) {
      body = {'items': [], 'nextCursor': null};
    } else {
      body = {};
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  Map<String, Object?> _slot(
    int id,
    String subject,
    int thu,
    int tiet,
    String? room,
  ) => {
    'ma_tiet_hoc': id,
    'ma_lop': 1,
    'ten_lop': '10A2',
    'ma_mon': subject.length,
    'ten_mon': subject,
    'ma_giao_vien': 10,
    'ten_giao_vien': 'Trần Thị B',
    'ma_hoc_ky': 1,
    'ten_hoc_ky': 'Học kỳ I',
    'thu': thu,
    'tiet': tiet,
    'phong_hoc': room,
    'ghi_chu': null,
  };
}

Future<void> _pump(
  WidgetTester tester, {
  String role = 'GIAO_VIEN',
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final container = ProviderContainer(
    overrides: [
      apiProvider.overrideWithValue(
        ApiClientDart(dio: Dio()..httpClientAdapter = _Server(role)),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.runAsync(
    () => container.read(sessionProvider.notifier).login('u', 'pw-for-test'),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: TimetableScreen(today: _today)),
    ),
  );
  await tester.pumpAndSettle();
}

String _caption(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('tt-caption'))).data!;

Future<void> _mode(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(ValueKey('tt-mode-$name')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mặc định chế độ Ngày: thẻ đúng môn/tiết, gộp tiết liền nhau', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Th 2, 08/09/2031'), findsOneWidget);
    expect(_caption(tester), 'Thứ Hai · Tuần 2');
    expect(find.text('Ngữ văn'), findsOneWidget); // 3 tiết → 1 thẻ
    expect(find.text('1 - 3'), findsOneWidget);
    expect(find.text('Toán'), findsOneWidget);
    expect(find.text('4'), findsOneWidget); // một tiết ghi "4"
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Buổi sáng'), findsNWidgets(2));
    expect(find.text('Buổi chiều'), findsOneWidget);
    expect(find.text('Phòng:'), findsNWidgets(2)); // Hóa không có phòng
    expect(
      find.byKey(const ValueKey('timetable-weekly-vertical-scroll')),
      findsNothing,
    );
  });

  testWidgets('giáo viên thấy Lớp, không thấy Giáo viên', (tester) async {
    await _pump(tester, role: 'GIAO_VIEN');
    expect(find.text('Lớp:'), findsWidgets);
    expect(find.text('Giáo viên:'), findsNothing);
    expect(find.text('Bộ lọc'), findsNothing);
  });

  testWidgets('học sinh thấy Giáo viên, không thấy Lớp/Phòng', (tester) async {
    await _pump(tester, role: 'HOC_SINH');
    expect(find.text('Giáo viên:'), findsWidgets);
    expect(find.text('Trần Thị B'), findsWidgets);
    expect(find.text('Lớp:'), findsNothing);
    expect(find.text('Phòng:'), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });

  testWidgets('chế độ Tuần: danh sách theo ngày, ngày trống mờ', (
    tester,
  ) async {
    await _pump(tester);
    await _mode(tester, 'week');
    expect(_caption(tester), 'Tuần 2 · 08/09 – 14/09/2031');
    expect(find.text('Thứ Hai, 08/09'), findsOneWidget);
    expect(find.text('Thứ Ba, 09/09'), findsOneWidget);
    expect(find.text('Hôm nay'), findsOneWidget); // huy hiệu của nhóm hôm nay
    expect(find.text('Ngữ văn'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('tt-week-list')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không có tiết'), findsWidgets);
  });

  testWidgets('chế độ Tháng: bấm ngày → về chế độ Ngày đúng ngày', (
    tester,
  ) async {
    await _pump(tester);
    await _mode(tester, 'month');
    expect(_caption(tester), 'Tháng 9/2031');
    expect(find.text('T2'), findsOneWidget);
    expect(find.text('5 tiết'), findsWidgets); // thứ Hai có 5 tiết khác nhau

    await tester.tap(find.byKey(const ValueKey('tt-month-day-1'))); // ngoài kỳ
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tt-month-grid')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tt-month-day-10')));
    await tester.pumpAndSettle();
    expect(find.text('Th 4, 10/09/2031'), findsOneWidget);
    expect(_caption(tester), 'Thứ Tư · Tuần 2');
    expect(find.text('Không có tiết dạy/học trong ngày này'), findsOneWidget);
    expect(find.text('Ngữ văn'), findsNothing);
  });

  testWidgets('‹ › và vuốt đổi ngày, khóa ở biên, Hôm nay quay về', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byKey(const ValueKey('tt-today')), findsNothing);

    await tester.fling(
      find.byKey(const ValueKey('tt-day-list')),
      const Offset(-300, 0),
      1500,
    );
    await tester.pumpAndSettle();
    expect(find.text('Th 3, 09/09/2031'), findsOneWidget);
    expect(find.byKey(const ValueKey('tt-today')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tt-today')));
    await tester.pumpAndSettle();
    expect(find.text('Th 2, 08/09/2031'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byTooltip('Trước'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Th 4, 03/09/2031'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('Trước'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('QTV: có Bộ lọc/Thêm môn, bấm thẻ mở hành động sửa', (
    tester,
  ) async {
    await _pump(tester, role: 'QUAN_TRI_VIEN');
    expect(find.text('Bộ lọc'), findsOneWidget);
    expect(find.text('Thêm môn vào lịch'), findsOneWidget);

    await tester.tap(find.text('Ngữ văn'));
    await tester.pumpAndSettle();
    expect(find.text('Sắp xếp tiết học'), findsOneWidget);
    expect(find.text('Sửa môn / giáo viên'), findsWidgets);
    expect(find.text('Xóa khỏi lịch'), findsWidgets);
    await tester.tapAt(const Offset(10, 10)); // chạm nền mờ để đóng
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bộ lọc'));
    await tester.pumpAndSettle();
    expect(find.text('Bộ lọc thời khóa biểu'), findsOneWidget);
    expect(find.text('Lớp học'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('màn rộng vẫn là lưới tuần', (tester) async {
    await _pump(tester, width: 1280);
    expect(find.byKey(const ValueKey('tt-mode-day')), findsNothing);
    expect(find.text('Thứ 2'), findsOneWidget);
    expect(find.byType(Table), findsOneWidget);
    expect(find.byType(DataTable), findsNothing);
  });

  for (final cfg in const [(320.0, 1.0), (320.0, 1.5), (390.0, 1.0)]) {
    for (final role in ['GIAO_VIEN', 'HOC_SINH', 'QUAN_TRI_VIEN']) {
      testWidgets('không overflow ở ${cfg.$1}px chữ ${cfg.$2}x, $role', (
        tester,
      ) async {
        await _pump(tester, role: role, width: cfg.$1, textScale: cfg.$2);
        for (final mode in ['day', 'week', 'month']) {
          await _mode(tester, mode);
          expect(tester.takeException(), isNull, reason: mode);
        }
      });
    }
  }
}
