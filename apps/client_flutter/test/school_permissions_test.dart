import 'dart:convert';
import 'dart:typed_data';
import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/features/authentication/profile_dialog.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'timetable_layout_test.dart' show TimetableFakeServer;

class SchoolServer extends TimetableFakeServer {
  SchoolServer(String role) : super(role: role);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/identity/profile')) {
      return ResponseBody.fromString(
        jsonEncode({'name': 'Hồ sơ thử nghiệm', 'email': null, 'phone': null}),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return super.fetch(options, requestStream, cancelFuture);
  }
}

void main() {
  for (final role in ['GIAO_VIEN', 'HOC_SINH']) {
    for (final width in [320.0, 1280.0]) {
      testWidgets('$role cannot open administrative catalog at $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderContainer(
          overrides: [
            apiProvider.overrideWithValue(
              ApiClientDart(dio: Dio()..httpClientAdapter = SchoolServer(role)),
            ),
          ],
        );
        addTearDown(container.dispose);
        await tester.runAsync(
          () => container
              .read(sessionProvider.notifier)
              .login('0000000000', 'test-password'),
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const GradebookApp(initialLocation: '/catalog/accounts'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          container
              .read(routerProvider('/catalog/accounts'))
              .routeInformationProvider
              .value
              .uri
              .path,
          '/',
        );
        expect(find.text('HỒ SƠ & DANH MỤC HỌC VỤ'), findsNothing);
        expect(find.text('DANH MỤC TRA CỨU'), findsNothing);
        expect(find.text('Nhận dạng & Duyệt OCR'), findsNothing);
        final edge = tester.getRect(
          find.byKey(const ValueKey('app-edge-scrollbar')),
        );
        expect(edge.left, 0);
        expect(edge.right, width);
        if (role == 'HOC_SINH') {
          expect(find.byTooltip('Đổi mật khẩu'), findsNothing);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
    testWidgets('$role profile name is read-only', (tester) async {
      final container = ProviderContainer(
        overrides: [
          apiProvider.overrideWithValue(
            ApiClientDart(dio: Dio()..httpClientAdapter = SchoolServer(role)),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.runAsync(
        () => container
            .read(sessionProvider.notifier)
            .login('0000000000', 'test-password'),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: ProfileDialog())),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Họ và tên'))
            .readOnly,
        isTrue,
      );
      if (role == 'HOC_SINH') expect(find.text('Lưu thay đổi'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
