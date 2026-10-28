import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/gradebooks/widgets/grade_cell.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sáu học sinh × ba cột. Cột 201 phủ các trạng thái của ô: nhập từ ảnh, nhập tay,
/// trống, chờ đối chiếu, miễn. Cột 202 ngoài lịch nhập (bảng chưa khóa). Cột 203
/// là Đạt/Không đạt.
class _Server implements HttpClientAdapter {
  _Server({required this.locked});
  final bool locked;

  Map<String, dynamic> get book => {
    'id': 7,
    'classId': 10,
    'subjectId': 20,
    'termId': 30,
    'className': '10A1',
    'subjectName': 'Toán',
    'termName': 'Học kỳ I',
    'status': locked ? 'DA_CHOT' : 'DANG_NHAP_LIEU',
    'version': 2,
    'pendingAdjustmentId': null,
    'resultsOutdated': false,
  };

  Map<String, dynamic> cell(
    int student,
    int component, {
    String? value,
    String status = 'DA_DUYET',
    String source = 'NHAP_TAY',
  }) => {
    'id': 'c${student}_$component',
    'studentId': 100 + student,
    'studentName': 'Học sinh $student',
    'stt': student,
    'active': true,
    'componentId': component,
    'componentName': switch (component) {
      201 => 'Miệng',
      202 => 'Giữa kỳ',
      _ => 'Thực hành',
    },
    'coefficient': '1.0',
    'required': true,
    'displayOrder': component - 200,
    'openForInput': !locked && component != 202,
    'columnLocked': locked,
    'passFail': component == 203,
    'value': value,
    'status': value == null && status == 'DA_DUYET' ? 'CHUA_CO' : status,
    'exemptionReason': status == 'MIEN' ? 'Miễn học' : null,
    'source': source,
  };

  List<Map<String, dynamic>> get cells => [
    for (var s = 1; s <= 6; s++) ...[
      switch (s) {
        1 => cell(s, 201, value: '8.0', source: 'NHAN_DIEN'),
        2 => cell(s, 201, value: '6.5'),
        3 => cell(s, 201),
        4 => cell(s, 201, status: 'CHO_DOI_CHIEU', source: 'NHAN_DIEN'),
        5 => cell(s, 201, status: 'MIEN'),
        _ => cell(s, 201, value: '10.0', source: 'NHAN_DIEN'),
      },
      cell(s, 202, value: '5.0', source: s == 2 ? 'NHAN_DIEN' : 'NHAP_TAY'),
      cell(
        s,
        203,
        value: switch (s) {
          1 || 4 => '10.0',
          2 || 6 => '0.0',
          _ => null,
        },
      ),
    ],
  ];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object body;
    var status = 200;
    if (options.path.endsWith('/login')) {
      body = {
        'id': 2,
        'username': 'giao_vien_test',
        'role': 'GIAO_VIEN',
        'active': true,
        'token': 'test-token',
        'csrf': 'test-csrf',
      };
    } else if (options.path.endsWith('/gradebooks/7/cells')) {
      body = {'book': book, 'items': cells, 'nextCursor': null};
    } else if (options.path.endsWith('/gradebooks/7/final-results')) {
      body = {'items': [], 'nextCursor': null};
    } else if (options.path.contains('/catalog/')) {
      body = {'items': [], 'nextCursor': null};
    } else {
      status = 404;
      body = {};
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  bool locked = false,
}) async {
  tester.view.physicalSize = Size(width, 8000); // đủ cao để dựng đủ 6 hàng
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      apiProvider.overrideWithValue(
        ApiClientDart(dio: Dio()..httpClientAdapter = _Server(locked: locked)),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.runAsync(
    () => container
        .read(sessionProvider.notifier)
        .login('giao_vien_test', 'fake-password'),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const GradebookApp(initialLocation: '/gradebooks/7'),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _frameOf(String key) => find.ancestor(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(GradeCellFrame),
);

Rect _rect(WidgetTester tester, String key) {
  expect(_frameOf(key), findsOneWidget, reason: 'Thiếu ô $key');
  return tester.getRect(_frameOf(key));
}

/// Khóa widget "giá trị" của ô tương ứng từng trạng thái ở cột 201.
const _col201 = [
  'grade-c1_201', // nhập từ ảnh
  'grade-c2_201', // nhập tay
  'grade-c3_201', // trống
  'grade-c4_201', // chờ đối chiếu
  'grade-exempt-c5_201', // miễn
  'grade-c6_201', // nhập từ ảnh
];

void main() {
  for (final width in [1440.0, 390.0]) {
    testWidgets(
      'mọi ô cùng cột cùng x, rộng, cao 40 ở mọi trạng thái, $width',
      (tester) async {
        await _pump(tester, width: width);
        final rects = [for (final k in _col201) _rect(tester, k)];
        for (final r in rects) {
          expect(r.left, closeTo(rects.first.left, .5));
          expect(r.width, closeTo(rects.first.width, .5));
          expect(r.height, closeTo(gradeCellHeight, .01));
        }
        // Cột 202 (ngoài lịch nhập) và cột Đạt/Không đạt cũng cùng khung.
        final out = [
          for (var s = 1; s <= 6; s++) _rect(tester, 'grade-c${s}_202'),
        ];
        final pf = [
          for (var s = 1; s <= 6; s++) _rect(tester, 'grade-pf-c${s}_203'),
        ];
        for (final group in [out, pf]) {
          for (final r in group) {
            expect(r.left, closeTo(group.first.left, .5));
            expect(r.width, closeTo(group.first.width, .5));
            expect(r.height, closeTo(gradeCellHeight, .01));
          }
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('chữ số nằm đúng tâm ô, thẳng hàng giữa các hàng, $width', (
      tester,
    ) async {
      await _pump(tester, width: width);
      double offset(String valueKey, Finder valueWidget) =>
          tester.getCenter(valueWidget).dx - _rect(tester, valueKey).center.dx;
      for (final k in ['grade-c1_201', 'grade-c2_201', 'grade-c6_201']) {
        final text = find.descendant(
          of: find.byKey(ValueKey(k)),
          matching: find.byType(EditableText),
        );
        expect(offset(k, text), closeTo(0, 1), reason: k);
      }
      final exempt = find.byKey(const ValueKey('grade-exempt-c5_201'));
      expect(offset('grade-exempt-c5_201', exempt), closeTo(0, 1));
      // Số của hai ô khác nhau (có/không AI) cùng một tâm ngang tuyệt đối.
      final a = tester.getCenter(
        find.descendant(
          of: find.byKey(const ValueKey('grade-c1_201')),
          matching: find.byType(EditableText),
        ),
      );
      final b = tester.getCenter(
        find.descendant(
          of: find.byKey(const ValueKey('grade-c2_201')),
          matching: find.byType(EditableText),
        ),
      );
      expect((a.dx - b.dx).abs(), lessThanOrEqualTo(1));
    });

    testWidgets('không helperText dưới ô; trạng thái là tooltip, $width', (
      tester,
    ) async {
      await _pump(tester, width: width);
      for (final d in tester.widgetList<InputDecorator>(
        find.byType(InputDecorator),
      )) {
        expect(d.decoration.helperText, isNull);
      }
      expect(find.text('Chưa có điểm'), findsNothing);
      expect(find.byTooltip('Chưa có điểm'), findsWidgets);
      expect(find.byTooltip('Chờ đối chiếu'), findsWidgets);
      expect(find.byTooltip('Ngoài lịch nhập'), findsWidgets);
      expect(find.byTooltip('Nhập từ ảnh'), findsWidgets);
      // Chấm AI nằm trong khung ô, không còn nhãn "● AI" bên ngoài.
      expect(find.text('● AI'), findsNothing);
      expect(
        find.descendant(
          of: _frameOf('grade-c1_201'),
          matching: find.byTooltip('Nhập từ ảnh'),
        ),
        findsOneWidget,
      );
      // Ô trống hiện "—" mờ ở giữa.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('grade-c3_201')),
          matching: find.text('—'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'cột đã chốt: ô chỉ đọc cùng khung, tooltip "Cột đã chốt", $width',
      (tester) async {
        await _pump(tester, width: width, locked: true);
        for (final k in _col201) {
          expect(
            _rect(tester, k).height,
            closeTo(gradeCellHeight, .01),
            reason: k,
          );
        }
        final lefts = {for (final k in _col201) _rect(tester, k).left.round()};
        expect(lefts.length, 1);
        expect(find.byTooltip('Cột đã chốt'), findsWidgets);
        // Biểu tượng khóa đã có ở tiêu đề cột: trong ô không lặp lại.
        expect(
          find.descendant(
            of: find.byType(GradeCellFrame),
            matching: find.byIcon(Icons.lock_rounded),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('chú thích có Cột đã chốt, Chờ đối chiếu, Ô miễn', (
    tester,
  ) async {
    await _pump(tester, width: 1440);
    final legend = find.byKey(const ValueKey('gradebook-legend'));
    for (final label in [
      'Ô đã sửa',
      'Nhập từ ảnh',
      'Điểm không hợp lệ',
      'Cột đã chốt',
      'Ngoài lịch nhập',
      'Chờ đối chiếu',
      'Ô miễn',
    ]) {
      expect(
        find.descendant(of: legend, matching: find.text(label)),
        findsOneWidget,
        reason: label,
      );
    }
  });

  for (final width in [320.0, 390.0, 1100.0]) {
    testWidgets('không overflow ở $width px', (tester) async {
      await _pump(tester, width: width);
      expect(tester.takeException(), isNull);
      // Bảng đã khóa: nút "Yêu cầu điều chỉnh" xuống dòng, không tràn ngang.
      await _pump(tester, width: width, locked: true);
      expect(
        find.byKey(const ValueKey('request-adjustment-btn')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
