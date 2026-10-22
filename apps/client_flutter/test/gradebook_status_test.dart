import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/app/theme_mode.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/app/widgets/app_badge.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/gradebooks/excel_import_dialog.dart';
import 'package:client_flutter/features/gradebooks/grade_deadlines_panel.dart';
import 'package:client_flutter/features/gradebooks/gradebook_status.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Máy chủ giả cho bước 10: danh sách bảng điểm và chi tiết một bảng.
class _Server implements HttpClientAdapter {
  _Server({this.locked = false, this.closes = const {}});

  final bool locked;

  /// `componentId` -> `closesAt` (ISO). Thiếu khóa là cột chưa đặt lịch.
  final Map<int, String?> closes;

  /// Mọi đường dẫn đã gọi, để kiểm tra giao diện không gọi lock.
  final paths = <String>[];

  @override
  void close({bool force = false}) {}

  Map<String, dynamic> get book => {
    'id': 7,
    'classId': 10,
    'subjectId': 20,
    'termId': 30,
    'className': '10A1',
    'subjectName': 'Toán',
    'termName': 'Học kỳ I',
    'status': locked ? 'DA_CHOT' : 'DANG_NHAP_LIEU',
    'version': 2,
    'pendingAdjustmentId': null,
    'resultsOutdated': false,
  };

  Map<String, dynamic> cell(
    String id,
    int componentId,
    String componentName,
    String? value, {
    String source = 'NHAP_TAY',
  }) => {
    'id': id,
    'studentId': 101,
    'studentName': 'An',
    'stt': 1,
    'active': true,
    'componentId': componentId,
    'componentName': componentName,
    'coefficient': componentId == 201 ? '1.0' : '2.0',
    'required': true,
    'displayOrder': componentId == 201 ? 1 : 2,
    'value': value,
    'status': value == null ? 'CHUA_CO' : 'DA_DUYET',
    'exemptionReason': null,
    'source': source,
    'closesAt': ?closes[componentId],
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add('${options.method} ${options.path}');
    Object body;
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
        'items': [
          book,
          {...book, 'id': 8, 'className': '11A2', 'status': 'DA_CHOT'},
        ],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/gradebooks/7/cells')) {
      body = {
        'book': book,
        'items': [
          cell('9001', 201, 'Miệng', null),
          cell('9002', 202, 'Giữa kỳ', '7.5', source: 'NHAN_DIEN'),
        ],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/gradebooks/7/final-results')) {
      body = {'items': [], 'nextCursor': null};
    } else if (options.path.endsWith('/catalog/classes') ||
        options.path.endsWith('/catalog/subjects')) {
      body = {'items': [], 'nextCursor': null};
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
}

GradeCellDto _column(int id, String? closesAt) => GradeCellDto.fromJson({
  'id': '$id',
  'studentId': 1,
  'studentName': 'Fixture',
  'stt': 1,
  'active': true,
  'componentId': id,
  'componentName': 'Cột $id',
  'coefficient': '1.0',
  'required': true,
  'displayOrder': id,
  'value': null,
  'status': 'CHUA_CO',
  'exemptionReason': null,
  'source': 'NHAP_TAY',
  'closesAt': ?closesAt,
});

Future<_Server> _pump(
  WidgetTester tester, {
  required String location,
  required double width,
  required Brightness mode,
  bool locked = false,
  Map<int, String?> closes = const {},
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.platformBrightnessTestValue = mode;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final server = _Server(locked: locked, closes: closes);
  final container = ProviderContainer(
    overrides: [
      themeModeProvider.overrideWith(
        (ref) => mode == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      ),
      apiProvider.overrideWithValue(
        ApiClientDart(dio: Dio()..httpClientAdapter = server),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.runAsync(
    () => container
        .read(sessionProvider.notifier)
        .login('giao_vien_test', 'fake-password'),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: GradebookApp(initialLocation: location),
    ),
  );
  await tester.pumpAndSettle();
  return server;
}

AppBadge _badge(WidgetTester tester, String label) =>
    tester.widget<AppBadge>(find.widgetWithText(AppBadge, label).first);

void main() {
  group('Nhãn trạng thái bảng điểm (kế hoạch 0.1)', () {
    test('DANG_NHAP_LIEU là "Đang nhập liệu" tông info', () {
      final view = gradebookStatusOf('DANG_NHAP_LIEU');
      expect(view.label, 'Đang nhập liệu');
      expect(view.tone, AppBadgeTone.info);
    });

    test('DA_CHOT là "Đã khóa" tông ok, không còn chữ "Đã chốt"', () {
      final view = gradebookStatusOf('DA_CHOT');
      expect(view.label, 'Đã khóa');
      expect(view.tone, AppBadgeTone.ok);
      expect(view.label, isNot(contains('chốt')));
    });

    test('giá trị lạ giữ nguyên chuỗi, tông trung tính', () {
      final view = gradebookStatusOf('KHAC');
      expect(view.label, 'KHAC');
      expect(view.tone, AppBadgeTone.neutral);
    });

    testWidgets('GradebookStatusBadge vẽ AppBadge theo nhãn', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Column(
            children: [
              GradebookStatusBadge('DANG_NHAP_LIEU'),
              GradebookStatusBadge('DA_CHOT'),
            ],
          ),
        ),
      );
      expect(_badge(tester, 'Đang nhập liệu').tone, AppBadgeTone.info);
      expect(_badge(tester, 'Đã khóa').tone, AppBadgeTone.ok);
    });
  });

  group('latestColumnClosesAt (hạn khóa chỉ khi đủ lịch)', () {
    test('mọi cột đều có closesAt: lấy giờ muộn nhất', () {
      final latest = latestColumnClosesAt([
        _column(1, '2026-10-20T03:00:00.000Z'),
        _column(2, '2026-10-25T10:30:00.000Z'),
        _column(3, '2026-10-22T08:00:00.000Z'),
      ]);
      expect(latest, DateTime.parse('2026-10-25T10:30:00.000Z'));
    });

    test('thiếu closesAt ở một cột: không hiện hạn', () {
      expect(
        latestColumnClosesAt([
          _column(1, '2026-10-20T03:00:00.000Z'),
          _column(2, null),
        ]),
        isNull,
      );
    });

    test('closesAt hỏng ở một cột: không hiện hạn', () {
      expect(
        latestColumnClosesAt([
          _column(1, '2026-10-20T03:00:00.000Z'),
          _column(2, 'không phải ngày'),
        ]),
        isNull,
      );
    });

    test('không có cột nào: không hiện hạn', () {
      expect(latestColumnClosesAt(const []), isNull);
    });
  });

  group('Giao diện không gọi lock / lockColumn', () {
    test('chỉ repository.dart được khai báo hoặc gọi lock()/lockColumn()', () {
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final path = entity.path.replaceAll('\\', '/');
        if (path.endsWith('features/gradebooks/repository.dart')) continue;
        final source = entity.readAsStringSync();
        if (source.contains('.lock(') ||
            source.contains('lockColumn(') ||
            source.contains('gradebooksLock')) {
          offenders.add(path);
        }
      }
      expect(offenders, isEmpty);
    });

    test('không còn nút "Chốt bảng điểm" trong lib/features/gradebooks', () {
      for (final entity in Directory(
        'lib/features/gradebooks',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        expect(source.contains('Chốt bảng'), isFalse, reason: entity.path);
        expect(source.contains('Đã chốt sổ'), isFalse, reason: entity.path);
      }
    });
  });

  for (final mode in Brightness.values) {
    for (final width in [390.0, 1280.0]) {
      final tag = '${mode.name} ${width.toInt()}px';

      testWidgets('danh sách: hai nhãn trạng thái, không hạn khóa, $tag', (
        tester,
      ) async {
        final server = await _pump(
          tester,
          location: '/gradebooks',
          width: width,
          mode: mode,
        );
        final tokens = mode == Brightness.dark
            ? AppTokens.dark
            : AppTokens.light;
        expect(
          find.descendant(
            of: find.byType(AppBadge),
            matching: find.text('Đang nhập liệu'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AppBadge),
            matching: find.text('Đã khóa'),
          ),
          findsOneWidget,
        );
        expect(find.text('Đã chốt sổ'), findsNothing);
        expect(find.textContaining('Khóa lúc'), findsNothing);
        expect(_badge(tester, 'Đã khóa').tone, AppBadgeTone.ok);
        expect(_badge(tester, 'Đang nhập liệu').tone, AppBadgeTone.info);
        final badgeBox = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.widgetWithText(AppBadge, 'Đã khóa'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect(
          (badgeBox.decoration as BoxDecoration).color,
          tokens.okSoft,
          reason: 'màu huy hiệu lấy từ token của chế độ $tag',
        );
        if (width >= 768) {
          expect(
            find.byKey(const ValueKey('gradebooks-table')),
            findsOneWidget,
          );
          expect(find.text('LỚP'), findsOneWidget);
          expect(find.text('TRẠNG THÁI'), findsOneWidget);
          expect(find.text('Nhập điểm'), findsOneWidget);
          expect(find.text('Xem'), findsOneWidget);
        } else {
          expect(find.byKey(const ValueKey('gradebooks-table')), findsNothing);
          expect(find.text('10A1 · Toán'), findsOneWidget);
        }
        expect(find.text('Tạo bảng điểm'), findsOneWidget);
        expect(server.paths.any((p) => p.contains('lock')), isFalse);
        expect(tester.takeException(), isNull);
      });

      testWidgets('chi tiết đủ lịch đóng: "Khóa lúc" giờ muộn nhất, $tag', (
        tester,
      ) async {
        await _pump(
          tester,
          location: '/gradebooks/7',
          width: width,
          mode: mode,
          closes: {
            201: '2026-10-20T03:00:00.000Z',
            202: '2026-10-25T10:30:00.000Z',
          },
        );
        expect(find.text('Đang nhập liệu'), findsOneWidget);
        expect(find.text('Đã khóa'), findsNothing);
        final strip = find.byKey(const ValueKey('gradebook-close-time'));
        expect(strip, findsOneWidget);
        final local = DateTime.parse('2026-10-25T10:30:00.000Z').toLocal();
        final loc = MaterialLocalizations.of(
          tester.element(find.byKey(const ValueKey('gradebook-status-strip'))),
        );
        final expected =
            'Khóa lúc ${loc.formatShortDate(local)} '
            '${loc.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: true)}';
        expect(find.text(expected), findsOneWidget);
        expect(find.text('Phiên bản 2'), findsOneWidget);
        expect(find.text('Lưu thay đổi'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('gradebook-readonly-notice')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('chi tiết thiếu lịch một cột: không hiện hạn, $tag', (
        tester,
      ) async {
        await _pump(
          tester,
          location: '/gradebooks/7',
          width: width,
          mode: mode,
          closes: {201: '2026-10-20T03:00:00.000Z'},
        );
        expect(find.text('Đang nhập liệu'), findsOneWidget);
        expect(find.textContaining('Khóa lúc'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('chi tiết đã khóa: chỉ đọc, thông báo theo ADR-0014, $tag', (
        tester,
      ) async {
        final server = await _pump(
          tester,
          location: '/gradebooks/7',
          width: width,
          mode: mode,
          locked: true,
          closes: {
            201: '2026-10-20T03:00:00.000Z',
            202: '2026-10-25T10:30:00.000Z',
          },
        );
        expect(find.text('Đã khóa'), findsWidgets);
        expect(find.text('Đã chốt'), findsNothing);
        expect(find.textContaining('Khóa lúc'), findsOneWidget);
        expect(find.text('Lưu thay đổi'), findsNothing);
        final notice = find.byKey(const ValueKey('gradebook-readonly-notice'));
        expect(notice, findsOneWidget);
        expect(
          find.descendant(
            of: notice,
            matching: find.textContaining('nhà trường đặt', findRichText: true),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Chốt'), findsNothing);
        for (final key in ['grade-9001', 'grade-9002']) {
          final field = tester.widget<TextFormField>(find.byKey(ValueKey(key)));
          expect(field.enabled, isFalse, reason: key);
        }
        expect(server.paths.any((p) => p.contains('lock')), isFalse);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('ô điểm: đã sửa nền accSoft, không hợp lệ nền badSoft', (
    tester,
  ) async {
    await _pump(
      tester,
      location: '/gradebooks/7',
      width: 390,
      mode: Brightness.light,
    );
    final tokens = AppTokens.light;
    Color? fillOf(String key) => tester
        .widget<InputDecorator>(
          find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(InputDecorator),
          ),
        )
        .decoration
        .fillColor;

    expect(fillOf('grade-9001'), tokens.surface);
    await tester.enterText(find.byKey(const ValueKey('grade-9001')), '8.5');
    await tester.pump();
    expect(fillOf('grade-9001'), tokens.accSoft);
    await tester.enterText(find.byKey(const ValueKey('grade-9001')), '11');
    await tester.pump();
    expect(fillOf('grade-9001'), tokens.badSoft);
    await tester.enterText(find.byKey(const ValueKey('grade-9001')), '');
    await tester.pump();
    expect(fillOf('grade-9001'), tokens.surface);
    expect(find.text('● AI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final mode in Brightness.values) {
    for (final width in [320.0, 1280.0]) {
      final tag = '${mode.name} ${width.toInt()}px';

      testWidgets('hộp thoại nhập Excel: AppDialog, nút áp dụng tắt, $tag', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final theme = mode == Brightness.dark
            ? AppTheme.dark()
            : AppTheme.light();
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => ExcelImportDialog(
                        bookId: 7,
                        students: {
                          101: [_column(201, null)],
                        },
                        components: [_column(201, null)],
                        onApply: (_, _) {},
                      ),
                    ),
                    child: const Text('Mở'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Mở'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('app-dialog-box')), findsOneWidget);
        expect(find.text('Nhập điểm từ file Excel'), findsOneWidget);
        expect(find.text('Tải file mẫu (.xlsx)'), findsOneWidget);
        expect(find.text('Chọn file tải lên'), findsOneWidget);
        final apply = tester.widget<FilledButton>(
          find.byKey(const ValueKey('app-dialog-confirm')),
        );
        expect(apply.onPressed, isNull);
        await tester.tap(find.text('Đóng').last);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('app-dialog-box')), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('lịch nhập của nhà trường: cột đã khóa là AppBadge, $tag', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final locked = GradeCellDto.fromJson({
          ..._column(201, '2026-10-20T03:00:00.000Z').toJson(),
          'columnLocked': true,
        });
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: mode == Brightness.dark
                  ? AppTheme.dark()
                  : AppTheme.light(),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: GradeDeadlinesPanel(
                    bookId: 7,
                    components: [locked],
                    isAdmin: false,
                    locked: true,
                    onReload: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Lịch nhập điểm của nhà trường'));
        await tester.pumpAndSettle();
        expect(_badge(tester, 'Đã khóa').tone, AppBadgeTone.ok);
        expect(find.textContaining('Chốt'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
