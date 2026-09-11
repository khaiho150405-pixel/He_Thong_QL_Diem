import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class GradebookFakeServer implements HttpClientAdapter {
  int version = 2;
  bool locked = false;
  bool conflictNext = false;
  bool networkFailureNext = false;
  String? firstValue;
  String? lastIdempotencyKey;
  final batchKeys = <String>[];
  Map<String, dynamic>? lastBatch;

  @override
  void close({bool force = false}) {}

  Map<String, dynamic> get book => {
    'id': 7,
    'classId': 10,
    'subjectId': 20,
    'termId': 30,
    'status': locked ? 'DA_CHOT' : 'DANG_NHAP_LIEU',
    'version': version,
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
    } else if (options.path == '/api/v1/gradebooks' &&
        options.method == 'GET') {
      body = {
        'items': [book],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/gradebooks/7/cells') &&
        options.method == 'GET') {
      body = {
        'book': book,
        'items': [
          _cell('9001', 101, 'An', 201, 'Miệng', firstValue),
          _cell('9002', 101, 'An', 202, 'Giữa kỳ', '0.0'),
        ],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/gradebooks/7/grades')) {
      lastIdempotencyKey = options.headers['x-idempotency-key'] as String?;
      batchKeys.add(lastIdempotencyKey!);
      if (networkFailureNext) {
        networkFailureNext = false;
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'offline',
        );
      }
      if (conflictNext) {
        conflictNext = false;
        status = 409;
        body = {
          'code': 'VERSION_CONFLICT',
          'message': 'Version changed',
          'details': null,
          'requestId': 'test-conflict',
        };
      } else {
        expect(options.headers['x-csrf-token'], 'test-csrf');
        lastBatch = jsonDecode(options.data as String) as Map<String, dynamic>;
        firstValue =
            ((lastBatch!['changes'] as List).first as Map)['value'] as String?;
        version++;
        body = {
          'items': [
            {
              'id': '9001',
              'value': firstValue,
              'status': firstValue == null ? 'CHUA_CO' : 'DA_DUYET',
              'source': 'NHAP_TAY',
            },
          ],
          'bookId': 7,
          'version': version,
        };
      }
    } else if (options.path.endsWith('/sync-roster')) {
      expect(options.headers['x-idempotency-key'], isNotEmpty);
      version++;
      body = book;
    } else if (options.path.endsWith('/lock')) {
      expect(options.headers['x-idempotency-key'], isNotEmpty);
      locked = true;
      version++;
      body = book;
    } else if (options.path.endsWith('/cells/9001/history')) {
      body = {
        'items': [
          {
            'id': '44',
            'cellId': '9001',
            'editor': 2,
            'oldValue': null,
            'newValue': '0.0',
            'reason': 'Nhập điểm kiểm tra',
            'timestamp': '2026-09-11T01:02:03.000Z',
          },
        ],
        'nextCursor': null,
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

  Map<String, dynamic> _cell(
    String id,
    int studentId,
    String studentName,
    int componentId,
    String componentName,
    String? value,
  ) => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'active': true,
    'componentId': componentId,
    'componentName': componentName,
    'coefficient': componentId == 201 ? '1.0' : '2.0',
    'required': true,
    'displayOrder': componentId == 201 ? 1 : 2,
    'value': value,
    'status': value == null ? 'CHUA_CO' : 'DA_DUYET',
    'source': 'NHAP_TAY',
  };
}

Future<ProviderContainer> pumpGradebooks(
  WidgetTester tester,
  GradebookFakeServer server, {
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  final api = ApiClientDart(dio: Dio()..httpClientAdapter = server);
  final container = ProviderContainer(
    overrides: [apiProvider.overrideWithValue(api)],
  );
  await tester.runAsync(
    () => container
        .read(sessionProvider.notifier)
        .login('giao_vien_test', 'fake-password'),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const GradebookApp(initialLocation: '/gradebooks'),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('teacher keeps NULL separate from 0.0 and writes a batch', (
    tester,
  ) async {
    final server = GradebookFakeServer();
    final container = await pumpGradebooks(tester, server);
    addTearDown(container.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    expect(find.textContaining('Đang nhập liệu'), findsOneWidget);
    await tester.tap(find.textContaining('Lớp #10'));
    await tester.pumpAndSettle();

    final nullField = find.byKey(const ValueKey('grade-9001'));
    final zeroField = find.byKey(const ValueKey('grade-9002'));
    expect((tester.widget<TextFormField>(nullField).controller)!.text, '');
    expect((tester.widget<TextFormField>(zeroField).controller)!.text, '0.0');

    await tester.enterText(nullField, '0.0');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Lý do thay đổi'),
      'Nhập điểm kiểm tra',
    );
    await tester.tap(find.text('Xác nhận lưu'));
    await tester.pumpAndSettle();

    expect(server.lastIdempotencyKey, startsWith('flutter-batch-'));
    expect(server.lastBatch!['expectedVersion'], 2);
    final changes = server.lastBatch!['changes'] as List;
    expect(changes, hasLength(1));
    expect((changes.first as Map)['cellId'], '9001');
    expect((changes.first as Map)['value'], '0.0');
    expect((changes.first as Map)['reason'], 'Nhập điểm kiểm tra');
    expect(find.text('Phiên bản 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('conflict requires reload and wide grid stays usable', (
    tester,
  ) async {
    final server = GradebookFakeServer()..conflictNext = true;
    final container = await pumpGradebooks(tester, server, width: 1280);
    addTearDown(container.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.tap(find.textContaining('Lớp #10'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('grade-9001')), '8.5');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Lý do thay đổi'),
      'Sửa điểm theo bài chấm',
    );
    await tester.tap(find.text('Xác nhận lưu'));
    await tester.pumpAndSettle();

    expect(find.textContaining('đã thay đổi ở nơi khác'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Tải lại'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('network retry reuses the idempotency key for the same batch', (
    tester,
  ) async {
    final server = GradebookFakeServer()..networkFailureNext = true;
    final container = await pumpGradebooks(tester, server);
    addTearDown(container.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.tap(find.textContaining('Lớp #10'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('grade-9001')), '7.5');

    for (var attempt = 0; attempt < 2; attempt++) {
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Lý do thay đổi'),
        'Nhập lại sau lỗi mạng',
      );
      await tester.tap(find.text('Xác nhận lưu'));
      await tester.pumpAndSettle();
    }

    expect(server.batchKeys, hasLength(2));
    expect(server.batchKeys[1], server.batchKeys[0]);
    expect(find.text('Phiên bản 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history, roster sync and lock state are visible on mobile', (
    tester,
  ) async {
    final server = GradebookFakeServer()..firstValue = '9.0';
    final container = await pumpGradebooks(tester, server);
    addTearDown(container.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.tap(find.textContaining('Lớp #10'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Lịch sử').first);
    await tester.pumpAndSettle();
    expect(find.text('NULL → 0.0'), findsOneWidget);
    expect(find.textContaining('Nhập điểm kiểm tra'), findsOneWidget);
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đồng bộ sĩ số'));
    await tester.pumpAndSettle();
    expect(find.text('Phiên bản 3'), findsOneWidget);

    await tester.tap(find.text('Chốt bảng'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Chốt bảng'));
    await tester.pumpAndSettle();
    expect(server.locked, true);
    expect(find.text('Đã chốt'), findsWidgets);
    expect(find.text('Lưu thay đổi'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
