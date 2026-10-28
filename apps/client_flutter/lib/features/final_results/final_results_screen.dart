import 'dart:math';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_controls.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/shimmer_loading.dart';
import '../academic_catalog/academic_year_scope.dart';
import '../authentication/session.dart';
import '../gradebooks/gradebook_status.dart';
import '../gradebooks/repository.dart';
import '../reports/reports_panel.dart';
import '../reports/repository.dart';
import 'final_results_panel.dart';

/// GV · Tổng kết & xếp loại (`gv-summary`) dưới dạng trang riêng.
///
/// Hỗ trợ 2 chế độ:
/// 1. Chế độ danh sách: bộ lọc Năm học -> Học kỳ -> Lớp -> Môn + tìm kiếm,
///    bảng chọn bảng điểm gọn gàng (phân trang 20 dòng, mobile thẻ).
/// 2. Chế độ chi tiết: thông tin bảng điểm, thống kê, xuất Excel, tính kết quả,
///    bảng điểm tổng kết phân trang 25 dòng có tìm kiếm, lọc xếp loại, nhóm.
class FinalResultsScreen extends ConsumerStatefulWidget {
  const FinalResultsScreen({super.key});

  @override
  ConsumerState<FinalResultsScreen> createState() => _FinalResultsScreenState();
}

class _FinalResultsScreenState extends ConsumerState<FinalResultsScreen> {
  final GlobalKey<FinalResultsPanelState> _panelKey =
      GlobalKey<FinalResultsPanelState>();
  late Future<List<GradebookDto>> _future;

  GradebookDto? _selectedBook;
  num? _classId;
  num? _subjectId;
  num? _termId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  int _listPage = 0;
  static const int _listPageSize = 20;
  bool _mobileFiltersOpen = false;
  bool _exporting = false;

  bool get teacher => ref.read(sessionProvider)?.role.value == 'GIAO_VIEN';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Đọc đủ mọi trang của `gradebooksRepositoryProvider.list` theo năm đang xem.
  Future<List<GradebookDto>> _load() async {
    final viewingYear = ref.read(viewingYearProvider);
    final yearId = viewingYear?.id;
    final repository = ref.read(gradebooksRepositoryProvider);
    final items = <GradebookDto>[];
    num? cursor;
    final seen = <num>{};
    do {
      final page = await repository.list(cursor: cursor, yearId: yearId);
      items.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor != null && !seen.add(cursor)) {
        throw StateError('Không thể tải tiếp danh sách bảng điểm.');
      }
    } while (cursor != null);
    return items;
  }

  void _reload() {
    setState(() {
      _future = _load();
      _selectedBook = null;
    });
  }

  List<GradebookDto> _filtered(List<GradebookDto> books) {
    final query = _searchQuery.trim().toLowerCase();
    return books.where((b) {
      if (_classId != null && b.classId != _classId) return false;
      if (_subjectId != null && b.subjectId != _subjectId) return false;
      if (_termId != null && b.termId != _termId) return false;
      if (query.isNotEmpty) {
        final match =
            b.className.toLowerCase().contains(query) ||
            b.subjectName.toLowerCase().contains(query) ||
            b.termName.toLowerCase().contains(query);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _exportExcel(GradebookDto book) async {
    setState(() => _exporting = true);
    try {
      final bytes = await ref.read(reportsRepositoryProvider).export(book.id);
      final path = await FilePicker.saveFile(
        dialogTitle: 'Lưu báo cáo Excel',
        fileName: 'tong-ket-${book.className}-${book.subjectName}.xlsx',
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        bytes: bytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'Đã hủy lưu báo cáo.'
                : 'Đã xuất báo cáo Excel thành công.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _listFilters(
    BuildContext context,
    List<GradebookDto> books,
    List<Map<String, dynamic>> years,
    bool isMobile,
  ) {
    final classes = <num, String>{};
    final subjects = <num, String>{};
    final terms = <num, String>{};
    for (final b in books) {
      classes[b.classId] = b.className;
      subjects[b.subjectId] = b.subjectName;
      terms[b.termId] = b.termName;
    }

    final searchField = TextField(
      key: const ValueKey('final-search-input'),
      controller: _searchController,
      onChanged: (v) => setState(() {
        _searchQuery = v;
        _listPage = 0;
      }),
      decoration: InputDecoration(
        hintText: 'Tìm theo lớp, môn, học kỳ...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _listPage = 0;
                  });
                },
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );

    final yearFilter = AcademicYearFilterControl(
      years: years,
      width: isMobile ? double.infinity : 270,
      onChanged: _reload,
    );

    final termDropdown = AppFilterDropdown<num>(
      key: const ValueKey('final-filter-term'),
      label: 'Học kỳ',
      icon: Icons.date_range_outlined,
      value: _termId,
      width: isMobile ? double.infinity : 220,
      items: [
        const DropdownMenuItem(value: null, child: Text('Tất cả')),
        for (final e in terms.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: (v) => setState(() {
        _termId = v;
        _listPage = 0;
      }),
    );

    final classDropdown = AppFilterDropdown<num>(
      key: const ValueKey('final-filter-class'),
      label: 'Lớp học',
      icon: Icons.meeting_room_outlined,
      value: _classId,
      width: isMobile ? double.infinity : 220,
      items: [
        const DropdownMenuItem(value: null, child: Text('Tất cả')),
        for (final e in classes.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: (v) => setState(() {
        _classId = v;
        _listPage = 0;
      }),
    );

    final subjectDropdown = AppFilterDropdown<num>(
      key: const ValueKey('final-filter-subject'),
      label: 'Môn học',
      icon: Icons.menu_book_outlined,
      value: _subjectId,
      width: isMobile ? double.infinity : 220,
      items: [
        const DropdownMenuItem(value: null, child: Text('Tất cả')),
        for (final e in subjects.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: (v) => setState(() {
        _subjectId = v;
        _listPage = 0;
      }),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                key: const ValueKey('final-mobile-filters-toggle'),
                onPressed: () =>
                    setState(() => _mobileFiltersOpen = !_mobileFiltersOpen),
                icon: Icon(
                  _mobileFiltersOpen
                      ? Icons.filter_alt_off
                      : Icons.filter_alt_outlined,
                  size: 18,
                ),
                label: const Text('Bộ lọc'),
              ),
            ],
          ),
          if (_mobileFiltersOpen) ...[
            const SizedBox(height: AppSpacing.md),
            yearFilter,
            const SizedBox(height: AppSpacing.sm),
            termDropdown,
            const SizedBox(height: AppSpacing.sm),
            classDropdown,
            const SizedBox(height: AppSpacing.sm),
            subjectDropdown,
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [yearFilter, termDropdown, classDropdown, subjectDropdown],
        ),
        const SizedBox(height: AppSpacing.md),
        searchField,
      ],
    );
  }

  Widget _gradebookListTable(
    BuildContext context,
    List<GradebookDto> pagedBooks,
    bool isMobile,
  ) {
    final t = context.tokens;

    if (isMobile) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: pagedBooks.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, index) {
          final b = pagedBooks[index];
          return Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              onTap: () => setState(() => _selectedBook = b),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${b.className} · ${b.subjectName}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: t.heading,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            b.termName,
                            style: TextStyle(color: t.ink2, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          GradebookStatusBadge(b.status.value),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      key: ValueKey('view-gradebook-${b.id}'),
                      onPressed: () => setState(() => _selectedBook = b),
                      child: const Text('Xem'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const totalColumns = 5;
            final hMargin = constraints.maxWidth >= 768
                ? AppSpacing.xl
                : AppSpacing.md;
            const colSpacing = 16.0;
            final availableTotalWidth =
                constraints.maxWidth -
                (hMargin * 2) -
                ((totalColumns - 1) * colSpacing);

            const minLop = 80.0;
            const minMon = 140.0;
            const minHk = 100.0;
            const minStatus = 120.0;
            const minAction = 76.0;
            const minRequired = minLop + minMon + minHk + minStatus + minAction;

            final double colLop;
            final double colMon;
            final double colHk;
            final double colStatus;
            final double colAction;

            if (availableTotalWidth > minRequired) {
              final extra = availableTotalWidth - minRequired;
              colLop = minLop + extra * 0.15;
              colMon = minMon + extra * 0.35;
              colHk = minHk + extra * 0.20;
              colStatus = minStatus + extra * 0.20;
              colAction = minAction + extra * 0.10;
            } else {
              colLop = minLop;
              colMon = minMon;
              colHk = minHk;
              colStatus = minStatus;
              colAction = minAction;
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  showCheckboxColumn: false,
                  columnSpacing: colSpacing,
                  horizontalMargin: hMargin,
                  columns: [
                    DataColumn(
                      label: SizedBox(width: colLop, child: const Text('Lớp')),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: colMon,
                        child: const Text('Môn học'),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: colHk,
                        child: const Text('Học kỳ'),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: colStatus,
                        child: const Text('Trạng thái'),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: colAction,
                        child: const Align(
                          alignment: Alignment.centerRight,
                          child: Text('Thao tác'),
                        ),
                      ),
                    ),
                  ],
                  rows: [
                    for (final b in pagedBooks)
                      DataRow(
                        onSelectChanged: (_) =>
                            setState(() => _selectedBook = b),
                        cells: [
                          DataCell(
                            SizedBox(
                              width: colLop,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  b.className,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: t.ink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: colMon,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  b.subjectName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: colHk,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(b.termName),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: colStatus,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: GradebookStatusBadge(b.status.value),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: colAction,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.tonal(
                                  key: ValueKey('view-gradebook-${b.id}'),
                                  onPressed: () =>
                                      setState(() => _selectedBook = b),
                                  child: const Text('Xem'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _listPagination(BuildContext context, int totalItems) {
    final t = context.tokens;
    final totalPages = max(1, (totalItems / _listPageSize).ceil());
    final start = totalItems == 0 ? 0 : _listPage * _listPageSize + 1;
    final end = min((_listPage + 1) * _listPageSize, totalItems);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hiển thị $start–$end / $totalItems bảng điểm',
            style: TextStyle(color: t.ink3, fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Trang trước',
                onPressed: _listPage > 0
                    ? () => setState(() => _listPage--)
                    : null,
              ),
              Text(
                'Trang ${_listPage + 1} / $totalPages',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                  fontSize: 13,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Trang sau',
                onPressed: _listPage < totalPages - 1
                    ? () => setState(() => _listPage++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailHeader(BuildContext context, GradebookDto book) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const ValueKey('back-to-gradebook-list'),
            onPressed: () => setState(() => _selectedBook = null),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('← Danh sách bảng điểm'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${book.className} – ${book.subjectName} – ${book.termName}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: t.heading,
                  ),
                ),
                GradebookStatusBadge(book.status.value),
              ],
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (teacher)
                  FilledButton.icon(
                    key: const ValueKey('calculate-final-results'),
                    onPressed: () {
                      _panelKey.currentState?.calculate();
                    },
                    icon: const Icon(Icons.functions, size: 18),
                    label: const Text('Tính kết quả'),
                  ),
                FilledButton.tonalIcon(
                  key: const ValueKey('export-xlsx'),
                  onPressed: _exporting ? null : () => _exportExcel(book),
                  icon: _exporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Xuất Excel'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _detailView(BuildContext context, GradebookDto book) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _detailHeader(context, book),
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
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: t.line),
          ),
          child: FinalResultsPanel(
            key: _panelKey,
            gradebookId: book.id,
            gradebookVersion: book.version,
            resultsOutdated: book.resultsOutdated,
            showResults: true,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider);
    final yearsAsync = ref.watch(academicYearsProvider);
    final years = yearsAsync.valueOrNull ?? const [];
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    // Lắng nghe thay đổi năm học để làm mới danh sách bảng điểm
    ref.listen<ViewingYear?>(viewingYearProvider, (prev, next) {
      if (prev?.id != next?.id) {
        _reload();
      }
    });

    return AppScaffold(
      title: 'Tổng kết & xếp loại',
      currentPath: '/final-results',
      showBackButton: true,
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

                    if (_selectedBook != null) {
                      return ListView(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        children: [_detailView(context, _selectedBook!)],
                      );
                    }

                    // Chế độ danh sách
                    final filtered = _filtered(books);
                    final totalPages = max(
                      1,
                      (filtered.length / _listPageSize).ceil(),
                    );
                    if (_listPage >= totalPages) _listPage = totalPages - 1;
                    if (_listPage < 0) _listPage = 0;

                    final pagedBooks = filtered
                        .skip(_listPage * _listPageSize)
                        .take(_listPageSize)
                        .toList();

                    return ListView(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      children: [
                        _listFilters(context, books, years, isMobile),
                        const SizedBox(height: AppSpacing.lg),
                        if (filtered.isEmpty)
                          const SizedBox(
                            height: 240,
                            child: EmptyState(
                              icon: Icons.search_off_outlined,
                              title: 'Không tìm thấy bảng điểm',
                              message:
                                  'Không có bảng điểm nào khớp với bộ lọc hoặc từ khóa tìm kiếm.',
                            ),
                          )
                        else ...[
                          _gradebookListTable(context, pagedBooks, isMobile),
                          if (filtered.length > _listPageSize)
                            _listPagination(context, filtered.length),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }
}
