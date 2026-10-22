import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/app/theme_mode.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/app/widgets/app_badge.dart';
import 'package:client_flutter/app/widgets/app_scaffold.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/final_results/final_results_panel.dart';
import 'package:client_flutter/features/reports/reports_panel.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Máy chủ giả cho ba route mới của bước 13: danh mục, bảng điểm, tổng kết.
class _Server implements HttpClientAdapter {
  _Server(this.role);
  final String role;

  static const _teachers = [
    {
      'ma_giao_vien': 10,
      'ho_ten': 'Lê Hoàng Cúc',
      'to_chuyen_mon': 'Tổ Toán',
      'email': null,
      'dien_thoai': null,
      'label': 'Lê Hoàng Cúc',
    },
    {
      'ma_giao_vien': 11,
      'ho_ten': 'Phạm Minh Đức',
      'to_chuyen_mon': null,
      'email': null,
      'dien_thoai': null,
      'label': 'Phạm Minh Đức',
    },
    {
      'ma_giao_vien': 12,
      'ho_ten': 'Vũ Thị Hà',
      'to_chuyen_mon': null,
      'email': null,
      'dien_thoai': null,
      'label': 'Vũ Thị Hà',
    },
  ];

  static const _classes = [
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
  ];

  static const _subjects = [
    {
      'ma_mon': 1,
      'ten_mon': 'Toán',
      'so_tiet_tuan': 4,
      'danh_gia_dat': false,
      'label': 'Toán',
    },
    {
      'ma_mon': 2,
      'ten_mon': 'Ngữ văn',
      'so_tiet_tuan': 4,
      'danh_gia_dat': false,
      'label': 'Ngữ văn',
    },
  ];

  static const _semesters = [
    {
      'ma_hoc_ky': 1,
      'ma_nam_hoc': 1,
      'ten': 'Học kỳ I',
      'thu_tu': 1,
      'ngay_bat_dau': '2026-09-01',
      'ngay_ket_thuc': '2027-01-15',
      'label': 'Học kỳ I · 2026-2027',
    },
  ];

  static const _assignments = [
    {
      'ma_phan_cong': 1,
      'ma_giao_vien': 10,
      'ma_lop': 1,
      'ma_mon': 1,
      'ma_hoc_ky': 1,
      'ngay_phan_cong': '2026-08-20',
      'label': 'Phân công 1',
    },
    {
      'ma_phan_cong': 2,
      'ma_giao_vien': 10,
      'ma_lop': 2,
      'ma_mon': 1,
      'ma_hoc_ky': 1,
      'ngay_phan_cong': '2026-08-20',
      'label': 'Phân công 2',
    },
    {
      'ma_phan_cong': 3,
      'ma_giao_vien': 11,
      'ma_lop': 1,
      'ma_mon': 2,
      'ma_hoc_ky': 1,
      'ngay_phan_cong': '2026-08-20',
      'label': 'Phân công 3',
    },
  ];

  static Map<String, dynamic> _component(
    int id,
    int subject,
    String name,
    String group,
    int order,
  ) => {
    'ma_thanh_phan': id,
    'ma_mon': subject,
    'ten_thanh_phan': name,
    'loai_he_so': group,
    'bat_buoc': true,
    'thu_tu_hien_thi': order,
    'cho_phep_nhap': true,
    'label': name,
  };

  static final _components = [
    _component(1, 1, 'Thường xuyên 1', 'TX', 1),
    _component(2, 1, 'Giữa kỳ', 'GK', 2),
    _component(3, 1, 'Cuối kỳ', 'CK', 3),
    _component(4, 2, 'Kiểm tra miệng', 'TX', 1),
  ];

  static Map<String, dynamic> _weight(int id, String group, String value) => {
    'ma_he_so': id,
    'ma_hoc_ky': 1,
    'loai_he_so': group,
    'he_so': value,
    'label': '$group $value',
  };

  static final _weights = [
    _weight(1, 'TX', '1.00'),
    _weight(2, 'GK', '2.00'),
    _weight(3, 'CK', '3.00'),
  ];

  static Map<String, dynamic> _book(int id, String className) => {
    'id': id,
    'classId': id,
    'subjectId': 1,
    'termId': 1,
    'className': className,
    'subjectName': 'Toán',
    'termName': 'Học kỳ I · 2026-2027',
    'status': 'DANG_NHAP_LIEU',
    'version': 3,
    'pendingAdjustmentId': null,
    'resultsOutdated': false,
  };

  static Map<String, dynamic> _result(String id, String name, String score) => {
    'id': id,
    'studentId': 101,
    'studentName': name,
    'finalScore': score,
    'classification': 'GIOI',
    'weightVersion': 'W-012345678901234567',
    'policyVersion': 'DEV-2026-01',
    'calculatedAt': '2026-09-13T01:00:00.000Z',
  };

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    Object body = {};
    var status = 200;
    List<Object?>? items;
    if (path.endsWith('/identity/login')) {
      body = {
        'id': 1,
        'username': 'route_tester',
        'role': role,
        'active': true,
        'token': 'token',
        'csrf': 'csrf',
      };
    } else if (path.endsWith('/catalog/teachers')) {
      items = _teachers;
    } else if (path.endsWith('/catalog/assignments')) {
      items = _assignments;
    } else if (path.endsWith('/catalog/classes')) {
      items = _classes;
    } else if (path.endsWith('/catalog/subjects')) {
      items = _subjects;
    } else if (path.endsWith('/catalog/semesters')) {
      items = _semesters;
    } else if (path.endsWith('/catalog/components')) {
      items = _components;
    } else if (path.endsWith('/catalog/semester-weights')) {
      items = _weights;
    } else if (path == '/api/v1/gradebooks') {
      items = [_book(7, '10A1'), _book(8, '10A2')];
    } else if (RegExp(r'/reports/gradebooks/\d+/summary$').hasMatch(path)) {
      body = {
        'gradebookId': 7,
        'students': 40,
        'average': '7.2',
        'highest': '9.8',
        'lowest': '2.5',
        'passed': 36,
        'failed': 4,
        'distribution': [
          {'classification': 'GIOI', 'students': 12},
          {'classification': 'KHA', 'students': 15},
        ],
      };
    } else if (path.endsWith('/final-results') && options.method == 'GET') {
      body = {
        'items': [
          _result('501', 'Nguyễn Văn An', '8.6'),
          _result('502', 'Trần Thị Bích', '9.1'),
        ],
        'nextCursor': null,
        'exemptedStudents': 0,
        'exempted': <dynamic>[],
        'skippedStudents': 0,
        'skipped': <dynamic>[],
      };
    } else {
      status = 404;
    }
    if (items != null) body = {'items': items, 'nextCursor': null};
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required String role,
  required String location,
  double width = 1280,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final container = ProviderContainer(
    overrides: [
      themeModeProvider.overrideWith(
        (ref) =>
            brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      ),
      apiProvider.overrideWithValue(
        ApiClientDart(dio: Dio()..httpClientAdapter = _Server(role)),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.runAsync(
    () => container.read(sessionProvider.notifier).login('route_tester', 'x'),
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

String _pathOf(ProviderContainer container, String initial) => container
    .read(routerProvider(initial))
    .routeInformationProvider
    .value
    .uri
    .path;

void main() {
  group('guard theo vai', () {
    const cases = <({String role, String path, bool allowed})>[
      (role: 'HOC_SINH', path: '/final-results', allowed: false),
      (role: 'GIAO_VIEN', path: '/final-results', allowed: true),
      (role: 'QUAN_TRI_VIEN', path: '/final-results', allowed: true),
      (role: 'GIAO_VIEN', path: '/admin/teaching-assignments', allowed: false),
      (role: 'HOC_SINH', path: '/admin/teaching-assignments', allowed: false),
      (
        role: 'QUAN_TRI_VIEN',
        path: '/admin/teaching-assignments',
        allowed: true,
      ),
      (role: 'GIAO_VIEN', path: '/admin/subjects-weights', allowed: false),
      (role: 'HOC_SINH', path: '/admin/subjects-weights', allowed: false),
      (role: 'QUAN_TRI_VIEN', path: '/admin/subjects-weights', allowed: true),
    ];
    for (final c in cases) {
      testWidgets(
        '${c.role} vào ${c.path}: ${c.allowed ? 'được vào' : 'về /'}',
        (tester) async {
          final container = await _pump(tester, role: c.role, location: c.path);
          expect(_pathOf(container, c.path), c.allowed ? c.path : '/');
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }

    for (final path in [
      '/final-results',
      '/admin/teaching-assignments',
      '/admin/subjects-weights',
    ]) {
      testWidgets('chưa đăng nhập vào $path thì về /login', (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderContainer(
          overrides: [
            apiProvider.overrideWithValue(
              ApiClientDart(
                dio: Dio()..httpClientAdapter = _Server('GIAO_VIEN'),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: GradebookApp(initialLocation: path),
          ),
        );
        await tester.pumpAndSettle();
        expect(_pathOf(container, path), '/login');
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  });

  for (final width in [390.0, 1280.0]) {
    final wide = width >= 1280;
    group('render ở ${width.toInt()} px', () {
      testWidgets(
        'Giáo viên & phân công: ghép giáo viên, môn, lớp, chủ nhiệm',
        (tester) async {
          await _pump(
            tester,
            role: 'QUAN_TRI_VIEN',
            location: '/admin/teaching-assignments',
            width: width,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Lê Hoàng Cúc'), findsOneWidget);
          expect(find.text('Phạm Minh Đức'), findsOneWidget);
          // Giáo viên chưa có phân công vẫn hiện.
          expect(find.text('Vũ Thị Hà'), findsOneWidget);
          expect(find.text('Quản lý giáo viên'), findsOneWidget);
          expect(find.text('Quản lý phân công'), findsOneWidget);
          // Lớp được phân công hiện dạng chip; chủ nhiệm dạng AppBadge.
          expect(find.text('10A1'), findsWidgets);
          expect(find.text('10A2'), findsWidgets);
          // Chủ nhiệm: mỗi lớp có đúng một AppBadge của giáo viên chủ nhiệm.
          for (final className in ['10A1', '10A2']) {
            expect(
              find.descendant(
                of: find.byType(AppBadge),
                matching: find.text(className),
              ),
              findsOneWidget,
            );
          }
          expect(
            find.byKey(const ValueKey('teaching-table')),
            wide ? findsOneWidget : findsNothing,
          );
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );

      testWidgets('Giáo viên & phân công: nút sang màn quản lý', (
        tester,
      ) async {
        final container = await _pump(
          tester,
          role: 'QUAN_TRI_VIEN',
          location: '/admin/teaching-assignments',
          width: width,
        );
        await tester.tap(
          find.byKey(const ValueKey('merged-link-/catalog/teachers')),
        );
        await tester.pumpAndSettle();
        expect(
          _pathOf(container, '/admin/teaching-assignments'),
          '/catalog/teachers',
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });

      testWidgets('Môn học & hệ số: chip thành phần với hệ số từ dữ liệu', (
        tester,
      ) async {
        await _pump(
          tester,
          role: 'QUAN_TRI_VIEN',
          location: '/admin/subjects-weights',
          width: width,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Toán'), findsWidgets);
        expect(find.text('Ngữ văn'), findsWidgets);
        expect(find.text('Thường xuyên 1 TX ×1'), findsOneWidget);
        expect(find.text('Giữa kỳ GK ×2'), findsOneWidget);
        expect(find.text('Cuối kỳ CK ×3'), findsOneWidget);
        expect(find.text('Kiểm tra miệng TX ×1'), findsOneWidget);
        expect(find.byKey(const ValueKey('weight-TX')), findsOneWidget);
        expect(find.text('×2'), findsOneWidget);
        expect(find.text('Quản lý môn học'), findsOneWidget);
        expect(find.text('Quản lý thành phần điểm'), findsOneWidget);
        expect(find.text('Quản lý hệ số học kỳ'), findsOneWidget);
        // Không viết công thức hay tổng hệ số cứng.
        expect(find.textContaining('chia 9'), findsNothing);
        expect(find.textContaining('Tổng hệ số'), findsNothing);
        expect(
          find.byKey(const ValueKey('subjects-table')),
          wide ? findsOneWidget : findsNothing,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });

      testWidgets('Tổng kết: chọn bảng điểm rồi nhúng panel tổng kết', (
        tester,
      ) async {
        await _pump(
          tester,
          role: 'GIAO_VIEN',
          location: '/final-results',
          width: width,
        );
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('view-gradebook-7')), findsOneWidget);
        expect(find.byType(FinalResultsPanel), findsNothing);

        await tester.tap(find.byKey(const ValueKey('view-gradebook-7')));
        await tester.pumpAndSettle();

        expect(find.byType(FinalResultsPanel), findsOneWidget);
        expect(find.byType(ReportsPanel), findsOneWidget);
        expect(find.byKey(const ValueKey('export-xlsx')), findsWidgets);
        expect(find.text('Nguyễn Văn An'), findsOneWidget);
        expect(find.text('8.6'), findsOneWidget);
        expect(find.textContaining('W-012345678901234567'), findsWidgets);
        expect(find.textContaining('DEV-2026-01'), findsWidgets);
        expect(find.text('Đang nhập liệu'), findsOneWidget);
        // Giáo viên được tính; không có cột TB nhóm TX/GK/CK.
        expect(
          find.byKey(const ValueKey('calculate-final-results')),
          findsWidgets,
        );
        expect(find.text('TX (TB)'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    });
  }

  testWidgets('Tổng kết: lọc còn một bảng điểm thì tự chọn; QTV không có nút '
      'tính', (tester) async {
    await _pump(tester, role: 'QUAN_TRI_VIEN', location: '/final-results');
    await tester.tap(find.byKey(const ValueKey('final-filter-class')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10A2').last);
    await tester.pumpAndSettle();
    expect(find.byType(FinalResultsPanel), findsOneWidget);
    expect(find.byKey(const ValueKey('calculate-final-results')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('chế độ tối, không overflow', () {
    const screens = <({String role, String path})>[
      (role: 'QUAN_TRI_VIEN', path: '/admin/teaching-assignments'),
      (role: 'QUAN_TRI_VIEN', path: '/admin/subjects-weights'),
      (role: 'GIAO_VIEN', path: '/final-results'),
    ];
    for (final s in screens) {
      for (final width in [390.0, 1280.0]) {
        testWidgets('${s.path} ở ${width.toInt()} px', (tester) async {
          await _pump(
            tester,
            role: s.role,
            location: s.path,
            width: width,
            brightness: Brightness.dark,
          );
          expect(tester.takeException(), isNull);
          final context = tester.element(find.byType(AppScaffold));
          expect(Theme.of(context).brightness, Brightness.dark);
          expect(context.tokens.surface, AppTokens.dark.surface);
          if (s.path == '/admin/teaching-assignments' && width >= 1280) {
            final box = tester.widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byKey(const ValueKey('teaching-table')),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            );
            expect(
              (box.decoration as BoxDecoration).color,
              AppTokens.dark.surface,
            );
          }
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  });

  group('mục sidebar mới theo vai', () {
    const adminOnly = ['Giáo viên & phân công', 'Môn học & hệ số'];
    const summary = 'Tổng kết & xếp loại';
    const expectations =
        <({String role, String path, bool admin, bool summary})>[
          (
            role: 'QUAN_TRI_VIEN',
            path: '/gradebooks',
            admin: true,
            summary: true,
          ),
          (role: 'GIAO_VIEN', path: '/gradebooks', admin: false, summary: true),
          (role: 'HOC_SINH', path: '/my-results', admin: false, summary: false),
        ];
    for (final e in expectations) {
      testWidgets('${e.role}: hiện đúng mục', (tester) async {
        tester.view.physicalSize = const Size(1280, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderContainer(
          overrides: [
            apiProvider.overrideWithValue(
              ApiClientDart(dio: Dio()..httpClientAdapter = _Server(e.role)),
            ),
          ],
        );
        addTearDown(container.dispose);
        await tester.runAsync(
          () => container
              .read(sessionProvider.notifier)
              .login('route_tester', 'x'),
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light(),
              home: AppScaffold(
                title: 'Trang thử',
                currentPath: e.path,
                body: const SizedBox.shrink(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final label in adminOnly) {
          expect(
            find.text(label),
            e.admin ? findsOneWidget : findsNothing,
            reason: '$label với ${e.role}',
          );
        }
        expect(
          find.text(summary),
          e.summary ? findsOneWidget : findsNothing,
          reason: '$summary với ${e.role}',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  });
}
