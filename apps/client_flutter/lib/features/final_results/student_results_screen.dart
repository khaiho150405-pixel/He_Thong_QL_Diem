import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/design_tokens.dart';
import '../../app/widgets/app_avatar.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../app/widgets/app_tabs.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/shimmer_loading.dart';
import '../authentication/session.dart';

/// Màu và nhãn của mã xếp loại do backend trả về. Chỉ ánh xạ theo MÃ, không
/// so ngưỡng điểm ở client (AGENTS.md); mã không nhận ra thì giữ nguyên chuỗi
/// và dùng tông trung tính.
({AppBadgeTone tone, String label}) classificationBadgeOf(String code) {
  switch (code.trim().toUpperCase()) {
    case 'GIOI':
    case 'GIỎI':
      return (tone: AppBadgeTone.ok, label: 'Giỏi');
    case 'KHA':
    case 'KHÁ':
      return (tone: AppBadgeTone.info, label: 'Khá');
    case 'DAT':
    case 'ĐẠT':
    case 'TRUNG_BINH':
      return (tone: AppBadgeTone.neutral, label: 'Đạt');
    case 'CHUA_DAT':
    case 'CHƯA ĐẠT':
    case 'KHONG_DAT':
    case 'KHÔNG ĐẠT':
      return (tone: AppBadgeTone.bad, label: 'Chưa đạt');
    case 'YEU':
    case 'YẾU':
      return (tone: AppBadgeTone.bad, label: 'Yếu');
    case 'KEM':
    case 'KÉM':
      return (tone: AppBadgeTone.bad, label: 'Kém');
    default:
      return (tone: AppBadgeTone.neutral, label: code);
  }
}

class StudentResultsScreen extends ConsumerStatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  ConsumerState<StudentResultsScreen> createState() =>
      _StudentResultsScreenState();
}

class _StudentResultsScreenState extends ConsumerState<StudentResultsScreen> {
  late Future<StudentResultsDto> data;

  /// 0 = 'Thẻ theo môn', 1 = 'Bảng tổng hợp'.
  int _viewIndex = 0;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    data = ref
        .read(apiProvider)
        .getStudentResultsApi()
        .studentResultsList()
        .then((response) => response.data!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Điểm của tôi',
      currentPath: '/my-results',
      showBackButton: true,
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          onPressed: () => setState(reload),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: FutureBuilder<StudentResultsDto>(
            future: data,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: ShimmerLoading(itemCount: 4, itemHeight: 96),
                );
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.error_outline,
                  title: 'Lỗi tải kết quả',
                  message: errorMessage(snapshot.error!),
                  actionLabel: 'Thử lại',
                  onAction: () => setState(reload),
                );
              }
              final items = snapshot.data!.items;
              final summary = snapshot.data!.summary;
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'Chưa có điểm',
                  message: 'Bạn chưa có điểm đã duyệt.',
                );
              }

              final totalSubjects = summary.totalSubjects.toInt();
              final publishedSubjects = summary.publishedSubjects.toInt();
              final allPublished =
                  totalSubjects > 0 && publishedSubjects >= totalSubjects;
              final average = _formatAverage(summary.averageScore);

              // Danh sách các cột điểm thành phần duy nhất.
              final componentNames = <String>[];
              for (final item in items) {
                for (final comp in item.components) {
                  if (!componentNames.contains(comp.componentName)) {
                    componentNames.add(comp.componentName);
                  }
                }
              }

              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageCompact,
                  vertical: AppSpacing.xl,
                ),
                children: [
                  _ResultsHero(
                    className: summary.className,
                    termName: summary.termName ?? items.first.termName,
                    average: average,
                    classRank: summary.classRank?.toInt(),
                    classSize: summary.classSize.toInt(),
                    publishedSubjects: publishedSubjects,
                    totalSubjects: totalSubjects,
                    allPublished: allPublished,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Kết quả học tập các môn',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppTabs(
                    tabs: const [
                      AppTabItem(label: 'Thẻ theo môn'),
                      AppTabItem(label: 'Bảng tổng hợp'),
                    ],
                    selectedIndex: _viewIndex,
                    onChanged: (index) => setState(() => _viewIndex = index),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_viewIndex == 1)
                    _buildUnifiedGradeTable(
                      context: context,
                      items: items,
                      componentNames: componentNames,
                      average: average,
                    )
                  else
                    _buildSubjectCards(context: context, items: items),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Điểm TB học kỳ do backend tính; chỉ định dạng một chữ số thập phân để
  /// hiển thị (cùng cách với thanh bên), không tính lại ở client.
  String? _formatAverage(String? raw) {
    final value = raw == null ? null : double.tryParse(raw);
    return value?.toStringAsFixed(1);
  }

  /// Bảng tổng hợp điểm các môn (DataTable).
  Widget _buildUnifiedGradeTable({
    required BuildContext context,
    required List<StudentSubjectResultDto> items,
    required List<String> componentNames,
    required String? average,
  }) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final headStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: t.ink3,
    );
    Widget dash() => Text('—', style: TextStyle(color: t.ink3));

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Theme(
          data: theme.copyWith(dividerColor: t.line),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(t.subtle),
            columnSpacing: AppSpacing.xxl,
            horizontalMargin: AppSpacing.xl,
            columns: [
              DataColumn(label: Text('Môn học', style: headStyle)),
              for (final cName in componentNames)
                DataColumn(label: Text(cName, style: headStyle)),
              DataColumn(label: Text('ĐTB Môn', style: headStyle)),
              DataColumn(label: Text('Xếp loại', style: headStyle)),
            ],
            rows: [
              for (final item in items)
                DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.book_outlined, size: 16, color: t.pri),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            item.subjectName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: t.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final cName in componentNames)
                      DataCell(
                        Builder(
                          builder: (_) {
                            final comp = item.components
                                .cast<StudentApprovedComponentDto?>()
                                .firstWhere(
                                  (c) => c?.componentName == cName,
                                  orElse: () => null,
                                );
                            if (comp == null || comp.value.isEmpty) {
                              return dash();
                            }
                            return _Chip(
                              background: t.hover,
                              child: Text(
                                item.passFail == true
                                    ? (comp.value == '10.0'
                                          ? 'Đạt'
                                          : 'Không đạt')
                                    : comp.value,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: t.ink,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    DataCell(
                      item.finalScore != null
                          ? _Chip(
                              background: t.priSoft,
                              child: Text(
                                item.passFail == true
                                    ? (item.finalScore == '10.0'
                                          ? 'Đạt'
                                          : 'Không đạt')
                                    : item.finalScore!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: t.priLink,
                                ),
                              ),
                            )
                          : const AppBadge.warn('Chờ chốt', dot: false),
                    ),
                    DataCell(
                      item.classification != null
                          ? _classificationBadge(item.classification!)
                          : dash(),
                    ),
                  ],
                ),

              // Hàng tổng kết học kỳ: ĐTB do backend tính; backend chưa trả
              // xếp loại chung nên không tự xếp loại ở client.
              DataRow(
                color: WidgetStateProperty.all(t.subtle),
                cells: [
                  DataCell(
                    Text(
                      'ĐIỂM TRUNG BÌNH CHUNG',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: t.heading,
                      ),
                    ),
                  ),
                  for (var i = 0; i < componentNames.length; i++)
                    const DataCell(Text('')),
                  DataCell(
                    average != null
                        ? _Chip(
                            background: t.pri,
                            child: Text(
                              average,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: t.onPri,
                              ),
                            ),
                          )
                        : Text(
                            'Chờ công bố',
                            style: TextStyle(
                              fontSize: 11,
                              color: t.warn,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  DataCell(dash()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _classificationBadge(String code) {
    final badge = classificationBadgeOf(code);
    return AppBadge(badge.label, tone: badge.tone);
  }

  /// Dạng thẻ theo môn (accordion).
  Widget _buildSubjectCards({
    required BuildContext context,
    required List<StudentSubjectResultDto> items,
  }) {
    final theme = Theme.of(context);
    final t = context.tokens;
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i < items.length - 1 ? AppSpacing.md : 0,
            ),
            child: Card(
              child: ExpansionTile(
                initiallyExpanded: i == 0,
                shape: const Border(),
                collapsedShape: const Border(),
                leading: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.priSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Icon(Icons.school_outlined, color: t.pri, size: 22),
                  ),
                ),
                title: Text(
                  items[i].subjectName,
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  items[i].termName,
                  style: theme.textTheme.bodySmall,
                ),
                trailing: items[i].finalScore != null
                    ? _scoreBadge(items[i])
                    : const AppBadge.warn('Chờ chốt ĐTB', dot: false),
                children: [
                  Divider(height: 1, color: t.line),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final comp in items[i].components)
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: t.subtle,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                  border: Border.all(color: t.line),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comp.componentName,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            items[i].passFail == true
                                                ? (comp.value == '10.0'
                                                      ? 'Đạt'
                                                      : 'Không đạt')
                                                : comp.value,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: t.pri,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          Text(
                                            '(hs ${comp.coefficient})',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: t.ink3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (items[i].calculatedAt != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Đã chốt & tính ĐTB lúc ${items[i].calculatedAt!.toLocal()}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Điểm TB môn kèm mã xếp loại; tông màu theo mã (chuỗi giữ nguyên).
  Widget _scoreBadge(StudentSubjectResultDto item) {
    final score = item.passFail == true
        ? (item.finalScore == '10.0' ? 'Đạt' : 'Không đạt')
        : item.finalScore;
    final code = item.classification;
    final tone = code == null
        ? AppBadgeTone.neutral
        : classificationBadgeOf(code).tone;
    return AppBadge('$score · ${code ?? "Chưa công bố"}', tone: tone);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.background, required this.child});

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: child,
      ),
    );
  }
}

/// Khối tóm tắt đầu trang: avatar, lớp, ĐTB, xếp hạng, số môn đã có điểm.
/// Màn hẹp (dưới 600) dùng hero navy như `m-hs`, màn rộng dùng thẻ như `hs-hero`.
class _ResultsHero extends StatelessWidget {
  const _ResultsHero({
    required this.className,
    required this.termName,
    required this.average,
    required this.classRank,
    required this.classSize,
    required this.publishedSubjects,
    required this.totalSubjects,
    required this.allPublished,
  });

  final String className;
  final String termName;
  final String? average;
  final int? classRank;
  final int classSize;
  final int publishedSubjects;
  final int totalSubjects;
  final bool allPublished;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final averageText = average ?? '—';
    final rankText = classRank != null && classSize > 0
        ? '$classRank / $classSize'
        : '—';
    final subjectsText = '$publishedSubjects / $totalSubjects';
    final status = allPublished
        ? const AppBadge.ok('Đã công bố ĐTB')
        : AppBadge.warn('Đang cập nhật ($publishedSubjects/$totalSubjects)');
    final subtitle = 'Lớp $className · THPT Bà Điểm · $termName';

    return LayoutBuilder(
      builder: (context, constraints) {
        if (MediaQuery.sizeOf(context).width < 600) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: t.navy,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppAvatar(name: 'Học sinh', size: AppAvatarSize.lg),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bảng điểm cá nhân',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: t.onPri,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: t.onNavy,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _NavyScore(label: 'Điểm TB', value: averageText),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _NavyScore(label: 'Xếp hạng', value: rankText),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _NavyScore(label: 'Số môn', value: subjectsText),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  status,
                ],
              ),
            ),
          );
        }

        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bảng điểm cá nhân', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xxs),
            Text(subtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                status,
                Text(
                  'Điểm đã được giáo viên duyệt',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        );
        final stats = [
          _HeroStat(label: 'Điểm TB học kỳ', value: averageText),
          _HeroStat(label: 'Xếp hạng trong lớp', value: rankText),
          _HeroStat(label: 'Môn đã có điểm', value: subjectsText),
        ];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: constraints.maxWidth >= 800
                ? Row(
                    children: [
                      const AppAvatar(name: 'Học sinh', size: AppAvatarSize.lg),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(child: info),
                      for (final stat in stats) ...[
                        const SizedBox(width: AppSpacing.xl),
                        stat,
                      ],
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppAvatar(
                            name: 'Học sinh',
                            size: AppAvatarSize.lg,
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(child: info),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.xl,
                        runSpacing: AppSpacing.md,
                        children: stats,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// Số liệu của hero rộng (`.hs-k`): vạch kẻ bên trái, nhãn nhỏ, số lớn.
class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: t.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.66,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 28,
                height: 34 / 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ô điểm trên hero navy của mobile (`.mscore > div`).
class _NavyScore extends StatelessWidget {
  const _NavyScore({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.navyLine,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: t.onNavy),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: t.onPri,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
