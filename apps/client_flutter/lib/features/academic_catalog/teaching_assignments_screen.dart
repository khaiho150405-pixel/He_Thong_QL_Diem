import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_avatar.dart';
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
    required this.teachers,
    required this.assignments,
    required this.classes,
    required this.subjects,
    required this.semesters,
  });

  final List<Json> teachers;
  final List<Json> assignments;
  final List<Json> classes;
  final List<Json> subjects;
  final List<Json> semesters;
}

/// Một dòng ghép cho một giáo viên.
class _TeacherRow {
  const _TeacherRow({
    required this.name,
    required this.department,
    required this.subjects,
    required this.classNames,
    required this.homeroomNames,
  });

  final String name;
  final String? department;
  final List<String> subjects;
  final List<String> classNames;
  final List<String> homeroomNames;
}

/// QT · Giáo viên & phân công (`ad-teachers`). Chỉ đọc: ghép client-side danh
/// sách giáo viên, phân công và lớp; thêm, sửa, xóa nằm ở màn danh mục.
class TeachingAssignmentsScreen extends ConsumerStatefulWidget {
  const TeachingAssignmentsScreen({super.key});

  @override
  ConsumerState<TeachingAssignmentsScreen> createState() =>
      _TeachingAssignmentsScreenState();
}

class _TeachingAssignmentsScreenState
    extends ConsumerState<TeachingAssignmentsScreen> {
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
      fetchAllCatalogRows(repository, 'teachers'),
      fetchAllCatalogRows(repository, 'assignments'),
      fetchAllCatalogRows(repository, 'classes'),
      fetchAllCatalogRows(repository, 'subjects'),
      fetchAllCatalogRows(repository, 'semesters'),
    ]);
    return _Source(
      teachers: results[0],
      assignments: results[1],
      classes: results[2],
      subjects: results[3],
      semesters: results[4],
    );
  }

  void _reload() => setState(() => _future = _load());

  static String _className(Json? row, num id) =>
      row?['ten_lop']?.toString() ?? 'Lớp $id';

  List<_TeacherRow> _rows(_Source data) {
    final classById = <num, Json>{
      for (final c in data.classes)
        if (c['ma_lop'] is num) c['ma_lop'] as num: c,
    };
    final subjectNameById = <num, String>{
      for (final s in data.subjects)
        if (s['ma_mon'] is num)
          s['ma_mon'] as num: s['ten_mon']?.toString() ?? 'Môn ${s['ma_mon']}',
    };
    int byClass(Json? a, Json? b) {
      final k = ((a?['khoi'] as num?) ?? 0).compareTo(
        (b?['khoi'] as num?) ?? 0,
      );
      if (k != 0) return k;
      return (a?['ten_lop']?.toString() ?? '').compareTo(
        b?['ten_lop']?.toString() ?? '',
      );
    }

    final rows = <_TeacherRow>[];
    for (final teacher in data.teachers) {
      final id = teacher['ma_giao_vien'];
      if (id is! num) continue;
      final mine = data.assignments.where(
        (a) =>
            a['ma_giao_vien'] == id &&
            (_semesterId == null || a['ma_hoc_ky'] == _semesterId),
      );
      final classIds = <num>{
        for (final a in mine)
          if (a['ma_lop'] is num) a['ma_lop'] as num,
      };
      final subjectIds = <num>{
        for (final a in mine)
          if (a['ma_mon'] is num) a['ma_mon'] as num,
      };
      final classOrder = classIds.toList()
        ..sort((a, b) => byClass(classById[a], classById[b]));
      final homeroom =
          data.classes.where((c) => c['ma_gv_chu_nhiem'] == id).toList()
            ..sort(byClass);
      final subjects = [
        for (final s in subjectIds) subjectNameById[s] ?? 'Môn $s',
      ]..sort(VietnameseCollation.compare);
      rows.add(
        _TeacherRow(
          name: teacher['ho_ten']?.toString() ?? teacher['label'].toString(),
          department: teacher['to_chuyen_mon']?.toString(),
          subjects: subjects,
          classNames: [for (final c in classOrder) _className(classById[c], c)],
          homeroomNames: [
            for (final c in homeroom) _className(c, (c['ma_lop'] as num?) ?? 0),
          ],
        ),
      );
    }
    rows.sort(
      (a, b) => VietnameseCollation.compareStudentNames(a.name, b.name),
    );
    return rows;
  }

  Widget _semesterFilter(_Source data) {
    return AppFilterDropdown<num>(
      key: const ValueKey('teaching-semester-filter'),
      label: 'Học kỳ',
      icon: Icons.date_range_outlined,
      value: _semesterId,
      width: 260,
      items: [
        const DropdownMenuItem(value: null, child: Text('Tất cả')),
        for (final s in data.semesters)
          if (s['ma_hoc_ky'] is num)
            DropdownMenuItem(
              value: s['ma_hoc_ky'] as num,
              child: Text(s['label']?.toString() ?? s['ten'].toString()),
            ),
      ],
      onChanged: (value) => setState(() => _semesterId = value),
    );
  }

  Widget _nameCell(BuildContext context, _TeacherRow row) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppAvatar(name: row.name, size: AppAvatarSize.sm),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: t.heading,
                ),
              ),
              if (row.department != null && row.department!.isNotEmpty)
                Text(
                  row.department!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: t.ink3),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chips(List<String> names, BuildContext context) {
    if (names.isEmpty) {
      return Text('—', style: TextStyle(color: context.tokens.ink3));
    }
    return Wrap(
      spacing: AppSpacing.xs + 2,
      runSpacing: AppSpacing.xs + 2,
      children: [for (final n in names) MergedChip(text: n)],
    );
  }

  Widget _homeroom(_TeacherRow row, BuildContext context) {
    if (row.homeroomNames.isEmpty) {
      return Text('—', style: TextStyle(color: context.tokens.ink3));
    }
    return Wrap(
      spacing: AppSpacing.xs + 2,
      runSpacing: AppSpacing.xs + 2,
      children: [
        for (final n in row.homeroomNames) AppBadge.info(n, dot: false),
      ],
    );
  }

  Widget _subjectsText(_TeacherRow row, BuildContext context) => Text(
    row.subjects.isEmpty ? '—' : row.subjects.join(', '),
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: row.subjects.isEmpty ? context.tokens.ink3 : context.tokens.ink,
    ),
  );

  Widget _table(BuildContext context, List<_TeacherRow> rows) {
    final t = context.tokens;
    return MergedTable(
      key: const ValueKey('teaching-table'),
      columns: const [
        MergedColumn('Giáo viên', flex: 3),
        MergedColumn('Môn', flex: 2),
        MergedColumn('Lớp được phân công', flex: 4),
        MergedColumn('Số lớp', width: 72, alignEnd: true),
        MergedColumn('Chủ nhiệm', flex: 2),
        MergedColumn('', width: 120, alignEnd: true),
      ],
      rows: [
        for (final row in rows)
          [
            _nameCell(context, row),
            _subjectsText(row, context),
            _chips(row.classNames, context),
            Text(
              '${row.classNames.length}',
              style: TextStyle(
                color: t.ink,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            _homeroom(row, context),
            TextButton(
              onPressed: () => context.go('/catalog/assignments'),
              child: const Text('Phân công'),
            ),
          ],
      ],
    );
  }

  Widget _card(BuildContext context, _TeacherRow row) {
    final t = context.tokens;
    final theme = Theme.of(context);
    Widget labelled(String label, Widget child) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: t.ink3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
    return MergedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _nameCell(context, row),
          labelled('Môn', _subjectsText(row, context)),
          labelled(
            'Lớp được phân công (${row.classNames.length})',
            _chips(row.classNames, context),
          ),
          labelled('Chủ nhiệm', _homeroom(row, context)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider);
    return AppScaffold(
      title: 'Giáo viên & phân công',
      currentPath: '/admin/teaching-assignments',
      showBackButton: true,
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
                        title: 'Lỗi tải danh sách giáo viên và phân công',
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
    final t = context.tokens;
    final rows = _rows(data);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const MergedViewHeader(
          description:
              'Giáo viên dạy môn nào, ở lớp nào, và ai là giáo viên chủ '
              'nhiệm. Màn này chỉ để xem; thêm, sửa hoặc xóa ở màn quản lý.',
          links: [
            (
              label: 'Quản lý giáo viên',
              icon: Icons.badge_outlined,
              route: '/catalog/teachers',
            ),
            (
              label: 'Quản lý phân công',
              icon: Icons.assignment_ind_outlined,
              route: '/catalog/assignments',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _semesterFilter(data),
            Text(
              '${rows.length} giáo viên',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: t.ink3),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (rows.isEmpty)
          const SizedBox(
            height: 320,
            child: EmptyState(
              icon: Icons.badge_outlined,
              title: 'Chưa có giáo viên',
              message:
                  'Thêm giáo viên ở màn quản lý giáo viên để xem phân công '
                  'tại đây.',
            ),
          )
        else
          LayoutBuilder(
            builder: (context, box) {
              if (box.maxWidth >= 768) return _table(context, rows);
              return Column(
                children: [
                  for (final row in rows) ...[
                    _card(context, row),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}
