import 'package:api_client_dart/api_client_dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_controls.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../app/widgets/app_tabs.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/shimmer_loading.dart';
import '../../app/widgets/stat_card.dart';
import '../academic_catalog/academic_year_scope.dart';
import '../authentication/session.dart';
import '../gradebooks/excel_file_name.dart';
import 'repository.dart';

final yearStatisticsProvider = FutureProvider.autoDispose
    .family<YearStatisticsDto, ({num yearId, int term})>(
      (ref, query) => ref
          .watch(reportsRepositoryProvider)
          .yearStatistics(query.yearId, query.term),
    );

final yearComparisonProvider = FutureProvider.autoDispose
    .family<List<YearComparisonItemDto>, int>(
      (ref, term) => ref.watch(reportsRepositoryProvider).yearComparison(term),
    );

typedef _Row = ({String name, StatisticsValues values});

class StatisticsValues {
  const StatisticsValues({
    required this.students,
    required this.average,
    required this.fromEight,
    required this.fromSixHalf,
    required this.fromFive,
    required this.belowFive,
    required this.passed,
    required this.failed,
    required this.levels,
  });

  StatisticsValues.group(StatisticsGroupDto group)
    : students = group.students,
      average = group.average,
      fromEight = group.fromEight,
      fromSixHalf = group.fromSixHalf,
      fromFive = group.fromFive,
      belowFive = group.belowFive,
      passed = group.passed,
      failed = group.failed,
      levels = group.levels;

  StatisticsValues.year(YearComparisonItemDto item)
    : students = item.students,
      average = item.average,
      fromEight = item.fromEight,
      fromSixHalf = item.fromSixHalf,
      fromFive = item.fromFive,
      belowFive = item.belowFive,
      passed = item.passed,
      failed = item.failed,
      levels = item.levels;

  final num students;
  final String? average;
  final num fromEight;
  final num fromSixHalf;
  final num fromFive;
  final num belowFive;
  final num passed;
  final num failed;
  final LevelCountsDto? levels;

  List<(String, String)> cells({required bool withLevels}) => [
    ('Số học sinh', '$students'),
    ('ĐTB', average ?? '—'),
    ('Từ 8,0', '$fromEight'),
    ('6,5 – 7,9', '$fromSixHalf'),
    ('5,0 – 6,4', '$fromFive'),
    ('Dưới 5,0', '$belowFive'),
    ('Môn Đạt', '$passed'),
    ('Môn chưa đạt', '$failed'),
    if (withLevels) ...[
      ('Mức Tốt', '${levels?.TOT ?? 0}'),
      ('Mức Khá', '${levels?.KHA ?? 0}'),
      ('Mức Đạt', '${levels?.DAT ?? 0}'),
      ('Mức Chưa đạt', '${levels?.CHUA_DAT ?? 0}'),
      ('Chưa đủ môn', '${levels?.CHUA_DU_MON ?? 0}'),
    ],
  ];
}

String _sourceText(String source, num? version) => source == 'BAN_CHOT'
    ? version == null
          ? 'Bản chốt cuối năm'
          : 'Bản chốt cuối năm · phiên bản $version'
    : 'Dữ liệu hiện tại';

class YearStatisticsScreen extends ConsumerStatefulWidget {
  const YearStatisticsScreen({super.key});

  @override
  ConsumerState<YearStatisticsScreen> createState() =>
      _YearStatisticsScreenState();
}

class _YearStatisticsScreenState extends ConsumerState<YearStatisticsScreen> {
  int _term = 1;
  int _view = 0;
  bool _exporting = false;

  Map<String, dynamic>? _selectedYear(List<Map<String, dynamic>> years) {
    final viewing = ref.watch(viewingYearProvider)?.id;
    return years.where((year) => year['ma_nam_hoc'] == viewing).firstOrNull ??
        years.where((year) => year['hien_hanh'] == true).firstOrNull ??
        years.firstOrNull;
  }

  Future<void> _export(num yearId, String yearName) async {
    setState(() => _exporting = true);
    try {
      final bytes = await ref
          .read(reportsRepositoryProvider)
          .exportYear(yearId, _term);
      final path = await FilePicker.saveFile(
        dialogTitle: 'Lưu tổng hợp năm học',
        fileName: excelFileName(['Tổng hợp', yearName, 'Học kỳ $_term']),
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        bytes: bytes,
      );
      _notify(path == null ? 'Đã hủy lưu tệp.' : 'Đã xuất Excel thành công.');
    } catch (error) {
      _notify(errorMessage(error));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final years = ref.watch(academicYearsProvider);
    return AppScaffold(
      title: 'Thống kê năm học',
      currentPath: '/admin/year-statistics',
      showBackButton: true,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: years.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: ShimmerLoading(itemCount: 4, itemHeight: 80),
            ),
            error: (error, _) => _failure(
              errorMessage(error),
              () => ref.invalidate(academicYearsProvider),
            ),
            data: (items) {
              final year = _selectedYear(items);
              if (year == null) {
                return const EmptyState(
                  icon: Icons.calendar_month_outlined,
                  title: 'Chưa có năm học',
                  message: 'Thêm năm học trong danh mục trước khi thống kê.',
                );
              }
              return _content(items, year);
            },
          ),
        ),
      ),
    );
  }

  Widget _failure(String message, VoidCallback retry) => Center(
    child: EmptyState(
      icon: Icons.error_outline,
      title: 'Chưa tải được thống kê',
      message: message,
      actionLabel: 'Thử lại',
      onAction: retry,
    ),
  );

  Widget _content(List<Map<String, dynamic>> years, Map<String, dynamic> year) {
    final yearId = year['ma_nam_hoc'] as num;
    final yearName = year['ten']?.toString() ?? '';
    final comparing = _view == 3;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!comparing)
              AcademicYearFilterControl(
                years: years,
                allowAll: false,
                onChanged: () {},
              ),
            AppFilterDropdown<int>(
              key: const ValueKey('statistics-term'),
              label: 'Học kỳ',
              icon: Icons.date_range_outlined,
              value: _term,
              width: 200,
              items: const [
                DropdownMenuItem(value: 1, child: Text('Học kỳ 1')),
                DropdownMenuItem(value: 2, child: Text('Học kỳ 2')),
              ],
              onChanged: (value) => setState(() => _term = value ?? _term),
            ),
            if (!comparing)
              FilledButton.icon(
                key: const ValueKey('statistics-export'),
                onPressed: _exporting ? null : () => _export(yearId, yearName),
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Xuất Excel'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTabs(
          tabs: const [
            AppTabItem(label: 'Theo khối'),
            AppTabItem(label: 'Theo lớp'),
            AppTabItem(label: 'Theo môn'),
            AppTabItem(label: 'So sánh các năm'),
          ],
          selectedIndex: _view,
          onChanged: (index) => setState(() => _view = index),
        ),
        const SizedBox(height: AppSpacing.md),
        if (comparing) _comparison() else _statistics(yearId),
      ],
    );
  }

  Widget _statistics(num yearId) {
    final query = (yearId: yearId, term: _term);
    return ref
        .watch(yearStatisticsProvider(query))
        .when(
          skipLoadingOnRefresh: false,
          loading: () => const ShimmerLoading(itemCount: 3, itemHeight: 80),
          error: (error, _) => _failure(
            errorMessage(error),
            () => ref.invalidate(yearStatisticsProvider(query)),
          ),
          data: (data) {
            final total = data.total;
            if (total == null) {
              return const EmptyState(
                icon: Icons.query_stats_outlined,
                title: 'Chưa có số liệu',
                message: 'Học kỳ này chưa có kết quả đã công bố.',
              );
            }
            final levels = total.levels;
            final groups = switch (_view) {
              0 => data.grades,
              1 => data.classes,
              _ => data.subjects,
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBadge(
                  _sourceText(data.source_, data.snapshotVersion),
                  tone: data.source_ == 'BAN_CHOT'
                      ? AppBadgeTone.ok
                      : AppBadgeTone.info,
                ),
                const SizedBox(height: AppSpacing.md),
                StatCardGrid(
                  children: [
                    StatCard(
                      title: 'Học sinh',
                      value: '${total.students}',
                      subtitle: 'Toàn trường',
                      icon: Icons.school_outlined,
                    ),
                    StatCard(
                      title: 'Điểm trung bình',
                      value: total.average ?? '—',
                      subtitle: 'Các môn tính điểm',
                      icon: Icons.functions_rounded,
                    ),
                    StatCard(
                      title: 'Tốt và Khá',
                      value: '${(levels?.TOT ?? 0) + (levels?.KHA ?? 0)}',
                      subtitle: '${levels?.CHUA_DU_MON ?? 0} em chưa đủ môn',
                      icon: Icons.trending_up_rounded,
                      tone: StatTone.ok,
                    ),
                    StatCard(
                      title: 'Điểm dưới 5,0',
                      value: '${total.belowFive}',
                      subtitle: 'Lượt môn',
                      icon: Icons.warning_amber_rounded,
                      tone: StatTone.warn,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _table(
                  switch (_view) {
                    0 => 'Khối',
                    1 => 'Lớp',
                    _ => 'Môn học',
                  },
                  [
                    for (final group in groups)
                      (
                        name: group.label,
                        values: StatisticsValues.group(group),
                      ),
                  ],
                  withLevels: _view != 2,
                ),
              ],
            );
          },
        );
  }

  Widget _comparison() => ref
      .watch(yearComparisonProvider(_term))
      .when(
        skipLoadingOnRefresh: false,
        loading: () => const ShimmerLoading(itemCount: 3, itemHeight: 80),
        error: (error, _) => _failure(
          errorMessage(error),
          () => ref.invalidate(yearComparisonProvider(_term)),
        ),
        data: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.query_stats_outlined,
                title: 'Chưa có số liệu',
                message: 'Chưa năm nào công bố kết quả của học kỳ này.',
              )
            : _table('Năm học', [
                for (final item in items)
                  (
                    name:
                        '${item.yearName} (${_sourceText(item.source_, null)})',
                    values: StatisticsValues.year(item),
                  ),
              ], withLevels: true),
      );

  Widget _table(String heading, List<_Row> rows, {required bool withLevels}) {
    final t = context.tokens;
    if (MediaQuery.sizeOf(context).width < 600) {
      return Column(
        children: [
          for (final row in rows)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: t.heading,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final (label, value) in row.values.cells(
                          withLevels: withLevels,
                        ))
                          Text(
                            '$label: $value',
                            style: TextStyle(fontSize: 12, color: t.ink2),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    final labels = [
      for (final (label, _) in rows.first.values.cells(withLevels: withLevels))
        label,
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: AppSpacing.lg,
              headingRowColor: WidgetStateProperty.all(t.subtle),
              columns: [
                DataColumn(label: Text(heading)),
                for (final label in labels)
                  DataColumn(label: Text(label), numeric: true),
              ],
              rows: [
                for (final row in rows)
                  DataRow(
                    cells: [
                      DataCell(Text(row.name)),
                      for (final (_, value) in row.values.cells(
                        withLevels: withLevels,
                      ))
                        DataCell(Text(value)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
