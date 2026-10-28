import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/widgets/app_select_field.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/timetable/timetable_screen.dart';
import 'package:client_flutter/features/timetable/web/timetable_week_board.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Học kỳ 01/09/2031 – 31/12/2031; hôm nay cố định: thứ Hai 08/09/2031 (tuần 2).
const _semester = {
  'id': 1,
  'name': 'Học kỳ I',
  'yearName': '2031-2032',
  'startDate': '2031-09-01',
  'endDate': '2031-12-31',
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
          // Thứ Hai: Ngữ văn tiết 1-3 (gộp), Toán tiết 4 (sáng), Hóa tiết 7.
          for (final p in [1, 2, 3]) _slot(p, 7, 'Ngữ văn', 2, p, 'P.101'),
          _slot(4, 4, 'Toán', 2, 4, 'P.102'),
          _slot(5, 9, 'Hóa học', 2, 7, null),
          // Thứ Tư: Ngữ văn một tiết → cùng môn, cùng màu với thứ Hai.
          _slot(6, 7, 'Ngữ văn', 4, 2, 'P.101'),
        ],
        'total': 6,
        'semester': _semester,
      };
    } else if (options.path.endsWith('/catalog/assignments')) {
      body = {
        'items': [
          {
            'ma_phan_cong': 1,
            'ma_lop': 1,
            'ma_mon': 7,
            'ma_giao_vien': 10,
            'ma_hoc_ky': 1,
            'ngay_phan_cong': '2031-09-01',
            'label': '10A2 · Ngữ văn · Trần Thị B · Học kỳ I',
          },
        ],
        'nextCursor': null,
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
    int subjectId,
    String subject,
    int thu,
    int tiet,
    String? room,
  ) => {
    'ma_tiet_hoc': id,
    'ma_lop': 1,
    'ten_lop': '10A2',
    'ma_mon': subjectId,
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
  double width = 1440,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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

Color _blockColor(WidgetTester tester, int id) =>
    tester.widget<Material>(find.byKey(ValueKey('tt-block-$id'))).color!;

void main() {
  testWidgets('chỉ 2 hàng Sáng/Chiều, tiêu đề cột Thứ 2 + ngày đủ năm', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Sáng'), findsOneWidget);
    expect(find.text('Chiều'), findsOneWidget);
    expect(find.text('Buổi'), findsOneWidget);
    for (var tiet = 1; tiet <= 10; tiet++) {
      expect(find.text('T$tiet'), findsNothing);
    }
    final table = tester.widget<Table>(find.byType(Table));
    expect(table.children.length, 3); // tiêu đề + 2 buổi
    expect(find.text('Thứ 2'), findsOneWidget);
    expect(find.text('Thứ 7'), findsOneWidget);
    expect(find.text('Chủ nhật'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Table),
        matching: find.text('08/09/2031'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'tiết liền nhau gộp một khối; GV thấy Lớp + Phòng, không thấy GV',
    (tester) async {
      await _pump(tester);
      expect(find.text('Tiết: 1 - 3'), findsOneWidget);
      expect(find.text('Tiết: 4'), findsOneWidget);
      expect(find.text('Tiết: 7'), findsOneWidget);
      expect(find.text('Tiết: 2'), findsOneWidget); // Ngữ văn thứ Tư
      expect(find.text('Lớp: 10A2'), findsNWidgets(4));
      expect(find.text('Phòng: P.101'), findsNWidgets(2));
      expect(find.textContaining('GV:'), findsNothing);
      // Ngữ văn (thứ Hai) nằm ở ô Sáng, Hóa học ở ô Chiều.
      expect(find.byKey(const ValueKey('tt-block-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('tt-block-2')), findsNothing);
    },
  );

  testWidgets('học sinh thấy GV, không thấy Lớp/Phòng', (tester) async {
    await _pump(tester, role: 'HOC_SINH');
    expect(find.text('GV: Trần Thị B'), findsNWidgets(4));
    expect(find.textContaining('Lớp:'), findsNothing);
    expect(find.textContaining('Phòng:'), findsNothing);
  });

  testWidgets('cùng môn cùng màu, khác môn khác màu', (tester) async {
    await _pump(tester);
    expect(_blockColor(tester, 1), _blockColor(tester, 6)); // Ngữ văn × 2
    expect(_blockColor(tester, 1), isNot(_blockColor(tester, 4))); // Toán
  });

  testWidgets('giáo viên bấm khối chỉ xem, không có hành động sửa', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byIcon(Icons.add), findsNothing);
    await tester.tap(find.byKey(const ValueKey('tt-block-4'))); // Toán
    await tester.pumpAndSettle();
    expect(find.text('Đóng'), findsOneWidget);
    expect(find.text('Giáo viên'), findsOneWidget);
    expect(find.text('Sửa môn / giáo viên'), findsNothing);
    expect(find.text('Xóa khỏi lịch'), findsNothing);
  });

  testWidgets('QTV: nút + mở hộp thoại thêm với tiết trống đầu tiên', (
    tester,
  ) async {
    await _pump(tester, role: 'QUAN_TRI_VIEN');
    // Sáng thứ Hai đã có tiết 1-4 → tiết trống đầu tiên là 5.
    final add = find.byKey(const ValueKey('tt-add-2-0')).first;
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('Xếp tiết học'), findsOneWidget);
    final fields = tester
        .widgetList<AppSelectField<int>>(find.byType(AppSelectField<int>))
        .toList();
    expect(fields[0].initialValue, 2);
    expect(fields[1].initialValue, 5);
  });

  testWidgets('QTV có chuột: nút + chỉ hiện khi rê vào ô', (tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(2, 2));
    addTearDown(mouse.removePointer);
    await _pump(tester, role: 'QUAN_TRI_VIEN');
    double opacity() => tester
        .widget<AnimatedOpacity>(
          find
              .ancestor(
                of: find.byKey(const ValueKey('tt-add-3-1')),
                matching: find.byType(AnimatedOpacity),
              )
              .first,
        )
        .opacity;
    expect(opacity(), 0);
    await mouse.moveTo(
      tester.getCenter(find.byKey(const ValueKey('tt-cell-3-1'))),
    );
    await tester.pumpAndSettle();
    expect(opacity(), 1);
  });

  testWidgets('QTV: bấm khối mở hành động sửa/chuyển/xóa', (tester) async {
    await _pump(tester, role: 'QUAN_TRI_VIEN');
    await tester.tap(find.byKey(const ValueKey('tt-block-4')));
    await tester.pumpAndSettle();
    expect(find.text('Sửa môn / giáo viên'), findsOneWidget);
    expect(find.text('Chuyển ngày / tiết'), findsOneWidget);
    expect(find.text('Xóa khỏi lịch'), findsOneWidget);
  });

  testWidgets('QTV: công tắc Theo tiết hiện lưới chi tiết từng tiết', (
    tester,
  ) async {
    await _pump(tester, role: 'QUAN_TRI_VIEN');
    expect(find.byType(TimetableWeekBoard), findsWidgets);
    expect(find.byType(DataTable), findsNothing);
    await tester.tap(find.text('Theo tiết'));
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsWidgets);
    expect(find.byType(TimetableWeekBoard), findsNothing);
    expect(find.text('T10'), findsWidgets);
    await tester.tap(find.text('Theo buổi'));
    await tester.pumpAndSettle();
    expect(find.byType(TimetableWeekBoard), findsWidgets);
  });

  testWidgets('mobile 390 px không đổi: không có lưới theo buổi', (
    tester,
  ) async {
    await _pump(tester, width: 390);
    expect(find.byType(TimetableWeekBoard), findsNothing);
    expect(find.byKey(const ValueKey('tt-mode-day')), findsOneWidget);
  });

  for (final width in [1100.0, 1440.0, 900.0]) {
    for (final role in ['GIAO_VIEN', 'HOC_SINH', 'QUAN_TRI_VIEN']) {
      testWidgets('không overflow ở $width px, $role', (tester) async {
        await _pump(tester, role: role, width: width);
        expect(find.byType(TimetableWeekBoard), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Theo ngày'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
