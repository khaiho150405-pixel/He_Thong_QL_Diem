import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_controls.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/shimmer_loading.dart';
import '../../core/vietnamese_sort.dart';
import '../authentication/session.dart';
import 'academic_year_scope.dart';
import 'merged_view_widgets.dart';
import 'repository.dart';

/// Dữ liệu thô của màn: đọc từ `catalogRepositoryProvider.list`, không ghi.
class _Source {
  const _Source({
    required this.subjects,
    required this.components,
    required this.weights,
    required this.semesters,
    required this.years,
  });

  final List<Json> subjects;
  final List<Json> components;
  final List<Json> weights;
  final List<Json> semesters;
  final List<Json> years;
}

/// Hiển thị số hệ số lấy từ dữ liệu ("1.00" thành "1"); không tính toán.
String _formatCoefficient(String raw) {
  final value = double.tryParse(raw);
  if (value == null) return raw;
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

/// Tên đầy đủ của mã nhóm điểm, chỉ để hiển thị; mã lạ giữ nguyên.
String _groupName(String code) => switch (code) {
  'TX' => 'Thường xuyên',
  'GK' => 'Giữa kỳ',
  'CK' => 'Cuối kỳ',
  _ => code,
};

/// QT · Môn học & hệ số (`ad-subjects`). Chỉ đọc: ghép client-side môn học,
/// thành phần điểm và hệ số học kỳ; không nêu công thức tính điểm. Sửa ở các
/// màn danh mục.
class SubjectsWeightsScreen extends ConsumerStatefulWidget {
  const SubjectsWeightsScreen({super.key});

  @override
  ConsumerState<SubjectsWeightsScreen> createState() =>
      _SubjectsWeightsScreenState();
}

class _SubjectsWeightsScreenState extends ConsumerState<SubjectsWeightsScreen> {
  static const Map<String, String> _defaultWeights = {
    'TX': '1',
    'GK': '2',
    'CK': '3',
  };

  late Future<_Source> _future;
  num? _semesterId;
  ViewingYear? _lastViewingYear;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Source> _load() async {
    final repository = ref.read(catalogRepositoryProvider);
    final results = await Future.wait([
      fetchAllCatalogRows(repository, 'subjects'),
      fetchAllCatalogRows(repository, 'components'),
      fetchAllCatalogRows(repository, 'semester-weights'),
      fetchAllCatalogRows(repository, 'semesters'),
      fetchAllCatalogRows(repository, 'years').catchError((_) => <Json>[]),
    ]);
    return _Source(
      subjects: results[0],
      components: results[1],
      weights: results[2],
      semesters: results[3],
      years: results[4],
    );
  }

  void _reload() => setState(() => _future = _load());

  Map<num, Json> _buildYearMap(List<Json> years) => {
    for (final y in years)
      if (y['ma_nam_hoc'] is num) y['ma_nam_hoc'] as num: y,
  };

  List<Json> _filterAndSortSemesters(
    List<Json> semesters,
    Map<num, Json> yearMap,
    ViewingYear? viewingYear,
  ) {
    final filtered = viewingYear?.id != null
        ? semesters.where((s) => s['ma_nam_hoc'] == viewingYear!.id).toList()
        : [...semesters];

    filtered.sort((a, b) {
      final yearA = yearMap[a['ma_nam_hoc']];
      final yearB = yearMap[b['ma_nam_hoc']];
      final startA = yearA?['ngay_bat_dau']?.toString() ?? '';
      final startB = yearB?['ngay_bat_dau']?.toString() ?? '';
      final yearCmp = startB.compareTo(startA);
      if (yearCmp != 0) return yearCmp;

      final idA = (a['ma_nam_hoc'] as num?) ?? 0;
      final idB = (b['ma_nam_hoc'] as num?) ?? 0;
      final idCmp = idB.compareTo(idA);
      if (idCmp != 0) return idCmp;

      final thuTuA = (a['thu_tu'] as num?) ?? 0;
      final thuTuB = (b['thu_tu'] as num?) ?? 0;
      return thuTuA.compareTo(thuTuB);
    });

    return filtered;
  }

  String _semesterLabel(Json s, Map<num, Json> yearMap) {
    final semTen = (s['ten'] ?? s['label'] ?? (s['thu_tu'] != null ? 'Học kỳ ${s['thu_tu']}' : 'Học kỳ')).toString().trim();
    final yearId = s['ma_nam_hoc'];
    final yearRow = yearId is num ? yearMap[yearId] : null;
    final yearName = (yearRow?['ten'] ?? yearRow?['label'] ?? '').toString().trim();
    if (yearName.isNotEmpty && !semTen.contains(yearName)) {
      return '$semTen · $yearName';
    }
    return semTen;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Thứ tự ưu tiên chọn học kỳ:
  /// 1. Học kỳ người dùng đã chọn (nếu có trong validSemesters).
  /// 2. Học kỳ của năm đang xem đang diễn ra theo ngày hôm nay.
  /// 3. Học kỳ có thu_tu nhỏ nhất của năm đang xem.
  /// 4. Học kỳ đầu danh sách.
  num? _activeSemester(List<Json> validSemesters) {
    if (validSemesters.isEmpty) return null;

    if (_semesterId != null &&
        validSemesters.any((s) => s['ma_hoc_ky'] == _semesterId)) {
      return _semesterId;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final s in validSemesters) {
      final start = _parseDate(s['ngay_bat_dau']);
      final end = _parseDate(s['ngay_ket_thuc']);
      if (start != null && end != null) {
        final startDate = DateTime(start.year, start.month, start.day);
        final endDate = DateTime(end.year, end.month, end.day);
        if (!today.isBefore(startDate) && !today.isAfter(endDate)) {
          final id = s['ma_hoc_ky'];
          if (id is num) return id;
        }
      }
    }

    Json? minThuTuSem;
    for (final s in validSemesters) {
      final tt = s['thu_tu'];
      if (tt is num) {
        if (minThuTuSem == null || (minThuTuSem['thu_tu'] as num) > tt) {
          minThuTuSem = s;
        }
      }
    }
    if (minThuTuSem != null && minThuTuSem['ma_hoc_ky'] is num) {
      return minThuTuSem['ma_hoc_ky'] as num;
    }

    final firstId = validSemesters.first['ma_hoc_ky'];
    if (firstId is num) return firstId;

    return null;
  }

  /// Nhóm điểm (TX/GK/CK) thành chuỗi hệ số của học kỳ đang chọn.
  Map<String, String> _weightsOf(_Source data, num? semester) => {
    if (semester != null)
      for (final w in data.weights)
        if (w['ma_hoc_ky'] == semester && w['loai_he_so'] != null)
          w['loai_he_so'].toString(): w['he_so'].toString(),
  };

  Widget _componentChips(
    List<Json> components,
    Map<String, String> weights,
    BuildContext context,
  ) {
    if (components.isEmpty) {
      return Text('—', style: TextStyle(color: context.tokens.ink3));
    }
    return Wrap(
      spacing: AppSpacing.xs + 2,
      runSpacing: AppSpacing.xs + 2,
      children: [
        for (final c in components)
          MergedChip(
            text: c['ten_thanh_phan']?.toString() ?? c['label'].toString(),
            strongText: _chipSuffix(c['loai_he_so']?.toString(), weights),
          ),
      ],
    );
  }

  /// "TX ×1" khi có hệ số trong dữ liệu; chỉ "TX" khi học kỳ chưa có hệ số.
  String? _chipSuffix(String? group, Map<String, String> weights) {
    if (group == null || group.isEmpty) return null;
    final coefficient = weights[group];
    return coefficient == null
        ? group
        : '$group ×${_formatCoefficient(coefficient)}';
  }

  Widget _subjectName(Json subject, BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final pass = subject['danh_gia_dat'] == true;
    final periods = subject['so_tiet_tuan'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subject['ten_mon']?.toString() ?? subject['label'].toString(),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: t.heading,
          ),
        ),
        if (periods != null)
          Text(
            '$periods tiết/tuần',
            style: theme.textTheme.bodySmall?.copyWith(color: t.ink3),
          ),
        if (pass)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: AppBadge.info('Đạt/Không đạt', dot: false),
          ),
      ],
    );
  }

  Widget _countText(int count, BuildContext context) => Text(
    '$count',
    style: TextStyle(
      color: context.tokens.ink,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );

  List<Json> _componentsOf(_Source data, Json subject) {
    final list = data.components
        .where((c) => c['ma_mon'] == subject['ma_mon'])
        .toList();
    list.sort(
      (a, b) => ((a['thu_tu_hien_thi'] as num?) ?? 0).compareTo(
        (b['thu_tu_hien_thi'] as num?) ?? 0,
      ),
    );
    return list;
  }

  Widget _subjectsTable(
    BuildContext context,
    _Source data,
    Map<String, String> weights,
    List<Json> subjects,
  ) {
    return MergedTable(
      key: const ValueKey('subjects-table'),
      columns: const [
        MergedColumn('Môn học', flex: 3),
        MergedColumn('Thành phần điểm', flex: 6),
        MergedColumn('Số thành phần', width: 108, alignEnd: true),
      ],
      rows: [
        for (final subject in subjects)
          [
            _subjectName(subject, context),
            _componentChips(_componentsOf(data, subject), weights, context),
            _countText(_componentsOf(data, subject).length, context),
          ],
      ],
    );
  }

  Widget _subjectCard(
    BuildContext context,
    _Source data,
    Map<String, String> weights,
    Json subject,
  ) {
    final t = context.tokens;
    final components = _componentsOf(data, subject);
    return MergedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _subjectName(subject, context)),
              Text(
                '${components.length} thành phần',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: t.ink3),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _componentChips(components, weights, context),
        ],
      ),
    );
  }

  Widget _weightsCard(
    BuildContext context,
    _Source data,
    num? semester,
    List<Json> validSemesters,
    Map<num, Json> yearMap,
    Map<String, String> weights,
    bool isDefault,
  ) {
    final t = context.tokens;
    final theme = Theme.of(context);
    const order = ['TX', 'GK', 'CK'];
    final codes = [
      ...order.where(weights.containsKey),
      ...weights.keys.where((k) => !order.contains(k)),
    ];
    return MergedCard(
      key: const ValueKey('weights-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hệ số học kỳ',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: t.heading,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Dùng chung cho mọi môn trong cùng một học kỳ.',
            style: theme.textTheme.bodySmall?.copyWith(color: t.ink3),
          ),
          const SizedBox(height: AppSpacing.md),
          AppFilterDropdown<num>(
            key: const ValueKey('weights-semester-filter'),
            label: 'Học kỳ',
            icon: Icons.date_range_outlined,
            value: semester,
            width: double.infinity,
            items: [
              for (final s in validSemesters)
                if (s['ma_hoc_ky'] is num)
                  DropdownMenuItem(
                    value: s['ma_hoc_ky'] as num,
                    child: Text(_semesterLabel(s, yearMap)),
                  ),
            ],
            onChanged: (value) => setState(() => _semesterId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          if (codes.isEmpty)
            Text(
              'Chưa có học kỳ nào.',
              style: theme.textTheme.bodyMedium?.copyWith(color: t.ink2),
            )
          else ...[
            for (final code in codes) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_groupName(code)} ($code)',
                      style: theme.textTheme.bodyMedium?.copyWith(color: t.ink),
                    ),
                  ),
                  Text(
                    '×${_formatCoefficient(weights[code]!)}',
                    key: ValueKey('weight-$code'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: t.priLink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (code != codes.last)
                Divider(height: AppSpacing.xl, color: t.line),
            ],
            if (isDefault) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Đang dùng hệ số mặc định (chưa cấu hình riêng cho học kỳ này).',
                style: theme.textTheme.bodySmall?.copyWith(color: t.ink3),
              ),
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider);
    final viewingYear = ref.watch(viewingYearProvider);
    if (_lastViewingYear != viewingYear) {
      _lastViewingYear = viewingYear;
      _semesterId = null;
    }

    return AppScaffold(
      title: 'Môn học & hệ số',
      currentPath: '/admin/subjects-weights',
      showBackButton: true,
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: user == null
          ? const SizedBox.shrink()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1140),
                child: FutureBuilder<_Source>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: ShimmerLoading(itemCount: 5, itemHeight: 72),
                      );
                    }
                    if (snapshot.hasError) {
                      return EmptyState(
                        icon: Icons.error_outline,
                        title: 'Lỗi tải môn học và hệ số',
                        message: errorMessage(snapshot.error!),
                        actionLabel: 'Thử lại',
                        onAction: _reload,
                      );
                    }
                    return _content(context, snapshot.data!, viewingYear);
                  },
                ),
              ),
            ),
    );
  }

  Widget _content(
    BuildContext context,
    _Source data,
    ViewingYear? viewingYear,
  ) {
    final yearMap = _buildYearMap(data.years);
    final validSemesters = _filterAndSortSemesters(
      data.semesters,
      yearMap,
      viewingYear,
    );
    final semester = _activeSemester(validSemesters);
    final configured = _weightsOf(data, semester);
    final isDefault = configured.isEmpty && semester != null;
    final weights = isDefault ? _defaultWeights : configured;

    final subjects = [...data.subjects]
      ..sort(
        (a, b) => VietnameseCollation.compare(
          a['ten_mon']?.toString() ?? '',
          b['ten_mon']?.toString() ?? '',
        ),
      );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const MergedViewHeader(
          description:
              'Mỗi môn gồm các thành phần điểm thuộc nhóm TX, GK hoặc CK; '
              'hệ số của từng nhóm theo học kỳ. Màn này chỉ để xem; sửa ở '
              'các màn quản lý.',
          links: [
            (
              label: 'Quản lý môn học',
              icon: Icons.menu_book_outlined,
              route: '/catalog/subjects',
            ),
            (
              label: 'Quản lý thành phần điểm',
              icon: Icons.tune_outlined,
              route: '/catalog/components',
            ),
            (
              label: 'Quản lý hệ số học kỳ',
              icon: Icons.percent_outlined,
              route: '/catalog/semester-weights',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, box) {
            final weightsCard = _weightsCard(
              context,
              data,
              semester,
              validSemesters,
              yearMap,
              weights,
              isDefault,
            );
            final Widget list = subjects.isEmpty
                ? const SizedBox(
                    height: 280,
                    child: EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'Chưa có môn học',
                      message:
                          'Thêm môn học ở màn quản lý môn học để xem thành '
                          'phần điểm tại đây.',
                    ),
                  )
                : box.maxWidth >= 768
                ? _subjectsTable(context, data, weights, subjects)
                : Column(
                    children: [
                      for (final s in subjects) ...[
                        _subjectCard(context, data, weights, s),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  );
            if (box.maxWidth >= 1024) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: list),
                  const SizedBox(width: AppSpacing.gridGap),
                  SizedBox(width: 300, child: weightsCard),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                weightsCard,
                const SizedBox(height: AppSpacing.gridGap),
                list,
              ],
            );
          },
        ),
      ],
    );
  }
}
