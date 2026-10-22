import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/app/widgets/app_badge.dart';
import 'package:client_flutter/app/widgets/app_charts.dart';
import 'package:client_flutter/app/widgets/app_progress.dart';
import 'package:client_flutter/app/widgets/stat_card.dart';
import 'package:client_flutter/features/authentication/admin_charts.dart';
import 'package:client_flutter/features/authentication/presentation/widgets/home_dashboard_content.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/reports/repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Máy chủ giả chỉ trả kết quả học sinh (`/students/me/results`).
class _StudentServer implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object body = {};
    var status = 404;
    if (options.path.endsWith('/students/me/results')) {
      status = 200;
      body = {
        'items': <Object>[],
        'years': <Object>[
          {'id': 1, 'name': '2025-2026', 'className': '10A1'},
        ],
        'summary': {
          'termId': 30,
          'termName': 'Học kỳ I',
          'className': '10A1',
          'yearId': 1,
          'yearName': '2025-2026',
          'averageScore': '6.50',
          'publishedSubjects': 5,
          'totalSubjects': 6,
          'classRank': 3,
          'classSize': 38,
        },
      };
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

/// Repository giả: trả đúng dữ liệu `AdminOverviewData` được truyền vào.
class _FakeReports extends ReportsRepository {
  _FakeReports(this.data) : super(ApiClientDart(dio: Dio()));
  final AdminOverviewData data;

  @override
  Future<AdminOverviewData> adminOverview() async => data;
}

const _adminData = AdminOverviewData(
  kpi: AdminKpiData(
    totalStudents: 1248,
    totalClasses: 32,
    totalTeachers: 86,
    lockedGradebooks: 218,
    totalGradebooks: 320,
    completionRate: 68,
    pendingOcrTickets: 4,
  ),
  gradeDistribution: [
    AdminGradeDistributionItem(
      code: 'GIOI',
      label: 'Giỏi',
      count: 400,
      percentage: 40,
      color: '#173F43',
    ),
    AdminGradeDistributionItem(
      code: 'KHA',
      label: 'Khá',
      count: 350,
      percentage: 35,
      color: '#2D7D75',
    ),
    AdminGradeDistributionItem(
      code: 'DAT',
      label: 'Đạt',
      count: 200,
      percentage: 20,
      color: '#C69C3C',
    ),
    AdminGradeDistributionItem(
      code: 'CHUA_DAT',
      label: 'Chưa đạt',
      count: 50,
      percentage: 5,
      color: '#C87858',
    ),
  ],
  gradeLevelProgress: [
    AdminGradeLevelProgressItem(
      grade: 10,
      title: 'Khối 10',
      lockedClasses: 9,
      totalClasses: 11,
      percentage: 81,
    ),
    AdminGradeLevelProgressItem(
      grade: 11,
      title: 'Khối 11',
      lockedClasses: 7,
      totalClasses: 11,
      percentage: 64,
    ),
    AdminGradeLevelProgressItem(
      grade: 12,
      title: 'Khối 12',
      lockedClasses: 2,
      totalClasses: 10,
      percentage: 20,
    ),
  ],
  ocrAccuracy: AdminOcrAccuracyData(
    totalCells: 200,
    greenCount: 150,
    yellowCount: 36,
    redCount: 14,
    accuracyRate: 75,
  ),
  recentActivities: [
    AdminRecentActivityItem(
      className: '10A1',
      subjectName: 'Toán',
      teacherName: 'Nguyễn Thị Lan',
      status: 'Đã chốt',
      updatedAt: '2026-10-16T01:00:00.000Z',
    ),
    AdminRecentActivityItem(
      className: '11A3',
      subjectName: 'Ngữ văn',
      teacherName: 'Trần Văn Vinh',
      status: 'Đang nhập',
      updatedAt: '2026-10-16T01:00:00.000Z',
    ),
  ],
);

SessionDto _user(String role) => SessionDto.fromJson({
  'id': 1,
  'username': 'dash_user',
  'role': role,
  'active': true,
  'token': 'test-token',
  'csrf': 'test-csrf',
});

/// Dựng dashboard một vai ở kích thước và chế độ sáng/tối cho trước.
Future<void> _pump(
  WidgetTester tester, {
  required String role,
  required double width,
  required Brightness brightness,
}) async {
  tester.view.physicalSize = Size(width, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiProvider.overrideWithValue(
          ApiClientDart(dio: Dio()..httpClientAdapter = _StudentServer()),
        ),
        reportsRepositoryProvider.overrideWithValue(_FakeReports(_adminData)),
        teacherOverviewProvider.overrideWith(
          (ref) async => const TeacherOverviewData(
            totalGradebooks: 5,
            lockedGradebooks: 1,
            classNames: ['10A1', '11A3'],
            pendingOcrCount: 2,
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: Scaffold(
          body: HomeDashboardContent(
            user: _user(role),
            role: role,
            isDesktop: width >= 720,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Tháo cây widget để huỷ timer 10 giây của `adminOverviewProvider`.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

const _longTitle = 'B rất dài để xuống dòng thứ hai trong thẻ';

Finder _statCard(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(StatCard)).first;

void main() {
  for (final brightness in Brightness.values) {
    final tokens = brightness == Brightness.dark
        ? AppTokens.dark
        : AppTokens.light;
    for (final width in [390.0, 1280.0]) {
      final wide = width >= 720;
      final label = '${brightness.name} ${width.toInt()}px';

      testWidgets('quản trị $label: 4 KPI và 4 biểu đồ, không overflow', (
        tester,
      ) async {
        await _pump(
          tester,
          role: 'QUAN_TRI_VIEN',
          width: width,
          brightness: brightness,
        );

        expect(find.byType(StatCard), findsNWidgets(4));
        expect(find.text('Bảng điểm'), findsOneWidget);
        expect(find.text('218 / 320'), findsOneWidget);
        expect(find.text('32 lớp · 3 khối'), findsOneWidget);
        expect(find.text('68%'), findsOneWidget);
        expect(find.text('04'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(StatCard),
            matching: find.text('Học sinh'),
          ),
          findsOneWidget,
        );
        // Danh mục chỉ hiện ở mobile native (isDesktop=false, kIsWeb=false).
        expect(find.byType(ListTile), wide ? findsNothing : findsWidgets);
        expect(find.text('1248'), findsOneWidget);
        expect(find.text('39 HS / lớp'), findsOneWidget);
        // Dưới 720 px nhãn rút gọn như bản cũ.
        expect(find.text(wide ? 'Tỷ lệ hoàn thành' : 'Tỷ lệ'), findsOneWidget);
        expect(find.text(wide ? 'Đối chiếu OCR' : 'OCR'), findsOneWidget);

        // Thẻ KPI đi theo token của chế độ hiện tại.
        final card = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: _statCard('Bảng điểm'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect((card.decoration as BoxDecoration).color, tokens.surface);
        final value = tester.widget<Text>(find.text('218 / 320'));
        expect(value.style?.color, tokens.ink);
        expect(value.style?.fontSize, 30);

        // Bốn thẻ biểu đồ cao cố định.
        for (final title in [
          'Mức điểm toàn trường',
          'Đối chiếu 2 kênh Số & Chữ',
          'Tỷ lệ chốt sổ của giáo viên',
          'Hoạt động nộp điểm gần đây',
        ]) {
          expect(find.text(title), findsOneWidget);
        }
        expect(
          find.byWidgetPredicate(
            (w) => w is SizedBox && w.height == kAdminChartCardHeight,
          ),
          findsNWidgets(4),
        );

        // Phân bố học lực: màu cột lấy từ token, không dùng hex của backend.
        final bars = tester
            .widgetList<AppHBars>(find.byType(AppHBars))
            .toList();
        expect(bars, hasLength(2));
        final grade = bars.first.items;
        expect(grade.map((i) => i.label), ['Giỏi', 'Khá', 'Đạt', 'Chưa đạt']);
        expect(grade[0].color, tokens.pri);
        expect(grade[2].color, tokens.neu);
        expect(grade[3].color, tokens.bad);
        expect(grade[1].color, isNot(tokens.pri));
        expect(grade[0].valueText, '400 HS · 40%');
        // Tiến độ theo khối: 81% xanh, 64% primary, 20% amber.
        final progress = bars.last.items;
        expect(progress.map((i) => i.color), [
          tokens.ok,
          tokens.pri,
          tokens.acc,
        ]);
        expect(progress[0].valueText, '9 / 11 lớp (81%)');

        // OCR: ba badge Xanh/Vàng/Đỏ và ba thanh AppProgress.
        expect(find.text('Xanh (Khớp)'), findsOneWidget);
        expect(find.text('Vàng (Lệch)'), findsOneWidget);
        expect(find.text('Đỏ (Ô trống)'), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
        expect(find.text('75% Khớp'), findsOneWidget);
        expect(find.byType(AppProgress), findsNWidgets(3));
        expect(
          tester
              .widgetList<AppBadge>(find.byType(AppBadge))
              .where((b) => b.label == 'Đã chốt')
              .single
              .tone,
          AppBadgeTone.ok,
        );
        expect(find.text('Đang nhập'), findsOneWidget);
        expect(find.text('Trực tiếp (10s)'), findsOneWidget);
        expect(find.byTooltip('Làm mới dữ liệu ngay'), findsOneWidget);

        expect(tester.takeException(), isNull);
        await _unmount(tester);
      });

      testWidgets('giáo viên $label: 3 KPI, không overflow', (tester) async {
        await _pump(
          tester,
          role: 'GIAO_VIEN',
          width: width,
          brightness: brightness,
        );

        expect(find.byType(StatCard), findsNWidgets(3));
        expect(find.text('Phụ trách'), findsOneWidget);
        expect(find.text('2 lớp'), findsOneWidget);
        expect(find.text('10A1, 11A3'), findsOneWidget);
        expect(find.text('Tiến độ nhập'), findsOneWidget);
        expect(find.text('20%'), findsOneWidget);
        expect(find.text('1 / 5 bảng đã chốt'), findsOneWidget);
        expect(find.text('OCR chờ duyệt'), findsOneWidget);
        expect(find.text('02 phiếu'), findsOneWidget);
        expect(find.text('Cần xác nhận kết quả'), findsOneWidget);
        // Không có biểu đồ của quản trị.
        expect(find.byType(AppHBars), findsNothing);
        expect(find.text('Xin chào, dash_user'), findsOneWidget);

        final card = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: _statCard('Phụ trách'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect((card.decoration as BoxDecoration).color, tokens.surface);
        expect(tester.takeException(), isNull);
        await _unmount(tester);
      });

      testWidgets('học sinh $label: 3 KPI, không overflow', (tester) async {
        await _pump(
          tester,
          role: 'HOC_SINH',
          width: width,
          brightness: brightness,
        );

        expect(find.byType(StatCard), findsNWidgets(3));
        expect(find.text('ĐTB học kỳ'), findsOneWidget);
        expect(find.text('6.5'), findsOneWidget);
        expect(find.text('Học kỳ I'), findsOneWidget);
        expect(find.text('Môn đã chốt'), findsOneWidget);
        expect(find.text('5 / 6'), findsOneWidget);
        expect(find.text('Chỉ tính bảng điểm đã chốt'), findsOneWidget);
        expect(find.text('Xếp hạng lớp'), findsOneWidget);
        expect(find.text('3 / 38'), findsOneWidget);
        expect(find.text('Lớp 10A1'), findsOneWidget);
        expect(find.byType(AppHBars), findsNothing);

        final value = tester.widget<Text>(find.text('6.5'));
        expect(value.style?.color, tokens.ink);
        expect(tester.takeException(), isNull);
        await _unmount(tester);
      });
    }
  }

  testWidgets('StatCardGrid: 4 thẻ rộng 1 hàng, hẹp 2 hàng, cùng hàng cao bằng '
      'nhau', (tester) async {
    Future<void> pump(double width) async {
      tester.view.physicalSize = Size(width + 32, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: StatCardGrid(
                children: const [
                  StatCard(title: 'A', value: '1', icon: Icons.star),
                  StatCard(
                    title: _longTitle,
                    value: '2',
                    icon: Icons.star,
                    subtitle: 'phụ',
                    tone: StatTone.ok,
                  ),
                  StatCard(title: 'C', value: '3', icon: Icons.star),
                  StatCard(title: 'D', value: '4', icon: Icons.star),
                ],
              ),
            ),
          ),
        ),
      );
    }

    await pump(1000);
    final tops = {
      for (final k in ['A', _longTitle, 'C', 'D'])
        tester.getTopLeft(_statCard(k)).dy.round(),
    };
    expect(tops, hasLength(1));

    await pump(390);
    final topsNarrow = {
      for (final k in ['A', _longTitle, 'C', 'D'])
        tester.getTopLeft(_statCard(k)).dy.round(),
    };
    expect(topsNarrow, hasLength(2));
    expect(
      tester.getSize(_statCard('A')).height,
      tester.getSize(find.byType(StatCard).at(1)).height,
    );
    expect(tester.takeException(), isNull);
  });
}
