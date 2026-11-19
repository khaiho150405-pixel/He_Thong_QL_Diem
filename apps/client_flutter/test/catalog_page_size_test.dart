import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/features/academic_catalog/edit_dialog.dart';
import 'package:client_flutter/features/academic_catalog/fields.dart';
import 'package:client_flutter/app/widgets/app_select_field.dart';
import 'package:client_flutter/features/academic_catalog/repository.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _PagedServer implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  final List<Map<String, dynamic>> accounts = [
    for (var i = 1; i <= 1200; i++)
      {
        'id': i,
        'username': '09${i.toString().padLeft(8, '0')}',
        'role': 'HOC_SINH',
        'active': true,
      },
    for (var i = 1201; i <= 1800; i++)
      {
        'id': i,
        'username': '09${i.toString().padLeft(8, '0')}',
        'role': 'GIAO_VIEN',
        'active': true,
      },
  ];
  final classes = [
    for (var i = 1; i <= 40; i++)
      {
        'ma_lop': i,
        'ma_nam_hoc': 1,
        'ma_gv_chu_nhiem': 1,
        'ten_lop': 'Lớp $i',
        'khoi': 10,
        'label': 'Lớp $i',
      },
  ];
  final teachers = [
    for (var i = 1; i <= 43; i++)
      {
        'ma_giao_vien': i,
        'ho_ten': 'Giáo viên $i',
        'to_chuyen_mon': null,
        'email': null,
        'dien_thoai': null,
        'label': 'Giáo viên $i',
      },
  ];
  final assignments = [
    for (var i = 1; i <= 151; i++)
      {
        'ma_phan_cong': i,
        'ma_giao_vien': (i % 43) + 1,
        'ma_lop': (i % 40) + 1,
        'ma_mon': (i % 11) + 1,
        'ma_hoc_ky': 1,
        'ngay_phan_cong': '2025-09-01',
        'label': 'Phân công $i',
      },
  ];
  final subjects = [
    for (var i = 1; i <= 11; i++)
      {
        'ma_mon': i,
        'ten_mon': 'Môn $i',
        'so_tiet_tuan': 2,
        'danh_gia_dat': false,
        'label': 'Môn $i',
      },
  ];
  final semesters = [
    for (var i = 1; i <= 3; i++)
      {
        'ma_hoc_ky': i,
        'ma_nam_hoc': 1,
        'ten': 'Học kỳ $i',
        'thu_tu': i,
        'da_cong_bo': false,
        'ngay_bat_dau': '2025-09-01',
        'ngay_ket_thuc': '2026-06-01',
        'label': 'Học kỳ $i',
      },
  ];
  final years = [
    {
      'ma_nam_hoc': 1,
      'ten': '2025-2026',
      'ngay_bat_dau': '2025-09-01',
      'ngay_ket_thuc': '2026-06-01',
      'hien_hanh': true,
      'label': '2025-2026',
    },
  ];

  Iterable<RequestOptions> listRequests(String suffix) =>
      requests.where((r) => r.method == 'GET' && r.path.endsWith(suffix));

  int get listRequestCount => requests
      .where((r) => r.method == 'GET' && !r.path.endsWith('/identity/login'))
      .length;

  Map<String, dynamic> _page(
    List<Map<String, dynamic>> rows,
    String idKey,
    Map<String, dynamic> query,
  ) {
    final role = query['role']?.toString();
    final yearId = query['yearId']?.toString();
    var filtered = role == null
        ? rows
        : rows.where((r) => r['role'] == role).toList();
    if (yearId != null) {
      filtered = filtered
          .where(
            (r) =>
                r['ma_nam_hoc'] == null || r['ma_nam_hoc'].toString() == yearId,
          )
          .toList();
    }
    final limit = int.tryParse(query['limit']?.toString() ?? '') ?? 50;
    final after = int.tryParse(query['cursor']?.toString() ?? '') ?? 0;
    final rest = filtered.where((r) => (r[idKey] as int) > after).toList();
    final items = rest.take(limit).toList();
    return {
      'items': items,
      'nextCursor': rest.length > limit ? '${items.last[idKey]}' : null,
    };
  }

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final path = options.path;
    final query = options.queryParameters;
    Object body = {};
    var status = 200;
    if (path.endsWith('/identity/login')) {
      body = {
        'id': 1,
        'username': 'admin',
        'role': 'QUAN_TRI_VIEN',
        'active': true,
        'token': 'tok',
        'csrf': 'csrf',
      };
    } else if (path.endsWith('/identity/accounts') &&
        options.method == 'POST') {
      final input = jsonDecode(options.data as String) as Map<String, dynamic>;
      final created = {
        'id': accounts.length + 1,
        'username': input['username'],
        'role': input['role'],
        'active': true,
      };
      accounts.add(created);
      body = created;
    } else if (path.endsWith('/identity/accounts')) {
      body = _page(accounts, 'id', query);
    } else if (path.endsWith('/catalog/classes')) {
      body = _page(classes, 'ma_lop', query);
    } else if (path.endsWith('/catalog/teachers')) {
      body = _page(teachers, 'ma_giao_vien', query);
    } else if (path.endsWith('/catalog/assignments')) {
      body = _page(assignments, 'ma_phan_cong', query);
    } else if (path.endsWith('/catalog/subjects')) {
      body = _page(subjects, 'ma_mon', query);
    } else if (path.endsWith('/catalog/semesters')) {
      body = _page(semesters, 'ma_hoc_ky', query);
    } else if (path.endsWith('/catalog/years')) {
      body = _page(years, 'ma_nam_hoc', query);
    } else {
      status = 404;
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

Future<ProviderContainer> _container(
  WidgetTester tester,
  _PagedServer server,
) async {
  final container = ProviderContainer(
    overrides: [
      apiProvider.overrideWithValue(
        ApiClientDart(dio: Dio()..httpClientAdapter = server),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.runAsync(
    () => container.read(sessionProvider.notifier).login('admin', 'pass'),
  );
  return container;
}

void main() {
  testWidgets(
    'hộp thoại thêm học sinh tải một trang lớn cho lớp và tài khoản học sinh',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final server = _PagedServer();
      final container = await _container(tester, server);
      final studentSpec = resources.firstWhere((r) => r.key == 'students');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: EditDialog(spec: studentSpec)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final accountRequests = server
          .listRequests('/identity/accounts')
          .toList();
      final classRequests = server.listRequests('/catalog/classes').toList();
      expect(accountRequests, hasLength(3));
      for (final request in accountRequests) {
        expect(request.queryParameters['role'], 'HOC_SINH');
        expect(request.queryParameters['limit'], catalogLargePage);
      }
      expect(
        accountRequests.first.queryParameters.containsKey('cursor'),
        isFalse,
      );
      expect(accountRequests.last.queryParameters['cursor'], '1000');
      expect(classRequests, hasLength(1));
      expect(classRequests.single.queryParameters['limit'], catalogLargePage);
    },
  );

  testWidgets('hộp thoại thêm học sinh vẫn thấy tài khoản nằm sau trang đầu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final server = _PagedServer();
    final container = await _container(tester, server);
    final studentSpec = resources.firstWhere((r) => r.key == 'students');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: EditDialog(spec: studentSpec)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppSelectField<num>).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '0900001200');
    await tester.pumpAndSettle();
    expect(find.text('0900001200'), findsWidgets);
  });

  testWidgets(
    'tạo tài khoản giáo viên mới tìm thấy tài khoản dù nằm sau trang đầu',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final server = _PagedServer();
      final container = await _container(tester, server);
      final teacherSpec = resources.firstWhere((r) => r.key == 'teachers');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: EditDialog(spec: teacherSpec)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tạo tài khoản giáo viên mới'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Số điện thoại đăng nhập'),
        '0911111111',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mật khẩu ban đầu'),
        'matkhau-dai-12345',
      );
      await tester.tap(find.text('Tạo và liên kết'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('0911111111'), findsWidgets);
      final teacherAccountRequests = server
          .listRequests('/identity/accounts')
          .where((r) => r.queryParameters['role'] == 'GIAO_VIEN')
          .toList();
      expect(teacherAccountRequests.length, greaterThanOrEqualTo(4));
    },
  );

  testWidgets('màn Giáo viên và phân công mở với dưới 15 request danh mục', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final server = _PagedServer();
    final container = await _container(tester, server);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const GradebookApp(
          initialLocation: '/admin/teaching-assignments',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final assignmentRequests = server
        .listRequests('/catalog/assignments')
        .toList();
    expect(assignmentRequests, hasLength(1));
    expect(
      assignmentRequests.single.queryParameters['limit'],
      catalogLargePage,
    );
    expect(server.listRequestCount, lessThan(15));
  });

  test(
    'không có limit thì API cũ cần nhiều trang: so sánh số request',
    () async {
      final server = _PagedServer();
      final repository = CatalogRepository(
        ApiClientDart(dio: Dio()..httpClientAdapter = server),
      );
      Future<int> pages({num? limit}) async {
        final before = server.requests.length;
        String? cursor;
        do {
          final page = await repository.list(
            'accounts',
            cursor: cursor,
            limit: limit,
            role: 'HOC_SINH',
          );
          cursor = page.nextCursor;
        } while (cursor != null);
        return server.requests.length - before;
      }

      expect(await pages(), 24);
      expect(await pages(limit: catalogLargePage), 3);
    },
  );
}
