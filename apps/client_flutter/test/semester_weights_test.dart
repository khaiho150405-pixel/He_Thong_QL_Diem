import 'dart:convert';
import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'phase1_test.dart' show FakeServer;

class WeightServer extends FakeServer {
  String coefficient = '3.00';
  bool saved = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    Object? body;
    if (path.contains('/catalog/semester-weights')) {
      if (options.method == 'PUT') {
        final input = jsonDecode(options.data as String) as Map;
        expect(input['loai_he_so'], 'CK');
        expect(input['ma_hoc_ky'], 1);
        coefficient = input['he_so'] as String;
        saved = true;
      }
      final row = {
        'ma_he_so': 1,
        'loai_he_so': 'CK',
        'ma_hoc_ky': 1,
        'he_so': coefficient,
        'label': 'Cuối kỳ · Học kỳ I · 2026-2027',
      };
      body = options.method == 'PUT'
          ? row
          : {
              'items': [row],
              'nextCursor': null,
            };
    } else if (path.endsWith('/catalog/components')) {
      body = {
        'items': [
          {
            'ma_thanh_phan': 1,
            'ma_mon': 1,
            'ten_thanh_phan': 'Cuối kỳ',
            'he_so': '2.00',
            'bat_buoc': true,
            'thu_tu_hien_thi': 1,
            'cho_phep_nhap': true,
            'label': 'Cuối kỳ · Toán',
          },
        ],
        'nextCursor': null,
      };
    } else if (path.endsWith('/catalog/semesters')) {
      body = {
        'items': [
          {
            'ma_hoc_ky': 1,
            'ma_nam_hoc': 1,
            'ten': 'Học kỳ I',
            'thu_tu': 1,
            'ngay_bat_dau': '2026-09-01',
            'ngay_ket_thuc': '2027-01-01',
            'label': 'Học kỳ I · 2026-2027',
          },
        ],
        'nextCursor': null,
      };
    } else if (path.contains('/catalog/')) {
      body = {'items': [], 'nextCursor': null};
    } else {
      return super.fetch(options, requestStream, cancelFuture);
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

void main() {
  for (final profile in [
    (platform: TargetPlatform.android, width: 360.0),
    (platform: TargetPlatform.iOS, width: 390.0),
    (platform: TargetPlatform.windows, width: 1366.0),
  ]) {
    testWidgets('edit semester coefficient on ${profile.platform}', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = profile.platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.view.physicalSize = Size(profile.width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final server = WeightServer()..logins = 1;
      final container = ProviderContainer(
        overrides: [
          apiProvider.overrideWithValue(
            ApiClientDart(dio: Dio()..httpClientAdapter = server),
          ),
        ],
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
          child: const GradebookApp(
            initialLocation: '/catalog/semester-weights',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hệ số: 3.00'), findsOneWidget);
      await tester.tap(find.text('Cuối kỳ · Học kỳ I · 2026-2027'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Hệ số riêng cho học kỳ'),
        '4.00',
      );
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(server.saved, isTrue);
      expect(find.text('Hệ số: 4.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
