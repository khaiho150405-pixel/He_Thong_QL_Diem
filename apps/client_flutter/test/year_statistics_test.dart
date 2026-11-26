import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/features/academic_catalog/academic_year_scope.dart';
import 'package:client_flutter/features/reports/repository.dart';
import 'package:client_flutter/features/reports/year_statistics_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

StatisticsGroupDto _group(String label, {bool levels = true}) =>
    StatisticsGroupDto(
      key: label.hashCode,
      label: label,
      students: 40,
      average: '7.25',
      fromEight: 12,
      fromSixHalf: 15,
      fromFive: 9,
      belowFive: 4,
      passed: 38,
      failed: 2,
      missing: 0,
      levels: levels
          ? LevelCountsDto(
              TOT: 5,
              KHA: 20,
              DAT: 14,
              CHUA_DAT: 1,
              CHUA_DU_MON: 0,
            )
          : null,
    );

class _FakeReports extends ReportsRepository {
  _FakeReports() : super(ApiClientDart(dio: Dio()));
  final requested = <(num, int)>[];

  @override
  Future<YearStatisticsDto> yearStatistics(num yearId, int term) async {
    requested.add((yearId, term));
    return YearStatisticsDto(
      yearId: yearId,
      yearName: '2025-2026',
      source_: 'BAN_CHOT',
      snapshotVersion: 2,
      snapshotAt: '2026-06-30T00:00:00Z',
      total: term == 1 ? _group('Toàn trường') : null,
      grades: [_group('Khối 12')],
      classes: [_group('12A1')],
      subjects: [_group('Toán', levels: false)],
    );
  }

  @override
  Future<List<YearComparisonItemDto>> yearComparison(int term) async => [
    YearComparisonItemDto(
      key: 0,
      label: 'Toàn trường',
      students: 120,
      average: '6.90',
      fromEight: 1,
      fromSixHalf: 2,
      fromFive: 3,
      belowFive: 4,
      passed: 5,
      failed: 6,
      missing: 0,
      levels: null,
      yearId: 1,
      yearName: '2024-2025',
      source_: 'HIEN_TAI',
    ),
  ];
}

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets('thống kê năm học theo nhóm và so sánh, ${width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final reports = _FakeReports();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportsRepositoryProvider.overrideWithValue(reports),
            academicYearsProvider.overrideWith(
              (ref) async => [
                {'ma_nam_hoc': 7, 'ten': '2025-2026', 'hien_hanh': true},
              ],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const YearStatisticsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(reports.requested, [(7, 1)]);
      expect(find.text('Bản chốt cuối năm · phiên bản 2'), findsOneWidget);
      expect(find.textContaining('Khối 12'), findsOneWidget);
      expect(find.textContaining('Mức Tốt'), findsOneWidget);

      await tester.ensureVisible(find.text('Theo môn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Theo môn'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Toán'), findsOneWidget);
      expect(find.textContaining('Mức Tốt'), findsNothing);

      await tester.ensureVisible(find.text('So sánh các năm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('So sánh các năm'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('2024-2025 (Dữ liệu hiện tại)'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('statistics-export')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
