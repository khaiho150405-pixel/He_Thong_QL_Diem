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
import 'merged_view_widgets.dart';
import 'repository.dart';

/// Dữ liệu thô của màn: đọc từ `catalogRepositoryProvider.list`, không ghi.
class _Source {
  const _Source({
    required this.subjects,
    required this.components,
    required this.weights,
    required this.semesters,
  });

  final List<Json> subjects;
  final List<Json> components;
  final List<Json> weights;
  final List<Json> semesters;
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
  late Future<_Source> _future;
  num? _semesterId;

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
    ]);
    return _Source(
      subjects: results[0],
      components: results[1],
      weights: results[2],
      semesters: results[3],
    );
  }

  void _reload() => setState(() => _future = _load());

  /// Học kỳ đang chọn; chưa chọn thì lấy học kỳ đầu tiên có dòng hệ số.
  num? _activeSemester(_Source data) {
    if (_semesterId != null) return _semesterId;
    for (final s in data.semesters) {
      final id = s['ma_hoc_ky'];
      if (id is num && data.weights.any((w) => w['ma_hoc_ky'] == id)) {
        return id;
      }
    }
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

  Widget _weightsCard(BuildContext context, _Source data, num? semester) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final weights = _weightsOf(data, semester);
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
              for (final s in data.semesters)
                if (s['ma_hoc_ky'] is num)
                  DropdownMenuItem(
                    value: s['ma_hoc_ky'] as num,
                    child: Text(s['label']?.toString() ?? s['ten'].toString()),
                  ),
            ],
            onChanged: (value) => setState(() => _semesterId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          if (codes.isEmpty)
            Text(
              'Học kỳ này chưa có hệ số được cấu hình.',
              style: theme.textTheme.bodyMedium?.copyWith(color: t.ink2),
            )
          else
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider);
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
                    return _content(context, snapshot.data!);
                  },
                ),
              ),
            ),
    );
  }

  Widget _content(BuildContext context, _Source data) {
    final semester = _activeSemester(data);
    final weights = _weightsOf(data, semester);
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
            final weightsCard = _weightsCard(context, data, semester);
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
