import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class GradebookConflictFakeServer implements HttpClientAdapter {
  int version = 2;
  String? nextErrorCode;
  String? nextErrorMessage;
  int nextStatusCode = 409;
  bool returnRawConflict = false;

  @override
  void close({bool force = false}) {}

  Map<String, dynamic> get book => {
        'id': 7,
        'classId': 10,
        'subjectId': 20,
        'termId': 30,
        'className': '10A1',
        'subjectName': 'Toán',
        'termName': 'Học kỳ I',
        'status': 'DANG_NHAP_LIEU',
        'version': version,
        'pendingAdjustmentId': null,
        'resultsOutdated': false,
      };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body;
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
    } else if (options.path == '/api/v1/gradebooks' && options.method == 'GET') {
      body = {
        'items': [book],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/gradebooks/7/cells')) {
      body = {
        'book': book,
        'items': [
          {
            'id': '9001',
            'studentId': 101,
            'studentName': 'Nguyễn Văn An',
            'stt': 1,
            'active': true,
            'componentId': 201,
            'componentName': 'Miệng',
            'coefficient': '1.00',
            'required': true,
            'displayOrder': 1,
            'value': null,
            'status': 'CHUA_CO',
            'exemptionReason': null,
            'source': 'NHAP_TAY',
            'openForInput': true,
            'columnLocked': false,
          },
        ],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/gradebooks/7/missing-students')) {
      body = {'items': []};
    } else if (options.path.endsWith('/gradebooks/7/grades')) {
      if (returnRawConflict) {
        returnRawConflict = false;
        status = 409;
        body = {'message': 'Raw 409 conflict'};
      } else if (nextErrorCode != null) {
        status = nextStatusCode;
        body = {
          'code': nextErrorCode,
          'message': nextErrorMessage ?? 'Lỗi từ chối thao tác',
          'details': null,
          'requestId': 'req-conflict-test',
        };
        nextErrorCode = null;
      } else {
        version++;
        body = {
          'items': [
            {
              'id': '9001',
              'value': '8.5',
              'status': 'DA_DUYET',
              'source': 'NHAP_TAY',
            },
          ],
          'bookId': 7,
          'version': version,
        };
      }
    } else {
      status = 404;
      body = {'code': 'NOT_FOUND'};
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

Future<ProviderContainer> _pumpGradebook(
  WidgetTester tester,
  GradebookConflictFakeServer server,
) async {
  final dio = Dio()..httpClientAdapter = server;
  final api = ApiClientDart(dio: dio);
  final container = ProviderContainer(
    overrides: [apiProvider.overrideWithValue(api)],
  );

  await tester.runAsync(
    () => container
        .read(sessionProvider.notifier)
        .login('giao_vien_test', 'fake-password'),
  );

  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const GradebookApp(initialLocation: '/gradebooks/7'),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
      '409 code CELL_HAS_VALUE: không hiện banner xung đột, hiện thông báo "Ô đã có điểm…", giữ nguyên ô đang gõ',
      (tester) async {
    final server = GradebookConflictFakeServer()..nextErrorCode = 'CELL_HAS_VALUE';
    final container = await _pumpGradebook(tester, server);
    addTearDown(container.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final inputFinder = find.byKey(const ValueKey('grade-9001'));
    expect(inputFinder, findsOneWidget);

    // Người dùng gõ điểm
    await tester.enterText(inputFinder, '8.5');
    await tester.pumpAndSettle();

    // Bấm lưu
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    // Điền lý do và xác nhận
    await tester.enterText(
      find.widgetWithText(TextField, 'Lý do thay đổi'),
      'Nhập điểm miệng',
    );
    await tester.tap(find.text('Xác nhận lưu'));
    await tester.pumpAndSettle();

    // Không hiện banner xung đột
    expect(find.textContaining('đã thay đổi ở nơi khác'), findsNothing);

    // Hiện thông báo "Ô đã có điểm…"
    expect(find.textContaining('Ô đã có điểm'), findsOneWidget);

    // Giữ nguyên ô người dùng đang gõ
    final textFormField = tester.widget<TextFormField>(inputFinder);
    expect(textFormField.controller?.text, '8.5');

    // Lưới vẫn mở để chỉnh sửa (Save button vẫn hiển thị)
    expect(find.text('Lưu thay đổi'), findsOneWidget);
  });

  testWidgets(
      '409 code VERSION_OR_STATE_CONFLICT: hiện banner xung đột và yêu cầu tải lại',
      (tester) async {
    final server = GradebookConflictFakeServer()
      ..nextErrorCode = 'VERSION_OR_STATE_CONFLICT';
    final container = await _pumpGradebook(tester, server);
    addTearDown(container.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final inputFinder = find.byKey(const ValueKey('grade-9001'));
    await tester.enterText(inputFinder, '9.0');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Lý do thay đổi'),
      'Sửa điểm',
    );
    await tester.tap(find.text('Xác nhận lưu'));
    await tester.pumpAndSettle();

    // Bật banner xung đột
    expect(find.textContaining('đã thay đổi ở nơi khác'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Tải lại'), findsOneWidget);
  });

  testWidgets('409 không có code nghiệp vụ (raw 409): hiện banner xung đột',
      (tester) async {
    final server = GradebookConflictFakeServer()..returnRawConflict = true;
    final container = await _pumpGradebook(tester, server);
    addTearDown(container.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final inputFinder = find.byKey(const ValueKey('grade-9001'));
    await tester.enterText(inputFinder, '7.0');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Lý do thay đổi'),
      'Nhập điểm',
    );
    await tester.tap(find.text('Xác nhận lưu'));
    await tester.pumpAndSettle();

    // Bật banner xung đột
    expect(find.textContaining('đã thay đổi ở nơi khác'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Tải lại'), findsOneWidget);
  });
}
