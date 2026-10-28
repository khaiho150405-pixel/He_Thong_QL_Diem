import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/timetable/timetable_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Học kỳ 03/09/2031 (thứ Tư) – 30/09/2031 (thứ Ba): 5 tuần, tuần đầu/cuối lẻ.
const _semester = {
  'id': 1,
  'name': 'Học kỳ I',
  'yearName': '2031-2032',
  'startDate': '2031-09-03',
  'endDate': '2031-09-30',
};

// Hôm nay cố định: thứ Tư 10/09/2031, tuần 2 (08/09 – 14/09).
final _today = DateTime(2031, 9, 10, 15, 30);

class _Server implements HttpClientAdapter {
  _Server({this.withSemester = true});
  final bool withSemester;

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
        'username': 'gv',
        'role': 'GIAO_VIEN',
        'active': true,
        'token': 'token',
        'csrf': 'csrf',
      };
    } else if (options.path.endsWith('/timetable')) {
      body = {
        'items': [_slot(1, 2, 'Toán'), _slot(2, 4, 'Ngữ văn')],
        'total': 2,
        'semester': withSemester ? _semester : null,
      };
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

  Map<String, Object?> _slot(int id, int thu, String subject) => {
    'ma_tiet_hoc': id,
    'ma_lop': 1,
    'ten_lop': '10A1',
    'ma_mon': id,
    'ten_mon': subject,
    'ma_giao_vien': 10,
    'ten_giao_vien': 'Giáo viên',
    'ma_hoc_ky': 1,
    'ten_hoc_ky': 'Học kỳ I',
    'thu': thu,
    'tiet': 1,
    'phong_hoc': null,
    'ghi_chu': null,
  };
}

Future<void> _pump(
  WidgetTester tester, {
  bool withSemester = true,
  DateTime? today,
}) async {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final api = ApiClientDart(
    dio: Dio()..httpClientAdapter = _Server(withSemester: withSemester),
  );
  final container = ProviderContainer(
    overrides: [apiProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  await tester.runAsync(
    () => container.read(sessionProvider.notifier).login('gv', 'pw-for-test'),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: TimetableScreen(today: today ?? _today)),
    ),
  );
  await tester.pumpAndSettle();
}

String _weekLabel(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('timetable-week-label')))
    .data!;

VoidCallback? _onPressed(WidgetTester tester, String label) => tester
    .widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    )
    .onPressed;

/// Chữ trong tiêu đề cột (tránh trùng nhãn ô chọn ngày trên thanh công cụ).
Finder _head(String text) =>
    find.descendant(of: find.byType(Table), matching: find.text(text));

Color? _headColor(WidgetTester tester, String text) =>
    tester.widget<Text>(_head(text)).style?.color;

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mặc định vào tuần chứa hôm nay, cột có đúng ngày', (
    tester,
  ) async {
    await _pump(tester);
    expect(_weekLabel(tester), '08/09 – 14/09/2031');
    expect(find.text('Tuần 2'), findsOneWidget);
    expect(find.text('Học kỳ I · 2031-2032'), findsOneWidget);
    for (final d in [
      '08/09/2031',
      '09/09/2031',
      '10/09/2031',
      '11/09/2031',
      '12/09/2031',
      '13/09/2031',
      '14/09/2031',
    ]) {
      expect(_head(d), findsOneWidget);
    }
    expect(_head('Thứ 2'), findsOneWidget);
    expect(_head('Chủ nhật'), findsOneWidget);
  });

  testWidgets('Tuần trước/sau đổi ngày và bị khóa ở biên học kỳ', (
    tester,
  ) async {
    await _pump(tester);
    await _tap(tester, 'Tuần trước');
    expect(_weekLabel(tester), '01/09 – 07/09/2031');
    expect(find.text('Tuần 1'), findsOneWidget);
    expect(_head('01/09/2031'), findsOneWidget);
    expect(_onPressed(tester, 'Tuần trước'), isNull);
    expect(_onPressed(tester, 'Tuần sau'), isNotNull);

    for (var i = 0; i < 4; i++) {
      await _tap(tester, 'Tuần sau');
    }
    expect(_weekLabel(tester), '29/09 – 05/10/2031');
    expect(find.text('Tuần 5'), findsOneWidget);
    expect(_onPressed(tester, 'Tuần sau'), isNull);
    expect(_onPressed(tester, 'Tuần trước'), isNotNull);

    await _tap(tester, 'Hôm nay');
    expect(_weekLabel(tester), '08/09 – 14/09/2031');
  });

  testWidgets('chỉ tô "hôm nay" khi tuần đang xem chứa hôm nay', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      _headColor(tester, '10/09/2031'),
      isNot(_headColor(tester, '09/09/2031')),
    );
    expect(_headColor(tester, '09/09/2031'), _headColor(tester, '11/09/2031'));

    await _tap(tester, 'Tuần sau'); // 15/09 – 21/09
    expect(_headColor(tester, '17/09/2031'), _headColor(tester, '16/09/2031'));
    expect(_headColor(tester, '15/09/2031'), _headColor(tester, '16/09/2031'));
  });

  testWidgets('ngày ngoài học kỳ mờ đi và không hiện tiết', (tester) async {
    await _pump(tester);
    // Tuần 2: cả Toán (thứ Hai) lẫn Ngữ văn (thứ Tư) hiện.
    expect(find.text('Toán'), findsOneWidget);
    expect(find.text('Ngữ văn'), findsOneWidget);

    await _tap(tester, 'Tuần trước'); // 01/09 – 07/09, bắt đầu từ 03/09
    expect(find.text('Toán'), findsNothing); // thứ Hai 01/09 ngoài học kỳ
    expect(find.text('Ngữ văn'), findsOneWidget); // thứ Tư 03/09 trong học kỳ
    final faded = tester.widget<Opacity>(
      find.ancestor(of: _head('01/09/2031'), matching: find.byType(Opacity)),
    );
    expect(faded.opacity, lessThan(1));
  });

  testWidgets('hôm nay sau học kỳ: vào tuần cuối, nút Hôm nay tắt', (
    tester,
  ) async {
    await _pump(tester, today: DateTime(2031, 12, 1));
    expect(find.text('Tuần 5'), findsOneWidget);
    expect(_weekLabel(tester), '29/09 – 05/10/2031');
    expect(_onPressed(tester, 'Hôm nay'), isNull);
  });

  testWidgets('hôm nay trước học kỳ: vào tuần 1', (tester) async {
    await _pump(tester, today: DateTime(2031, 8, 1));
    expect(find.text('Tuần 1'), findsOneWidget);
    expect(_weekLabel(tester), '01/09 – 07/09/2031');
  });

  testWidgets(
    'semester null: vẫn hiện ngày, chuyển tuần tự do, không "Tuần n"',
    (tester) async {
      await _pump(tester, withSemester: false);
      expect(_weekLabel(tester), '08/09 – 14/09/2031');
      expect(find.text('Tuần 2'), findsNothing);
      expect(_head('10/09/2031'), findsOneWidget);
      expect(find.text('Toán'), findsOneWidget);

      await _tap(tester, 'Tuần sau');
      expect(_weekLabel(tester), '15/09 – 21/09/2031');
      await _tap(tester, 'Tuần trước');
      await _tap(tester, 'Tuần trước');
      expect(_weekLabel(tester), '01/09 – 07/09/2031');
      expect(find.text('Toán'), findsOneWidget); // không giới hạn học kỳ
      expect(_onPressed(tester, 'Tuần trước'), isNotNull);
    },
  );

  testWidgets('tab Theo ngày: nút thứ kèm ngày, ngoài học kỳ có thông báo', (
    tester,
  ) async {
    await _pump(tester);
    await _tap(tester, 'Theo ngày');
    expect(find.text('T2 · 08/09'), findsOneWidget);
    expect(find.text('CN · 14/09'), findsOneWidget);
    // Mặc định là thứ Tư (hôm nay) → Ngữ văn.
    expect(find.text('Ngữ văn'), findsOneWidget);

    await _tap(tester, 'T2 · 08/09');
    expect(find.text('Toán'), findsOneWidget);

    await _tap(tester, 'Tuần trước');
    expect(find.text('T2 · 01/09'), findsOneWidget);
    expect(find.text('Ngày này nằm ngoài học kỳ'), findsOneWidget);
    expect(find.text('Toán'), findsNothing);
  });
}
