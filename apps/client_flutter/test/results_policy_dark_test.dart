import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/widgets/app_badge.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/connection/connection.dart';
import 'package:client_flutter/features/final_results/student_results_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Máy chủ giả cho bước 4: điểm của học sinh, chính sách xếp loại.
class _FakeServer implements HttpClientAdapter {
  _FakeServer(this.role);

  final String role;

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
        'id': role == 'HOC_SINH' ? 4 : 1,
        'username': 'step4_test',
        'role': role,
        'active': true,
        'token': 'test-token',
        'csrf': 'test-csrf',
      };
    } else if (options.path.endsWith('/students/me/results')) {
      body = {
        'items': [
          _subject('Toán', '8.4', 'GIOI'),
          _subject('Ngữ văn', '6.8', 'KHA'),
          _subject('Vật lý', '5.2', 'DAT'),
          _subject('Hóa học', '3.1', 'YEU'),
          _subject('Sinh học', '7.0', 'XUAT_SAC_LA'),
          {
            ..._subject('Lịch sử', null, null),
            'components': <Object>[],
            'calculatedAt': null,
          },
        ],
        'summary': {
          'termId': 30,
          'termName': 'Học kỳ I',
          'className': '10A1',
          'averageScore': '6.50',
          'publishedSubjects': 5,
          'totalSubjects': 6,
          'classRank': 3,
          'classSize': 38,
        },
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

  Map<String, dynamic> _subject(String name, String? score, String? code) => {
    'gradebookId': 7,
    'subjectId': name.hashCode.abs() % 1000,
    'subjectName': name,
    'termId': 30,
    'termName': 'Học kỳ I',
    'components': [
      {
        'componentId': 201,
        'componentName': 'Cuối kỳ',
        'coefficient': '2.00',
        'value': score ?? '5.0',
      },
    ],
    'finalScore': score,
    'classification': code,
    'calculatedAt': score == null ? null : '2026-09-13T01:00:00.000Z',
  };
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required String role,
  required String location,
  required double width,
  required Brightness mode,
  double height = 900,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.platformBrightnessTestValue = mode;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final api = ApiClientDart(dio: Dio()..httpClientAdapter = _FakeServer(role));
  final container = ProviderContainer(
    overrides: [
      apiProvider.overrideWithValue(api),
      connectionProvider.overrideWith((ref) async {}),
    ],
  );
  addTearDown(container.dispose);
  await tester.runAsync(
    () => container
        .read(sessionProvider.notifier)
        .login('step4_test', 'fake-password'),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: GradebookApp(initialLocation: location),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  test('classificationBadgeOf ánh xạ theo mã, mã lạ giữ nguyên chuỗi', () {
    expect(classificationBadgeOf('GIOI').tone, AppBadgeTone.ok);
    expect(classificationBadgeOf('GIOI').label, 'Giỏi');
    expect(classificationBadgeOf('KHA').tone, AppBadgeTone.info);
    expect(classificationBadgeOf('DAT').tone, AppBadgeTone.neutral);
    expect(classificationBadgeOf('YEU').tone, AppBadgeTone.bad);
    expect(classificationBadgeOf('CHUA_DAT').label, 'Chưa đạt');
    final unknown = classificationBadgeOf('XUAT_SAC_LA');
    expect(unknown.tone, AppBadgeTone.neutral);
    expect(unknown.label, 'XUAT_SAC_LA');
  });

  for (final mode in Brightness.values) {
    for (final width in [390.0, 1280.0]) {
      final tag = '${mode.name} ${width.toInt()}px';

      testWidgets('Điểm của tôi: thẻ và bảng, $tag', (tester) async {
        await _pump(
          tester,
          role: 'HOC_SINH',
          location: '/my-results',
          width: width,
          mode: mode,
        );
        final tokens = Theme.of(
          tester.element(find.byType(StudentResultsScreen)),
        ).extension<AppTokens>()!;
        expect(tokens.brightness, mode);
        expect(find.text('Bảng điểm cá nhân'), findsOneWidget);
        expect(find.textContaining('THPT Bà Điểm · Học kỳ I'), findsOneWidget);
        expect(find.text('6.5'), findsWidgets);
        expect(find.text('3 / 38'), findsOneWidget);
        expect(find.text('5 / 6'), findsOneWidget);
        expect(find.textContaining('Mã học sinh'), findsNothing);
        // Mã lạ giữ nguyên chuỗi, vẫn là badge.
        expect(find.text('7.0 · XUAT_SAC_LA'), findsOneWidget);
        expect(find.text('8.4 · GIOI'), findsOneWidget);
        expect(find.text('Chờ chốt ĐTB'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Bảng tổng hợp'));
        await tester.pumpAndSettle();
        expect(find.text('Giỏi'), findsOneWidget);
        expect(find.text('Khá'), findsOneWidget);
        expect(find.text('Đạt'), findsOneWidget);
        expect(find.text('Yếu'), findsOneWidget);
        expect(find.text('XUAT_SAC_LA'), findsOneWidget);
        expect(find.text('ĐIỂM TRUNG BÌNH CHUNG'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Thẻ theo môn'));
        await tester.pumpAndSettle();
        expect(find.text('Toán'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Chính sách xếp loại, $tag', (tester) async {
        await _pump(
          tester,
          role: 'QUAN_TRI_VIEN',
          location: '/classification-policy',
          width: width,
          mode: mode,
          height: 1800,
        );
        expect(find.text('Chính sách xếp loại'), findsOneWidget);
        expect(
          find.text('Phiên bản DEV-2026-01 · đang áp dụng'),
          findsOneWidget,
        );
        expect(find.text('GIOI'), findsOneWidget);
        expect(find.text('YEU'), findsOneWidget);
        expect(find.byKey(const ValueKey('policy-version')), findsOneWidget);
        expect(find.byKey(const ValueKey('activate-policy')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Kết nối, $tag', (tester) async {
        await _pump(
          tester,
          role: 'QUAN_TRI_VIEN',
          location: '/connection',
          width: width,
          mode: mode,
        );
        expect(find.text('Kết nối thành công'), findsOneWidget);
        final tokens = Theme.of(
          tester.element(find.byType(ConnectionScreen)),
        ).extension<AppTokens>()!;
        expect(tokens.brightness, mode);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
