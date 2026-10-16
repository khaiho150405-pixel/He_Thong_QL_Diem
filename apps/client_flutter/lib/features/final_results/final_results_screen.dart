import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_controls.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/shimmer_loading.dart';
import '../authentication/session.dart';
import '../gradebooks/gradebook_status.dart';
import '../gradebooks/repository.dart';
import '../reports/reports_panel.dart';
import 'final_results_panel.dart';

/// GV · Tổng kết & xếp loại (`gv-summary`) dưới dạng trang riêng.
///
/// Một bảng điểm là lớp + môn + học kỳ nên trang cho chọn bảng điểm (lọc
/// client-side theo lớp, môn, học kỳ) rồi nhúng nguyên [ReportsPanel] (thống
/// kê, xuất Excel) và [FinalResultsPanel] (kết quả, tính, lịch sử). Trang chỉ
/// hiện các trường backend có: điểm tổng kết, xếp loại, phiên bản hệ số,
/// phiên bản chính sách, thời điểm tính. Hộp thoại "Tổng kết" trong màn bảng
/// điểm vẫn giữ nguyên.
class FinalResultsScreen extends ConsumerStatefulWidget {
  const FinalResultsScreen({super.key});

  @override
  ConsumerState<FinalResultsScreen> createState() => _FinalResultsScreenState();
}

class _FinalResultsScreenState extends ConsumerState<FinalResultsScreen> {
  late Future<List<GradebookDto>> _future;
  num? _classId;
  num? _subjectId;
  num? _termId;
  num? _bookId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Đọc đủ mọi trang của `gradebooksRepositoryProvider.list`.
  Future<List<GradebookDto>> _load() async {
    final repository = ref.read(gradebooksRepositoryProvider);
    final items = <GradebookDto>[];
    num? cursor;
    final seen = <num>{};
    do {
      final page = await repository.list(cursor: cursor);
      items.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor != null && !seen.add(cursor)) {
        throw StateError('Không thể tải tiếp danh sách bảng điểm.');
      }
    } while (cursor != null);
    return items;
  }

  void _reload() => setState(() => _future = _load());

  static String _bookLabel(GradebookDto b) =>
      '${b.className} · ${b.subjectName} · ${b.termName}';

  List<GradebookDto> _filtered(List<GradebookDto> books) => [
    for (final b in books)
      if ((_classId == null || b.classId == _classId) &&
          (_subjectId == null || b.subjectId == _subjectId) &&
          (_termId == null || b.termId == _termId))
        b,
  ];

  /// Bảng điểm đang chọn; chỉ có đúng một bảng khớp bộ lọc thì tự chọn.
  GradebookDto? _selected(List<GradebookDto> filtered) {
    if (_bookId != null) {
      for (final b in filtered) {
        if (b.id == _bookId) return b;
      }
    }
    return filtered.length == 1 ? filtered.first : null;
  }

  Widget _filterBar(BuildContext context, List<GradebookDto> books) {
    final classes = <num, String>{};
    final subjects = <num, String>{};
    final terms = <num, String>{};
    for (final b in books) {
      classes[b.classId] = b.className;
      subjects[b.subjectId] = b.subjectName;
      terms[b.termId] = b.termName;
    }
    final filtered = _filtered(books);
    final selected = _selected(filtered);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            AppFilterDropdown<num>(
              key: const ValueKey('final-filter-class'),
              label: 'Lớp học',
              icon: Icons.meeting_room_outlined,
              value: _classId,
              width: 170,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Tất cả các lớp'),
                ),
                for (final e in classes.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _classId = v),
            ),
            AppFilterDropdown<num>(
              key: const ValueKey('final-filter-subject'),
              label: 'Môn học',
              icon: Icons.menu_book_outlined,
              value: _subjectId,
              width: 180,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Tất cả môn học'),
                ),
                for (final e in subjects.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _subjectId = v),
            ),
            AppFilterDropdown<num>(
              key: const ValueKey('final-filter-term'),
              label: 'Học kỳ',
              icon: Icons.date_range_outlined,
              value: _termId,
              width: 220,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Tất cả học kỳ'),
                ),
                for (final e in terms.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _termId = v),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppFilterDropdown<num>(
          key: const ValueKey('final-book-select'),
          label: 'Bảng điểm (Lớp · Môn · Học kỳ)',
          icon: Icons.table_chart_outlined,
          value: selected?.id,
          width: double.infinity,
          items: [
            for (final b in filtered)
              DropdownMenuItem(value: b.id, child: Text(_bookLabel(b))),
          ],
          onChanged: (v) => setState(() => _bookId = v),
        ),
      ],
    );
  }

  Widget _selectedHeader(BuildContext context, GradebookDto book) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${book.className} · ${book.subjectName}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: t.heading,
          ),
        ),
        Text(
          book.termName,
          style: theme.textTheme.bodyMedium?.copyWith(color: t.ink2),
        ),
        GradebookStatusBadge(book.status.value),
      ],
    );
  }

  Widget _results(BuildContext context, GradebookDto book) {
    final t = context.tokens;
    final radius = BorderRadius.circular(AppRadius.md);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _selectedHeader(context, book),
        const SizedBox(height: AppSpacing.lg),
        ReportsPanel(
          key: ValueKey('final-page-reports-${book.id}'),
          gradebookId: book.id,
          compact: false,
        ),
        const SizedBox(height: AppSpacing.lg),
        DecoratedBox(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: radius,
            border: Border.all(color: t.line),
          ),
          child: FinalResultsPanel(
            key: ValueKey('final-page-results-${book.id}-${book.version}'),
            gradebookId: book.id,
            gradebookVersion: book.version,
            showResults: true,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider);
    return AppScaffold(
      title: 'Tổng kết & xếp loại',
      currentPath: '/final-results',
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
                child: FutureBuilder<List<GradebookDto>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: ShimmerLoading(itemCount: 3, itemHeight: 72),
                      );
                    }
                    if (snapshot.hasError) {
                      return EmptyState(
                        icon: Icons.error_outline,
                        title: 'Lỗi tải danh sách bảng điểm',
                        message: errorMessage(snapshot.error!),
                        actionLabel: 'Thử lại',
                        onAction: _reload,
                      );
                    }
                    final books = snapshot.data!;
                    if (books.isEmpty) {
                      return const EmptyState(
                        icon: Icons.table_chart_outlined,
                        title: 'Chưa có bảng điểm',
                        message:
                            'Chưa có bảng điểm nào để xem tổng kết và xếp loại.',
                      );
                    }
                    final selected = _selected(_filtered(books));
                    return ListView(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      children: [
                        _filterBar(context, books),
                        const SizedBox(height: AppSpacing.xl),
                        if (selected == null)
                          const SizedBox(
                            height: 280,
                            child: EmptyState(
                              icon: Icons.workspace_premium_outlined,
                              title: 'Chọn một bảng điểm',
                              message:
                                  'Chọn bảng điểm theo lớp, môn và học kỳ để '
                                  'xem kết quả tổng kết và xếp loại.',
                            ),
                          )
                        else
                          _results(context, selected),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }
}
