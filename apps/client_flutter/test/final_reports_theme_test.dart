import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/app/widgets/app_badge.dart';
import 'package:client_flutter/app/widgets/app_charts.dart';
import 'package:client_flutter/app/widgets/stat_card.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/final_results/final_results_panel.dart';
import 'package:client_flutter/features/reports/reports_panel.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Máy chủ giả cho bước 7: kết quả tổng kết, lịch sử tính và thống kê báo cáo.
class _FakeServer implements HttpClientAdapter {
  _FakeServer({this.role = 'GIAO_VIEN', this.results = const []});

  final String role;
  final List<Map<String, dynamic>> results;

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
        'id': 2,
        'username': 'step7_test',
        'role': role,
        'active': true,
        'token': 'test-token',
        'csrf': 'test-csrf',
      };
    } else if (options.path.endsWith('/final-results/501/history')) {
      body = {
        'items': [
          {
            'id': '1',
            'resultId': '501',
            'calculatorId': 2,
            'oldScore': null,
            'oldClassification': null,
            'newScore': '8.4',
            'newClassification': 'GIOI',
            'reason': 'Tổng kết học kỳ I',
            'calculatedAt': '2026-09-13T01:00:00.000Z',
          },
          {
            'id': '2',
            'resultId': '501',
            'calculatorId': 2,
            'oldScore': '8.4',
            'oldClassification': 'GIOI',
            'newScore': '8.6',
            'newClassification': 'GIOI',
            'reason': 'Tính lại sau khi sửa điểm',
            'calculatedAt': '2026-09-14T02:30:00.000Z',
          },
        ],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/final-results') &&
        options.method == 'GET') {
      body = {
        'items': results,
        'nextCursor': null,
        'exemptedStudents': 0,
        'exempted': [],
        'skippedStudents': 0,
        'skipped': [],
      };
    } else if (options.path.endsWith('/reports/gradebooks/7/summary')) {
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
          {'classification': 'DAT', 'students': 9},
          {'classification': 'YEU', 'students': 4},
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
}

Map<String, dynamic> _result(
  String id,
  String name,
  String score,
  String code,
) => {
  'id': id,
  'studentId': 101,
  'studentName': name,
  'finalScore': score,
  'classification': code,
  'weightVersion': 'W-012345678901234567',
  'policyVersion': 'DEV-2026-01',
  'calculatedAt': '2026-09-13T01:00:00.000Z',
};

final _results = [
  _result('501', 'Nguyễn Văn An', '8.6', 'GIOI'),
  _result('502', 'Trần Thị Bích', '6.8', 'KHA'),
  _result('503', 'Lê Hoàng Cường', '5.4', 'DAT'),
  _result('504', 'Phạm Minh Đức', '3.1', 'YEU'),
];

/// Dựng một panel ở kích thước và chế độ sáng/tối cho trước, đã đăng nhập.
Future<void> _pump(
  WidgetTester tester,
  Widget panel, {
  required double width,
  required Brightness brightness,
  String role = 'GIAO_VIEN',
  List<Map<String, dynamic>>? results,
  double height = 1400,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final api = ApiClientDart(
    dio: Dio()
      ..httpClientAdapter = _FakeServer(
        role: role,
        results: results ?? _results,
      ),
  );
  final container = ProviderContainer(
    overrides: [apiProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  await tester.runAsync(
    () => container
        .read(sessionProvider.notifier)
        .login('step7_test', 'fake-password'),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: panel,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _finalPanel = FinalResultsPanel(gradebookId: 7, gradebookVersion: 4);
const _reportsPanel = ReportsPanel(gradebookId: 7);

/// Mọi `AppBadge` phải lấy màu chữ từ token đúng chế độ.
Color _badgeDotColor(WidgetTester tester, String label) {
  final badge = find.ancestor(
    of: find.text(label),
    matching: find.byType(AppBadge),
  );
  final dot = find.descendant(
    of: badge.first,
    matching: find.byKey(const ValueKey('app-badge-dot')),
  );
  final box = tester.widget<DecoratedBox>(dot).decoration as BoxDecoration;
  return box.color!;
}

void main() {
  for (final brightness in Brightness.values) {
    final tokens = brightness == Brightness.dark
        ? AppTokens.dark
        : AppTokens.light;
    for (final width in [390.0, 1280.0]) {
      final label = '${brightness.name} ${width.toInt()}px';

      testWidgets('tổng kết $label: bảng, xếp loại bằng AppBadge, không '
          'overflow', (tester) async {
        await _pump(tester, _finalPanel, width: width, brightness: brightness);

        expect(find.text('Kết quả tổng kết và xếp loại'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('calculate-final-results')),
          findsOneWidget,
        );
        if (width < 600) {
          expect(find.byType(DataTable), findsNothing);
        } else {
          expect(find.byType(DataTable), findsOneWidget);
          for (final column in [
            'STT',
            'Học sinh',
            'Điểm tổng kết',
            'Xếp loại',
            'Chi tiết',
          ]) {
            expect(find.text(column), findsOneWidget);
          }
        }
        expect(find.text('Nguyễn Văn An'), findsOneWidget);
        expect(find.text('8.6'), findsOneWidget);
        // Xếp loại ánh xạ theo mã backend.
        expect(find.byType(AppBadge), findsNWidgets(4));
        expect(_badgeDotColor(tester, 'Giỏi'), tokens.ok);
        expect(_badgeDotColor(tester, 'Khá'), tokens.priLink);
        expect(_badgeDotColor(tester, 'Đạt'), tokens.neu);
        expect(_badgeDotColor(tester, 'Yếu'), tokens.bad);
        // Dữ liệu thật: phiên bản hệ số, chính sách, thời điểm tính (hiển thị 1 lần phía trên).
        expect(
          find.textContaining('Hệ số W-012345678901234567'),
          findsOneWidget,
        );
        expect(find.textContaining('Chính sách DEV-2026-01'), findsOneWidget);
        expect(find.textContaining('Tính lúc '), findsOneWidget);
        expect(find.byTooltip('Lịch sử tính'), findsNWidgets(4));
        expect(tester.takeException(), isNull);
      });

      testWidgets('tổng kết $label: hộp thoại lý do và lịch sử', (
        tester,
      ) async {
        await _pump(tester, _finalPanel, width: width, brightness: brightness);

        await tester.tap(find.byKey(const ValueKey('calculate-final-results')));
        await tester.pumpAndSettle();
        expect(find.text('Tính kết quả tổng kết'), findsOneWidget);
        expect(find.text('Lý do tính hoặc tính lại'), findsOneWidget);
        // Lý do trống thì báo lỗi, không đóng hộp thoại.
        await tester.tap(find.text('Tính kết quả').last);
        await tester.pumpAndSettle();
        expect(find.text('Cần nhập lý do.'), findsOneWidget);
        expect(find.text('Tính kết quả tổng kết'), findsOneWidget);
        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();
        expect(find.text('Tính kết quả tổng kết'), findsNothing);

        await tester.ensureVisible(find.byTooltip('Lịch sử tính').first);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Lịch sử tính').first);
        await tester.pumpAndSettle();
        expect(find.text('Lịch sử tổng kết · Nguyễn Văn An'), findsOneWidget);
        expect(find.text('Chưa có → 8.4 · Giỏi'), findsOneWidget);
        expect(find.text('8.4 → 8.6 · Giỏi'), findsOneWidget);
        expect(find.text('Tính lại sau khi sửa điểm'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Đóng').last);
        await tester.pumpAndSettle();
        expect(find.textContaining('Lịch sử tổng kết ·'), findsNothing);
      });

      testWidgets('báo cáo $label: 6 StatCard, phổ xếp loại, xuất Excel', (
        tester,
      ) async {
        await _pump(
          tester,
          _reportsPanel,
          width: width,
          brightness: brightness,
        );

        expect(find.textContaining('Thống kê ·'), findsOneWidget);
        expect(find.byKey(const ValueKey('export-xlsx')), findsOneWidget);
        expect(find.text('Xuất Excel'), findsOneWidget);
        expect(find.byType(StatCard), findsNWidgets(6));
        for (final entry in {
          'Sĩ số học sinh': '40',
          'ĐTB lớp': '7.2',
          'Cao nhất': '9.8',
          'Thấp nhất': '2.5',
          'Đạt yêu cầu': '36',
          'Chưa đạt': '4',
        }.entries) {
          final card = find.ancestor(
            of: find.text(entry.key),
            matching: find.byType(StatCard),
          );
          expect(card, findsOneWidget);
          expect(
            find.descendant(of: card, matching: find.text(entry.value)),
            findsOneWidget,
          );
        }
        // Phân bố xếp loại: dữ liệu `distribution` của backend vẽ bằng AppHBars.
        expect(find.byType(AppHBars), findsOneWidget);
        expect(find.text('Phân bố xếp loại:'), findsOneWidget);
        expect(find.text('12 HS'), findsOneWidget);
        expect(find.text('15 HS'), findsOneWidget);
        expect(find.text('9 HS'), findsOneWidget);
        expect(find.text('4 HS'), findsOneWidget);
        final fill = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('app-hbar-fill-0')),
        );
        expect((fill.decoration as BoxDecoration).color, tokens.pri);
        final badFill = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('app-hbar-fill-3')),
        );
        expect((badFill.decoration as BoxDecoration).color, tokens.bad);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets('tổng kết trong hộp thoại bảng điểm ${brightness.name} '
        '390px, chữ 150%: không overflow, có nút đóng', (tester) async {
      await _pump(
        tester,
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => Dialog(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _finalPanel,
                ),
              ),
            ),
            child: const Text('Mở tổng kết'),
          ),
        ),
        width: 390,
        brightness: brightness,
        height: 800,
      );
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await tester.tap(find.text('Mở tổng kết'));
      await tester.pumpAndSettle();
      expect(find.text('Kết quả tổng kết và xếp loại'), findsOneWidget);
      expect(find.byType(AppBadge), findsNWidgets(4));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      expect(find.text('Kết quả tổng kết và xếp loại'), findsNothing);
    });
  }

  testWidgets('tổng kết: danh sách trống và học sinh không có nút Tính', (
    tester,
  ) async {
    await _pump(
      tester,
      _finalPanel,
      width: 390,
      brightness: Brightness.light,
      role: 'HOC_SINH',
      results: const [],
    );
    expect(find.text('Chưa tính kết quả cho bảng điểm này.'), findsOneWidget);
    expect(find.byKey(const ValueKey('calculate-final-results')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('báo cáo: chế độ compact giữ một dòng Thống kê và nút xuất', (
    tester,
  ) async {
    await _pump(
      tester,
      const ReportsPanel(gradebookId: 7, compact: true),
      width: 390,
      brightness: Brightness.dark,
    );
    expect(
      find.text(
        'Thống kê · 40 HS · ĐTB lớp 7.2 · Cao nhất 9.8 · Thấp nhất 2.5',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('export-xlsx')), findsOneWidget);
    expect(find.byType(StatCard), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
