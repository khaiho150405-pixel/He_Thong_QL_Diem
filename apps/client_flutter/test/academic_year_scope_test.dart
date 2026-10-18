import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/features/academic_catalog/academic_year_scope.dart';
import 'package:client_flutter/features/academic_catalog/edit_dialog.dart';
import 'package:client_flutter/features/academic_catalog/fields.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ScopeTestServer implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  Map<String, dynamic> pendingSummary = {
    'openGradebooks': 3,
    'pendingRecognitionTickets': 1,
    'unpublishedSemesters': 1,
  };
  bool pendingSummaryError = false;
  bool throw409OnDisableCurrentYear = false;
  bool throw409OnDeleteCurrentYear = false;

  final years = [
    {
      'ma_nam_hoc': 1,
      'ten': '2025-2026',
      'ngay_bat_dau': '2025-09-01',
      'ngay_ket_thuc': '2026-06-01',
      'hien_hanh': true,
      'label': '2025-2026',
    },
    {
      'ma_nam_hoc': 2,
      'ten': '2024-2025',
      'ngay_bat_dau': '2024-09-01',
      'ngay_ket_thuc': '2025-06-01',
      'hien_hanh': false,
      'label': '2024-2025',
    },
  ];

  final teachers = [
    {
      'ma_giao_vien': 10,
      'ho_ten': 'Nguyễn Văn A',
      'to_chuyen_mon': 'Toán',
      'email': null,
      'dien_thoai': '0901234567',
      'label': 'Nguyễn Văn A',
    },
  ];

  final classes = [
    {
      'ma_lop': 101,
      'ma_nam_hoc': 1,
      'ma_gv_chu_nhiem': 10,
      'ten_lop': '10A1',
      'khoi': 10,
      'label': '10A1',
    },
  ];

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
    Object body = {};
    int status = 200;

    if (path.endsWith('/identity/login')) {
      body = {
        'id': 1,
        'username': 'admin',
        'role': 'QUAN_TRI_VIEN',
        'active': true,
        'token': 'tok',
        'csrf': 'csrf',
      };
    } else if (RegExp(r'/catalog/years/\d+/pending-summary$').hasMatch(path)) {
      if (pendingSummaryError) {
        status = 500;
        body = {'code': 'ERROR', 'message': 'Lỗi server'};
      } else {
        body = pendingSummary;
      }
    } else if (RegExp(r'/catalog/years(/\d+)?$').hasMatch(path)) {
      if (options.method == 'PUT') {
        if (throw409OnDisableCurrentYear) {
          status = 409;
          body = {
            'code': 'CONFLICT',
            'message':
                'Phải có một năm học hiện hành; hãy bật năm khác để chuyển.',
          };
        } else {
          final data =
              jsonDecode(options.data as String) as Map<String, dynamic>;
          body = data;
        }
      } else if (options.method == 'DELETE') {
        if (throw409OnDeleteCurrentYear) {
          status = 409;
          body = {
            'code': 'CONFLICT',
            'message':
                'Không thể xóa năm học hiện hành; hãy chuyển năm hiện hành sang năm khác trước.',
          };
        } else {
          status = 204;
        }
      } else {
        body = {'items': years, 'nextCursor': null};
      }
    } else if (path.endsWith('/catalog/classes')) {
      body = {'items': classes, 'nextCursor': null};
    } else if (path.endsWith('/catalog/teachers')) {
      body = {'items': teachers, 'nextCursor': null};
    } else if (path.endsWith('/catalog/semesters')) {
      body = {'items': [], 'nextCursor': null};
    } else if (path.endsWith('/catalog/assignments')) {
      body = {'items': [], 'nextCursor': null};
    } else if (path.endsWith('/catalog/semester-weights')) {
      body = {'items': [], 'nextCursor': null};
    } else if (path.endsWith('/catalog/students')) {
      body = {'items': [], 'nextCursor': null};
    } else if (path.endsWith('/catalog/subjects')) {
      body = {'items': [], 'nextCursor': null};
    } else if (path.endsWith('/catalog/components')) {
      body = {'items': [], 'nextCursor': null};
    } else if (path.endsWith('/catalog/accounts')) {
      body = {'items': [], 'nextCursor': null};
    } else if (path == '/api/v1/gradebooks' || path.endsWith('/gradebooks')) {
      body = {'items': [], 'nextCursor': null};
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

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  required _ScopeTestServer server,
  String initialLocation = '/catalog/classes',
  Size size = const Size(1280, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final dio = Dio()..httpClientAdapter = server;
  final container = ProviderContainer(
    overrides: [apiProvider.overrideWithValue(ApiClientDart(dio: dio))],
  );
  addTearDown(container.dispose);

  await tester.runAsync(
    () => container.read(sessionProvider.notifier).login('admin', 'pass'),
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
  group('Academic Year Scope Provider & Widgets', () {
    testWidgets('ViewingYear model properties and operators', (tester) async {
      const all = ViewingYear.all;
      expect(all.isAll, isTrue);
      expect(all.id, isNull);
      expect(all.name, 'Tất cả các năm');
      expect(all['ten'], 'Tất cả các năm');

      final year = ViewingYear.fromRow({
        'ma_nam_hoc': 1,
        'ten': '2025-2026',
        'hien_hanh': true,
      });
      expect(year.isAll, isFalse);
      expect(year.id, 1);
      expect(year.isCurrent, isTrue);
      expect(year['ma_nam_hoc'], 1);
      expect(year['ten'], '2025-2026');
    });

    testWidgets('Default calls API with current yearId on classes screen', (
      tester,
    ) async {
      final server = _ScopeTestServer();
      await _pumpApp(
        tester,
        server: server,
        initialLocation: '/catalog/classes',
      );

      // Check requests to /catalog/classes
      final classRequests = server.requests.where(
        (r) => r.path.endsWith('/catalog/classes'),
      );
      expect(classRequests, isNotEmpty);
      expect(classRequests.last.queryParameters['yearId'], 1);

      // Verify the dropdown shows "2025-2026 (hiện hành)"
      expect(find.text('2025-2026 (hiện hành)'), findsWidgets);
    });

    testWidgets('Selecting "Tất cả các năm" sends request without yearId', (
      tester,
    ) async {
      final server = _ScopeTestServer();
      await _pumpApp(
        tester,
        server: server,
        initialLocation: '/catalog/classes',
      );

      // Tap the year filter dropdown
      final yearDropdown = find.text('2025-2026 (hiện hành)').first;
      await tester.tap(yearDropdown);
      await tester.pumpAndSettle();

      // Tap "Tất cả các năm"
      final allYearsOption = find.text('Tất cả các năm').last;
      await tester.tap(allYearsOption);
      await tester.pumpAndSettle();

      // Check latest class request
      final classRequests = server.requests.where(
        (r) => r.path.endsWith('/catalog/classes'),
      );
      expect(classRequests.last.queryParameters.containsKey('yearId'), isFalse);
    });

    testWidgets('Selecting archive year displays "Năm lưu trữ" badge', (
      tester,
    ) async {
      final server = _ScopeTestServer();
      await _pumpApp(
        tester,
        server: server,
        initialLocation: '/catalog/classes',
      );

      // Tap the year filter dropdown
      final yearDropdown = find.text('2025-2026 (hiện hành)').first;
      await tester.tap(yearDropdown);
      await tester.pumpAndSettle();

      // Tap "2024-2025" (non-current year)
      final oldYearOption = find.text('2024-2025').last;
      await tester.tap(oldYearOption);
      await tester.pumpAndSettle();

      // Check for "Năm lưu trữ" badge
      expect(find.text('Năm lưu trữ'), findsWidgets);

      // Request sent with yearId: 2
      final classRequests = server.requests.where(
        (r) => r.path.endsWith('/catalog/classes'),
      );
      expect(classRequests.last.queryParameters['yearId'], 2);
    });

    testWidgets('Teachers filter sends activeInYearId when checked', (
      tester,
    ) async {
      final server = _ScopeTestServer();
      await _pumpApp(
        tester,
        server: server,
        initialLocation: '/catalog/teachers',
      );

      // Initially, teacher request does NOT have activeInYearId
      var teacherRequests = server.requests.where(
        (r) => r.path.endsWith('/catalog/teachers'),
      );
      expect(
        teacherRequests.last.queryParameters.containsKey('activeInYearId'),
        isFalse,
      );

      // Open the "Phân công" dropdown (currently displaying "Tất cả giáo viên")
      // AppSelectField (DropdownMenu) hiển thị nhãn ở cả ô chọn lẫn menu ẩn.
      final assignmentDropdown = find.text('Tất cả giáo viên').first;
      expect(find.text('Tất cả giáo viên'), findsWidgets);
      await tester.tap(assignmentDropdown);
      await tester.pumpAndSettle();

      // Tap the option "Có phân công..."
      final activeOption = find.textContaining('Có phân công').last;
      expect(activeOption, findsOneWidget);
      await tester.tap(activeOption);
      await tester.pumpAndSettle();

      // Next teacher request sends activeInYearId = 1
      teacherRequests = server.requests.where(
        (r) => r.path.endsWith('/catalog/teachers'),
      );
      expect(teacherRequests.last.queryParameters['activeInYearId'], 1);
    });

    testWidgets(
      'Confirmation dialog on current year switch with pending warning',
      (tester) async {
        final server = _ScopeTestServer();
        server.pendingSummary = {
          'openGradebooks': 3,
          'pendingRecognitionTickets': 1,
          'unpublishedSemesters': 1,
        };

        final dio = Dio()..httpClientAdapter = server;
        final container = ProviderContainer(
          overrides: [apiProvider.overrideWithValue(ApiClientDart(dio: dio))],
        );
        addTearDown(container.dispose);

        await tester.runAsync(
          () => container.read(sessionProvider.notifier).login('admin', 'pass'),
        );

        final yearSpec = resources.firstWhere((r) => r.key == 'years');
        final yearRow = {
          'ma_nam_hoc': 2,
          'ten': '2024-2025',
          'ngay_bat_dau': '2024-09-01',
          'ngay_ket_thuc': '2025-06-01',
          'hien_hanh': false,
        };

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: EditDialog(spec: yearSpec, row: yearRow),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find switch for "Năm hiện hành" and toggle it
        final switchFinder = find.byType(Switch);
        expect(switchFinder, findsOneWidget);
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        // Confirmation dialog should be displayed with pending summary counts
        expect(find.textContaining('Chuyển năm hiện hành từ'), findsOneWidget);
        expect(find.textContaining('3 bảng điểm chưa chốt'), findsOneWidget);
        expect(find.textContaining('1 phiếu chờ đối chiếu'), findsOneWidget);
        expect(find.textContaining('1 học kỳ chưa công bố'), findsOneWidget);

        // Tap "Hủy"
        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Chuyển năm hiện hành từ'), findsNothing);
      },
    );

    testWidgets(
      'Confirmation dialog on current year switch without pending warning (0 counts)',
      (tester) async {
        final server = _ScopeTestServer();
        server.pendingSummary = {
          'openGradebooks': 0,
          'pendingRecognitionTickets': 0,
          'unpublishedSemesters': 0,
        };

        final dio = Dio()..httpClientAdapter = server;
        final container = ProviderContainer(
          overrides: [apiProvider.overrideWithValue(ApiClientDart(dio: dio))],
        );
        addTearDown(container.dispose);

        await tester.runAsync(
          () => container.read(sessionProvider.notifier).login('admin', 'pass'),
        );

        final yearSpec = resources.firstWhere((r) => r.key == 'years');
        final yearRow = {
          'ma_nam_hoc': 2,
          'ten': '2024-2025',
          'ngay_bat_dau': '2024-09-01',
          'ngay_ket_thuc': '2025-06-01',
          'hien_hanh': false,
        };

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: EditDialog(spec: yearSpec, row: yearRow),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Toggle switch
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        // Confirmation dialog should appear WITHOUT warning counts
        expect(find.textContaining('Chuyển năm hiện hành từ'), findsOneWidget);
        expect(find.textContaining('bảng điểm chưa chốt'), findsNothing);

        // Tap "Hủy"
        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets('Confirmation dialog appears even when pending summary fails', (
      tester,
    ) async {
      final server = _ScopeTestServer();
      server.pendingSummaryError = true;

      final dio = Dio()..httpClientAdapter = server;
      final container = ProviderContainer(
        overrides: [apiProvider.overrideWithValue(ApiClientDart(dio: dio))],
      );
      addTearDown(container.dispose);

      await tester.runAsync(
        () => container.read(sessionProvider.notifier).login('admin', 'pass'),
      );

      final yearSpec = resources.firstWhere((r) => r.key == 'years');
      final yearRow = {
        'ma_nam_hoc': 2,
        'ten': '2024-2025',
        'ngay_bat_dau': '2024-09-01',
        'ngay_ket_thuc': '2025-06-01',
        'hien_hanh': false,
      };

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: EditDialog(spec: yearSpec, row: yearRow),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Dialog still shows
      expect(find.textContaining('Chuyển năm hiện hành từ'), findsOneWidget);

      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
    });

    testWidgets('409 Conflict displayed when disabling only current year', (
      tester,
    ) async {
      final server = _ScopeTestServer();
      server.throw409OnDisableCurrentYear = true;

      final dio = Dio()..httpClientAdapter = server;
      final container = ProviderContainer(
        overrides: [apiProvider.overrideWithValue(ApiClientDart(dio: dio))],
      );
      addTearDown(container.dispose);

      await tester.runAsync(
        () => container.read(sessionProvider.notifier).login('admin', 'pass'),
      );

      final yearSpec = resources.firstWhere((r) => r.key == 'years');
      final currentYearRow = {
        'ma_nam_hoc': 1,
        'ten': '2025-2026',
        'ngay_bat_dau': '2025-09-01',
        'ngay_ket_thuc': '2026-06-01',
        'hien_hanh': true,
      };

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: EditDialog(spec: yearSpec, row: currentYearRow),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch off hien_hanh
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Tap Lưu
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      // Error banner with 409 message
      expect(
        find.textContaining(
          'Phải có một năm học hiện hành; hãy bật năm khác để chuyển.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      '409 Conflict displayed when deleting current year in catalog screen',
      (tester) async {
        final server = _ScopeTestServer();
        server.throw409OnDeleteCurrentYear = true;

        await _pumpApp(
          tester,
          server: server,
          initialLocation: '/catalog/years',
        );

        // Click delete (delete icon) on the first row
        final deleteButtons = find.byIcon(Icons.delete_outline);
        expect(deleteButtons, findsWidgets);
        await tester.tap(deleteButtons.first);
        await tester.pumpAndSettle();

        // Confirmation dialog pops up, click "Xóa"
        expect(find.textContaining('Xóa bản ghi'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
        await tester.pumpAndSettle();

        // SnackBar shows 409 message
        expect(
          find.textContaining(
            'Không thể xóa năm học hiện hành; hãy chuyển năm hiện hành sang năm khác trước.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Mobile 360x800 layout renders without overflow', (
      tester,
    ) async {
      final server = _ScopeTestServer();
      await _pumpApp(
        tester,
        server: server,
        initialLocation: '/catalog/classes',
        size: const Size(360, 800),
      );

      // Verify no overflow exception was thrown
      expect(tester.takeException(), isNull);

      // Title exists
      expect(find.text('Lớp học'), findsOneWidget);

      // Topbar year label on mobile exists
      expect(find.textContaining('2025-2026'), findsWidgets);

      // Year filter control exists
      expect(find.text('2025-2026 (hiện hành)'), findsWidgets);
    });
  });
}
