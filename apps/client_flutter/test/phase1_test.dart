import 'dart:convert';
import 'dart:typed_data';
import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeServer implements HttpClientAdapter {
  int logins = 0;
  bool created = false;
  String role = 'QUAN_TRI_VIEN';
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body;
    int status = 200;
    if (options.path.endsWith('/login')) {
      logins++;
      if (logins == 1) {
        status = 401;
        body = {
          'code': 'UNAUTHENTICATED',
          'message': 'Invalid',
          'details': null,
          'requestId': 'test',
        };
      } else {
        body = {
          'id': 1,
          'username': 'fake_user',
          'role': role,
          'active': true,
          'token': 'test-token',
          'csrf': 'test-csrf',
        };
      }
    } else if (options.path.endsWith('/logout')) {
      status = 204;
    } else if (options.path.endsWith('/catalog/years')) {
      final row = {
        'ma_nam_hoc': 1,
        'ten': '2026-2027',
        'ngay_bat_dau': '2026-09-01',
        'ngay_ket_thuc': '2027-06-01',
        'hien_hanh': true,
        'label': '2026-2027',
      };
      if (options.method == 'POST') {
        expect(options.headers['x-csrf-token'], 'test-csrf');
        expect((jsonDecode(options.data as String) as Map)['ten'], '2026-2027');
        created = true;
        body = row;
      } else {
        body = {
          'items': created ? [row] : [],
          'nextCursor': null,
        };
      }
    } else {
      status = 404;
      body = {};
    }
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

void main() => registerPhaseOneTests();
void registerPhaseOneTests({bool resize = true}) {
  for (final width in resize ? [390.0, 1280.0] : [390.0]) {
    testWidgets('login retry, create year and logout at width $width', (
      tester,
    ) async {
      if (resize) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      }
      final server = FakeServer();
      final dio = Dio()..httpClientAdapter = server;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiProvider.overrideWithValue(ApiClientDart(dio: dio))],
          child: const GradebookApp(initialLocation: '/'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tên đăng nhập'),
        'fake_user',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mật khẩu'),
        'fake-password',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Thông tin đăng nhập không đúng'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.pumpAndSettle();
      expect(find.text('Xin chào, fake_user'), findsOneWidget);
      await tester.tap(find.text('Năm học'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có dữ liệu phù hợp.'), findsOneWidget);
      await tester.tap(find.text('Thêm mới'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tên'),
        '2026-2027',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ngày bắt đầu'),
        '2026-09-01',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ngày kết thúc'),
        '2027-06-01',
      );
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('2026-2027'), findsOneWidget);
      expect(server.created, true);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Đăng nhập'), findsOneWidget);
      expect(dio.options.headers.containsKey('authorization'), false);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('student navigation only exposes personal records', (
    tester,
  ) async {
    final server = FakeServer()
      ..role = 'HOC_SINH'
      ..logins = 1;
    final api = ApiClientDart(dio: Dio()..httpClientAdapter = server);
    final container = ProviderContainer(
      overrides: [apiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    await tester.runAsync(
      () => container
          .read(sessionProvider.notifier)
          .login('fake', 'fake-password'),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const GradebookApp(initialLocation: '/'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Học sinh'), findsWidgets);
    expect(find.text('Tài khoản'), findsNothing);
    expect(find.text('Phân công'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
