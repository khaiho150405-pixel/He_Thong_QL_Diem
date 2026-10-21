import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _UxFakeServer implements HttpClientAdapter {
  _UxFakeServer({this.includeSummary = false});

  final bool includeSummary;

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
        'username': 'gv_test',
        'role': 'GIAO_VIEN',
        'active': true,
        'token': 'test-token',
        'csrf': 'test-csrf',
      };
    } else if (options.path.endsWith('/catalog/years')) {
      body = {
        'items': [
          {'ma_nam_hoc': 1, 'ten': '2026-2027', 'hien_hanh': true},
        ],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/gradebooks') &&
        options.method == 'GET') {
      body = {
        'items': [
          {
            'id': 1,
            'classId': 10,
            'subjectId': 20,
            'termId': 30,
            'className': '10A1',
            'subjectName': 'Toán',
            'termName': 'Học kỳ I',
            'status': 'DANG_NHAP_LIEU',
            'version': 1,
          },
          {
            'id': 2,
            'classId': 11,
            'subjectId': 21,
            'termId': 30,
            'className': '10A2',
            'subjectName': 'Ngữ văn',
            'termName': 'Học kỳ I',
            'status': 'DA_CHOT',
            'version': 2,
          },
        ],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/gradebooks/1/cells')) {
      body = {
        'book': {
          'id': 1,
          'classId': 10,
          'subjectId': 20,
          'termId': 30,
          'className': '10A1',
          'subjectName': 'Toán',
          'termName': 'Học kỳ I',
          'status': 'DANG_NHAP_LIEU',
          'version': 1,
        },
        'items': [
          {
            'id': '901',
            'studentId': 101,
            'studentName': 'Nguyễn Văn An',
            'stt': 1,
            'active': true,
            'componentId': 201,
            'componentName': 'Cuối kỳ',
            'coefficient': '2.00',
            'required': true,
            'displayOrder': 1,
            'value': '8.5',
            'status': 'DA_DUYET',
            'source': 'NHAP_TAY',
          },
          {
            'id': '902',
            'studentId': 102,
            'studentName': 'Trần Thị Bích',
            'stt': 2,
            'active': true,
            'componentId': 201,
            'componentName': 'Cuối kỳ',
            'coefficient': '2.00',
            'required': true,
            'displayOrder': 1,
            'value': '6.5',
            'status': 'DA_DUYET',
            'source': 'NHAP_TAY',
          },
        ],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/gradebooks/1/final-results') &&
        options.method == 'GET') {
      body = {
        'items': [
          {
            'id': '501',
            'studentId': 101,
            'studentName': 'Nguyễn Văn An',
            'finalScore': '8.5',
            'classification': 'GIOI',
            'weightVersion': 'W-012345678901234567',
            'policyVersion': 'DEV-2026-01',
            'calculatedAt': '2026-09-13T01:00:00.000Z',
          },
          {
            'id': '502',
            'studentId': 102,
            'studentName': 'Trần Thị Bích',
            'finalScore': '6.5',
            'classification': 'CHUA_CONG_BO',
            'weightVersion': 'W-012345678901234567',
            'policyVersion': 'DEV-2026-01',
            'calculatedAt': '2026-09-13T01:00:00.000Z',
          },
        ],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/reports/gradebooks/1/summary')) {
      body = {
        'gradebookId': 1,
        'students': 2,
        'average': '7.5',
        'highest': '8.5',
        'lowest': '6.5',
        'passed': 2,
        'failed': 0,
        'distribution': [
          {'classification': 'GIOI', 'students': 1},
          {'classification': 'CHUA_CONG_BO', 'students': 1},
        ],
      };
    } else if (options.path.endsWith('/final-results/calculate')) {
      body = {
        'gradebookId': 1,
        'gradebookVersion': 1,
        'weightVersion': 'W-012345678901234567',
        'policyVersion': 'DEV-2026-01',
        'calculatedStudents': 2,
        'skippedStudents': 1,
        'exemptedStudents': 1,
        'results': [],
        'exempted': [
          {
            'studentId': 103,
            'studentName': 'Lê Văn Miễn',
            'reason': 'Miễn học theo quyết định',
          },
        ],
        'skipped': [
          {
            'studentId': 104,
            'studentName': 'Phạm Văn Thiếu',
            'missingComponents': [
              {
                'componentId': 201,
                'name': 'Điểm miệng',
              },
            ],
          },
        ],
      };
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

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  double width = 1200,
  bool includeSummary = false,
}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1;

  final api = ApiClientDart(
    dio: Dio()..httpClientAdapter = _UxFakeServer(includeSummary: includeSummary),
  );
  final container = ProviderContainer(
    overrides: [apiProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.runAsync(
    () => container
        .read(sessionProvider.notifier)
        .login('gv_test', 'fake-password'),
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const GradebookApp(initialLocation: '/final-results'),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('chế độ danh sách hiển thị bảng gọn và chuyển sang chi tiết khi bấm Xem', (
    tester,
  ) async {
    await _pumpApp(tester);

    // Chế độ danh sách: các cột của bảng điểm
    expect(find.text('Tổng kết & xếp loại'), findsWidgets);
    expect(find.text('Lớp'), findsOneWidget);
    expect(find.text('Môn học'), findsWidgets);
    expect(find.text('Học kỳ'), findsWidgets);
    expect(find.text('Trạng thái'), findsOneWidget);
    expect(find.text('Thao tác'), findsOneWidget);

    expect(find.text('10A1'), findsOneWidget);
    expect(find.text('10A2'), findsOneWidget);
    expect(find.text('Toán'), findsOneWidget);
    expect(find.text('Ngữ văn'), findsOneWidget);

    // Bấm nút "Xem" của bảng điểm 10A1
    await tester.tap(find.byKey(const ValueKey('view-gradebook-1')));
    await tester.pumpAndSettle();

    // Vào chế độ chi tiết
    expect(find.text('10A1 – Toán – Học kỳ I'), findsOneWidget);
    expect(find.byKey(const ValueKey('back-to-gradebook-list')), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('Trần Thị Bích'), findsOneWidget);

    // Bấm nút quay lại danh sách
    await tester.tap(find.byKey(const ValueKey('back-to-gradebook-list')));
    await tester.pumpAndSettle();

    // Trở về chế độ danh sách
    expect(find.text('10A1'), findsOneWidget);
    expect(find.text('10A2'), findsOneWidget);
  });

  testWidgets('chi tiết không lặp "Hệ số W-" ở từng dòng và CHUA_CONG_BO hiện "Chưa công bố"', (
    tester,
  ) async {
    await _pumpApp(tester);

    // Mở chi tiết bảng điểm 1
    await tester.tap(find.byKey(const ValueKey('view-gradebook-1')));
    await tester.pumpAndSettle();

    // "Hệ số W-" chỉ hiển thị đúng 1 lần ở dòng thông tin chung đầu bảng
    expect(
      find.textContaining('Hệ số W-012345678901234567'),
      findsOneWidget,
    );
    expect(find.textContaining('Chính sách DEV-2026-01'), findsOneWidget);
    expect(find.textContaining('Tính lúc '), findsOneWidget);

    // CHUA_CONG_BO ánh xạ thành nhãn tiếng Việt "Chưa công bố"
    expect(find.text('Chưa công bố'), findsWidgets);
    expect(find.text('CHUA_CONG_BO'), findsNothing);

    // Điểm số và xếp loại của từng dòng hiển thị gọn
    expect(find.text('8.5'), findsWidgets);
    expect(find.text('6.5'), findsWidgets);
    expect(find.text('Giỏi'), findsWidgets);
  });

  testWidgets('tìm theo tên học sinh lọc đúng danh sách', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('view-gradebook-1')));
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('Trần Thị Bích'), findsOneWidget);

    // Nhập tìm 'Bích'
    await tester.enterText(
      find.byKey(const ValueKey('final-results-search')),
      'Bích',
    );
    await tester.pumpAndSettle();

    expect(find.text('Trần Thị Bích'), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsNothing);

    // Xóa tìm kiếm
    await tester.enterText(
      find.byKey(const ValueKey('final-results-search')),
      '',
    );
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('Trần Thị Bích'), findsOneWidget);
  });

  testWidgets('nhóm Miễn môn và Thiếu điểm hiển thị dạng danh sách khi tính kết quả', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('view-gradebook-1')));
    await tester.pumpAndSettle();

    // Bấm tính kết quả
    await tester.tap(find.byKey(const ValueKey('calculate-final-results')).first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Lý do tính hoặc tính lại'),
      'Tổng kết học kỳ I',
    );
    await tester.tap(find.text('Tính kết quả').last);
    await tester.pumpAndSettle();

    // Chọn nhóm "Miễn môn"
    await tester.ensureVisible(find.byKey(const ValueKey('group-tab-exempted')));
    await tester.tap(find.byKey(const ValueKey('group-tab-exempted')));
    await tester.pumpAndSettle();

    expect(find.text('Lê Văn Miễn'), findsOneWidget);
    expect(find.text('Miễn môn'), findsWidgets);

    // Chọn nhóm "Thiếu điểm"
    await tester.ensureVisible(find.byKey(const ValueKey('group-tab-skipped')));
    await tester.tap(find.byKey(const ValueKey('group-tab-skipped')));
    await tester.pumpAndSettle();

    expect(find.text('Phạm Văn Thiếu'), findsOneWidget);
    expect(find.text('Thiếu điểm'), findsWidgets);
    expect(find.text('Điểm miệng'), findsOneWidget);

    // Chọn lại "Tất cả"
    await tester.ensureVisible(find.byKey(const ValueKey('group-tab-all')));
    await tester.tap(find.byKey(const ValueKey('group-tab-all')));
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('Trần Thị Bích'), findsOneWidget);
  });
}
