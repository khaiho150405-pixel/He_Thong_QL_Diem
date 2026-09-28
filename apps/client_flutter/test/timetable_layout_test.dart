import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/features/academic_catalog/edit_dialog.dart';
import 'package:client_flutter/features/academic_catalog/fields.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/timetable/timetable_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class TimetableFakeServer implements HttpClientAdapter {
  TimetableFakeServer({
    this.role = 'QUAN_TRI_VIEN',
    this.denseTimetable = false,
  });

  final String role;
  final bool denseTimetable;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object body;
    if (options.path.endsWith('/identity/login')) {
      body = {
        'id': 1,
        'username': 'admin',
        'role': role,
        'active': true,
        'token': 'token',
        'csrf': 'csrf',
      };
    } else if (options.path.endsWith('/catalog/classes')) {
      body = {
        'items': [
          {
            'ma_lop': 1,
            'ma_nam_hoc': 1,
            'ma_gv_chu_nhiem': 10,
            'ten_lop': '10A1',
            'khoi': 10,
            'label': '10A1',
          },
          {
            'ma_lop': 2,
            'ma_nam_hoc': 1,
            'ma_gv_chu_nhiem': 11,
            'ten_lop': '10A2',
            'khoi': 10,
            'label': '10A2',
          },
        ],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/catalog/teachers') ||
        options.path.endsWith('/catalog/assignments') ||
        options.path.endsWith('/catalog/semesters')) {
      body = {'items': [], 'nextCursor': null};
    } else if (options.path.endsWith('/identity/accounts')) {
      body = {'items': [], 'nextCursor': null};
    } else if (options.path.endsWith('/timetable')) {
      body = {
        'items': denseTimetable
            ? [
                for (var period = 1; period <= 10; period++)
                  _slot(period, 1, '10A1', 'Môn $period', period: period),
              ]
            : [_slot(1, 1, '10A1', 'Toán'), _slot(2, 2, '10A2', 'Ngữ văn')],
        'total': denseTimetable ? 10 : 2,
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

  Map<String, Object?> _slot(
    int id,
    int classId,
    String className,
    String subject, {
    int period = 1,
  }) => {
    'ma_tiet_hoc': id,
    'ma_lop': classId,
    'ten_lop': className,
    'ma_mon': id,
    'ten_mon': subject,
    'ma_giao_vien': id + 10,
    'ten_giao_vien': 'Giáo viên $id',
    'ma_hoc_ky': 1,
    'ten_hoc_ky': 'Học kỳ 1',
    'thu': 2,
    'tiet': period,
    'phong_hoc': 'P.$className',
    'ghi_chu': null,
  };
}

void main() {
  testWidgets('whole-school weekly view renders one table per class', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClientDart(
      dio: Dio()..httpClientAdapter = TimetableFakeServer(),
    );
    final container = ProviderContainer(
      overrides: [apiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    await tester.runAsync(
      () => container
          .read(sessionProvider.notifier)
          .login('admin', 'password-for-test'),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TimetableScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lớp 10A1'), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('Lớp 10A2'), findsOneWidget);
    expect(find.textContaining('lớp khác'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('teacher CRUD offers account creation when no account is free', (
    tester,
  ) async {
    final api = ApiClientDart(
      dio: Dio()..httpClientAdapter = TimetableFakeServer(),
    );
    final container = ProviderContainer(
      overrides: [apiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    await tester.runAsync(
      () => container
          .read(sessionProvider.notifier)
          .login('admin', 'password-for-test'),
    );
    final teacherSpec = resources.firstWhere((item) => item.key == 'teachers');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: EditDialog(spec: teacherSpec)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Không còn tài khoản giáo viên chưa liên kết.'),
      findsOneWidget,
    );
    expect(find.text('Tạo tài khoản giáo viên mới'), findsOneWidget);
    await tester.tap(find.text('Tạo tài khoản giáo viên mới'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo tài khoản giáo viên'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final profile in const [
    (role: 'GIAO_VIEN', size: Size(900, 560)),
    (role: 'HOC_SINH', size: Size(900, 560)),
    (role: 'GIAO_VIEN', size: Size(844, 390)),
    (role: 'HOC_SINH', size: Size(320, 568)),
  ]) {
    final role = profile.role;
    testWidgets(
      '$role can scroll the weekly timetable vertically ${profile.size}',
      (tester) async {
        tester.view.physicalSize = profile.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = ApiClientDart(
          dio: Dio()
            ..httpClientAdapter = TimetableFakeServer(
              role: role,
              denseTimetable: true,
            ),
        );
        final container = ProviderContainer(
          overrides: [apiProvider.overrideWithValue(api)],
        );
        addTearDown(container.dispose);
        await tester.runAsync(
          () => container
              .read(sessionProvider.notifier)
              .login('viewer', 'password-for-test'),
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: TimetableScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final scroll = find.byKey(
          const ValueKey('timetable-weekly-vertical-scroll'),
        );
        expect(scroll, findsOneWidget);
        final before = tester.getTopLeft(find.text('T10')).dy;
        await tester.drag(scroll, const Offset(0, -500));
        await tester.pumpAndSettle();
        final after = tester.getTopLeft(find.text('T10')).dy;
        expect(after, lessThan(before));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'timetable header remains readable on a narrow large-text phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final api = ApiClientDart(
        dio: Dio()..httpClientAdapter = TimetableFakeServer(),
      );
      final container = ProviderContainer(
        overrides: [apiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      await tester.runAsync(
        () => container
            .read(sessionProvider.notifier)
            .login('admin', 'password-for-test'),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TimetableScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thời khóa biểu toàn trường'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
