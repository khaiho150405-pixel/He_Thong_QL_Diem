import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class Phase5FakeServer implements HttpClientAdapter {
  Phase5FakeServer(this.role);

  final String role;
  Map<String, dynamic>? calculateBody;
  String? calculateKey;

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
        'id': role == 'HOC_SINH' ? 4 : 2,
        'username': 'phase5_test',
        'role': role,
        'active': true,
        'token': 'test-token',
        'csrf': 'test-csrf',
      };
    } else if (options.path.endsWith('/gradebooks/7/cells')) {
      body = {
        'book': {
          'id': 7,
          'classId': 10,
          'subjectId': 20,
          'termId': 30,
          'status': 'DA_CHOT',
          'version': 4,
        },
        'items': [
          {
            'id': '9001',
            'studentId': 101,
            'studentName': 'An',
            'active': true,
            'componentId': 201,
            'componentName': 'Cuối kỳ',
            'coefficient': '2.00',
            'required': true,
            'displayOrder': 1,
            'value': '0.0',
            'status': 'DA_DUYET',
            'source': 'NHAP_TAY',
          },
        ],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/gradebooks/7/final-results') &&
        options.method == 'GET') {
      body = {
        'items': [_result],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/final-results/calculate')) {
      calculateBody =
          jsonDecode(options.data as String) as Map<String, dynamic>;
      calculateKey = options.headers['x-idempotency-key'] as String?;
      body = {
        'gradebookId': 7,
        'gradebookVersion': 4,
        'weightVersion': 'W-012345678901234567',
        'policyVersion': 'DEV-2026-01',
        'calculatedStudents': 1,
        'skippedStudents': 0,
        'results': [_result],
        'skipped': [],
      };
    } else if (options.path.endsWith('/reports/gradebooks/7/summary')) {
      body = {
        'gradebookId': 7,
        'students': 1,
        'average': '0.0',
        'highest': '0.0',
        'lowest': '0.0',
        'passed': 0,
        'failed': 1,
        'distribution': [
          {'classification': 'YEU', 'students': 1},
        ],
      };
    } else if (options.path.contains('/recognition-tickets')) {
      body = {'items': [], 'nextCursor': null};
    } else if (options.path.endsWith('/students/me/results')) {
      body = {
        'items': [
          {
            'gradebookId': 7,
            'subjectId': 20,
            'subjectName': 'Toán',
            'termId': 30,
            'termName': 'Học kỳ I',
            'components': [
              {
                'componentId': 201,
                'componentName': 'Cuối kỳ',
                'coefficient': '2.00',
                'value': '0.0',
              },
            ],
            'finalScore': '6.5',
            'classification': 'KHA',
            'calculatedAt': '2026-09-13T01:00:00.000Z',
          },
        ],
      };
    } else if (options.path.endsWith('/classification-policies/active')) {
      body = {
        'version': 'DEV-2026-01',
        'name': 'Mặc định development',
        'roundingDigits': 1,
        'active': true,
        'criteria': [
          {'code': 'GIOI', 'minimum': '8.0', 'passing': true, 'order': 1},
          {'code': 'YEU', 'minimum': '0.0', 'passing': false, 'order': 2},
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

  Map<String, dynamic> get _result => {
    'id': '501',
    'studentId': 101,
    'studentName': 'An',
    'finalScore': '0.0',
    'classification': 'YEU',
    'weightVersion': 'W-012345678901234567',
    'policyVersion': 'DEV-2026-01',
    'calculatedAt': '2026-09-13T01:00:00.000Z',
  };
}

Future<ProviderContainer> pumpPhase5(
  WidgetTester tester,
  Phase5FakeServer server,
  String initialLocation, {
  double width = 1280,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  final api = ApiClientDart(dio: Dio()..httpClientAdapter = server);
  final container = ProviderContainer(
    overrides: [apiProvider.overrideWithValue(api)],
  );
  await tester.runAsync(
    () => container
        .read(sessionProvider.notifier)
        .login('phase5_test', 'fake-password'),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: GradebookApp(initialLocation: initialLocation),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('teacher calculates locked gradebook and sees UC16 summary', (
    tester,
  ) async {
    final server = Phase5FakeServer('GIAO_VIEN');
    final container = await pumpPhase5(tester, server, '/gradebooks/7');
    addTearDown(container.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    expect(find.text('Kết quả tổng kết'), findsOneWidget);
    expect(find.text('Thống kê và báo cáo'), findsOneWidget);
    expect(find.text('0.0'), findsWidgets);
    expect(find.text('Xuất Excel'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('calculate-final-results')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Lý do tính hoặc tính lại'),
      'Tổng kết học kỳ I',
    );
    await tester.tap(find.text('Tính kết quả').last);
    await tester.pumpAndSettle();
    expect(server.calculateBody?['expectedVersion'], 4);
    expect(server.calculateBody?['reason'], 'Tổng kết học kỳ I');
    expect(server.calculateKey, startsWith('flutter-final-'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'student self view preserves 0.0 and shows no arbitrary student picker',
    (tester) async {
      final server = Phase5FakeServer('HOC_SINH');
      final container = await pumpPhase5(
        tester,
        server,
        '/my-results',
        width: 390,
      );
      addTearDown(container.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      expect(find.text('Điểm của tôi'), findsOneWidget);
      expect(find.text('Toán'), findsOneWidget);
      expect(find.text('Cuối kỳ'), findsOneWidget);
      expect(find.text('0.0'), findsOneWidget);
      expect(find.text('6.5 · KHA'), findsOneWidget);
      expect(find.textContaining('Mã học sinh'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('administrator sees versioned classification policy editor', (
    tester,
  ) async {
    final server = Phase5FakeServer('QUAN_TRI_VIEN');
    final container = await pumpPhase5(
      tester,
      server,
      '/classification-policy',
    );
    addTearDown(container.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    expect(find.text('Chính sách xếp loại'), findsOneWidget);
    expect(find.text('GIOI'), findsOneWidget);
    expect(find.text('YEU'), findsOneWidget);
    expect(find.byKey(const ValueKey('activate-policy')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
