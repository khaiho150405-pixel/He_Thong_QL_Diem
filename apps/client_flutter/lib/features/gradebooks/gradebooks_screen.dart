import '../../app/design_tokens.dart';
import '../../app/widgets/app_controls.dart';
import '../../app/widgets/app_list_footer.dart';
import '../../app/widgets/app_scaffold.dart';
import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/shimmer_loading.dart';
import '../../core/progressive_loader.dart';
import '../../core/text_search.dart';
import '../academic_catalog/academic_year_scope.dart';
import '../academic_catalog/repository.dart';
import '../authentication/session.dart';
import 'gradebook_status.dart';
import 'repository.dart';

class GradebooksScreen extends ConsumerStatefulWidget {
  const GradebooksScreen({super.key});

  @override
  ConsumerState<GradebooksScreen> createState() => _GradebooksScreenState();
}

class _GradebooksScreenState extends ConsumerState<GradebooksScreen> {
  late Future<GradebookListDto> page;
  int _pageIndex = 1;
  int _pageSize = appDefaultPageSize;
  late final ProgressiveLoader<GradebookDto, num> _loader = ProgressiveLoader(
    onChanged: () {
      if (mounted) setState(() {});
    },
  );

  List<Json> _years = [];
  List<Json> _classes = [];
  List<Json> _subjects = [];
  bool _loadingCatalog = false;

  num? _filterClassId;
  num? _filterSubjectId;
  String? _filterStatus; // null | 'DANG_NHAP_LIEU' | 'DA_CHOT'
  String _searchQuery = '';
  final _searchController = TextEditingController();

  bool get teacher => ref.read(sessionProvider)?.role.value == 'GIAO_VIEN';
  bool get _hasFilter =>
      _filterClassId != null ||
      _filterSubjectId != null ||
      _filterStatus != null ||
      _searchQuery.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    reload();
  }

  @override
  void dispose() {
    _loader.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() => _loadingCatalog = true);
    try {
      final years = await _allCatalogItems('years').catchError((_) => <Json>[]);
      final classes = await _allCatalogItems(
        'classes',
      ).catchError((_) => <Json>[]);
      final subjects = await _allCatalogItems(
        'subjects',
      ).catchError((_) => <Json>[]);
      if (!mounted) return;
      setState(() {
        _years = years;
        _classes = classes;
        _subjects = subjects;
        _loadingCatalog = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCatalog = false);
    }
  }

  Future<List<Json>> _allCatalogItems(String resource) async {
    String? cursor;
    final items = <Json>[];
    final seen = <String>{};
    do {
      final res = await ref
          .read(catalogRepositoryProvider)
          .list(resource, cursor: cursor);
      items.addAll(res.items);
      cursor = res.nextCursor;
      if (cursor != null && !seen.add(cursor)) break;
    } while (cursor != null);
    return items;
  }

  void reload() {
    page = _loadPage();
  }

  Future<GradebookListDto> _loadPage() async {
    var viewingYear = ref.read(viewingYearProvider);
    if (viewingYear == null) {
      viewingYear = await ref.read(currentYearProvider.future);
      if (viewingYear != null &&
          mounted &&
          ref.read(viewingYearProvider) == null) {
        ref.read(viewingYearProvider.notifier).setYear(viewingYear);
      }
    }
    final yearId = viewingYear?.id;
    final key = 'books|$yearId';
    if (_loader.key == key) {
      return GradebookListDto(items: _loader.items, nextCursor: null);
    }
    // Trang đầu hiện ngay; các trang còn lại tải dưới nền.
    await _loader.start(key, (cursor) async {
      final result = await ref
          .read(gradebooksRepositoryProvider)
          .list(cursor: cursor, yearId: yearId);
      return LoadedChunk(result.items, result.nextCursor);
    });
    return GradebookListDto(items: _loader.items, nextCursor: null);
  }

  void _clearFilters() => setState(() {
    _searchController.clear();
    _searchQuery = '';
    _filterClassId = null;
    _filterSubjectId = null;
    _filterStatus = null;
  });

  bool _mobileFiltersOpen = false;

  int get _activeFilterCount {
    int count = 0;
    if (_filterClassId != null) count++;
    if (_filterSubjectId != null) count++;
    if (_filterStatus != null) count++;
    return count;
  }

  Widget _buildFilterBar(BuildContext context) {
    final t = context.tokens;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    if (_loadingCatalog) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }

    final searchBar = SizedBox(
      height: 44,
      child: TextField(
        key: const ValueKey('gradebooks-search-input'),
        controller: _searchController,
        onChanged: (val) => setState(() {
          _searchQuery = val.trim();
          _pageIndex = 1;
        }),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: t.ink,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: t.surface,
          hintText: 'Tìm kiếm theo lớp, môn học, học kỳ…',
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: t.ink3,
          ),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: t.ink3),
          suffixIcon: _searchQuery.isNotEmpty
              ? Tooltip(
                  message: 'Xóa tìm kiếm',
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: t.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: t.pri, width: 1.5),
          ),
        ),
      ),
    );

    final yearControl = AcademicYearFilterControl(
      years: _years,
      width: isMobile ? double.infinity : 270,
      onChanged: () {
        _pageIndex = 1;
        setState(reload);
      },
    );

    final statusControl = AppFilterDropdown<String>(
      label: 'Trạng thái',
      icon: Icons.tune_rounded,
      value: _filterStatus,
      width: isMobile ? double.infinity : 220,
      items: const [
        DropdownMenuItem(value: null, child: Text('Tất cả')),
        DropdownMenuItem(
          value: 'DANG_NHAP_LIEU',
          child: Text('Đang nhập liệu'),
        ),
        DropdownMenuItem(value: 'DA_CHOT', child: Text('Đã khóa')),
      ],
      onChanged: (val) => setState(() {
        _filterStatus = val;
        _pageIndex = 1;
      }),
    );

    final classControl = AppFilterDropdown<num>(
      label: 'Lớp học',
      icon: Icons.meeting_room_outlined,
      value: _filterClassId,
      width: isMobile ? double.infinity : 220,
      items: [
        const DropdownMenuItem(value: null, child: Text('Tất cả')),
        for (final c in _classes)
          DropdownMenuItem(
            value: c['ma_lop'] as num?,
            child: Text(c['ten_lop']?.toString() ?? 'Lớp ${c['ma_lop']}'),
          ),
      ],
      onChanged: (val) => setState(() {
        _filterClassId = val;
        _pageIndex = 1;
      }),
    );

    final subjectControl = AppFilterDropdown<num>(
      label: 'Môn học',
      icon: Icons.menu_book_outlined,
      value: _filterSubjectId,
      width: isMobile ? double.infinity : 220,
      items: [
        const DropdownMenuItem(value: null, child: Text('Tất cả')),
        for (final s in _subjects)
          DropdownMenuItem(
            value: s['ma_mon'] as num?,
            child: Text(s['ten_mon']?.toString() ?? 'Môn ${s['ma_mon']}'),
          ),
      ],
      onChanged: (val) => setState(() {
        _filterSubjectId = val;
        _pageIndex = 1;
      }),
    );

    final resetButton = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        ),
      ),
      icon: const Icon(Icons.clear_all_rounded, size: 18),
      label: const Text('Đặt lại'),
      onPressed: _clearFilters,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: searchBar),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const ValueKey('gradebooks-mobile-filters-toggle'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                  ),
                ),
                onPressed: () =>
                    setState(() => _mobileFiltersOpen = !_mobileFiltersOpen),
                icon: Badge(
                  isLabelVisible: _activeFilterCount > 0,
                  label: Text('$_activeFilterCount'),
                  child: Icon(
                    _mobileFiltersOpen
                        ? Icons.filter_alt_off_rounded
                        : Icons.filter_alt_rounded,
                    size: 18,
                  ),
                ),
                label: Text(_mobileFiltersOpen ? 'Đóng' : 'Bộ lọc'),
              ),
            ],
          ),
          if (_mobileFiltersOpen) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: t.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  yearControl,
                  const SizedBox(height: 10),
                  statusControl,
                  const SizedBox(height: 10),
                  classControl,
                  const SizedBox(height: 10),
                  subjectControl,
                  if (_hasFilter) ...[const SizedBox(height: 12), resetButton],
                ],
              ),
            ),
          ] else if (_hasFilter) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_filterStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text(
                          _filterStatus == 'DANG_NHAP_LIEU'
                              ? 'Đang nhập'
                              : 'Đã khóa',
                        ),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => setState(() => _filterStatus = null),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  if (_filterClassId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text('Lớp: $_filterClassId'),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => setState(() => _filterClassId = null),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  if (_filterSubjectId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text('Môn: $_filterSubjectId'),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () =>
                            setState(() => _filterSubjectId = null),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  TextButton(
                    onPressed: _clearFilters,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Xóa lọc',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchBar,
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            yearControl,
            statusControl,
            classControl,
            subjectControl,
            if (_hasFilter) resetButton,
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return AppScaffold(
      title: teacher ? 'Bảng điểm' : 'Bảng điểm toàn trường',
      currentPath: '/gradebooks',
      showBackButton: true,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFilterBar(context),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<GradebookListDto>(
                    future: page,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const ShimmerLoading(
                          itemCount: 5,
                          itemHeight: 84,
                        );
                      }
                      if (snapshot.hasError) {
                        return EmptyState(
                          icon: Icons.error_outline,
                          title: 'Lỗi tải danh sách bảng điểm',
                          message: errorMessage(snapshot.error!),
                          actionLabel: 'Thử lại',
                          onAction: () => setState(reload),
                        );
                      }
                      final allItems = _loader.items;

                      if (allItems.isEmpty) {
                        return EmptyState(
                          icon: Icons.table_chart_outlined,
                          title: 'Chưa có bảng điểm',
                          message: teacher
                              ? 'Bảng điểm được tạo tự động khi bạn được phân công lớp và môn. Hãy liên hệ quản trị viên nếu bạn chưa có phân công.'
                              : 'Hệ thống chưa có bảng điểm nào được tạo.',
                        );
                      }

                      final filteredItems = allItems.where((book) {
                        if (_filterClassId != null &&
                            book.classId != _filterClassId) {
                          return false;
                        }
                        if (_filterSubjectId != null &&
                            book.subjectId != _filterSubjectId) {
                          return false;
                        }
                        if (_filterStatus != null &&
                            book.status.value != _filterStatus) {
                          return false;
                        }
                        if (!matchesSearch(_searchQuery, [
                          book.className,
                          book.subjectName,
                          book.termName,
                        ])) {
                          return false;
                        }
                        return true;
                      }).toList();

                      if (filteredItems.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_alt_off_rounded,
                                size: 48,
                                color: t.ink3,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Không có bảng điểm phù hợp với bộ lọc.',
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _clearFilters,
                                icon: const Icon(Icons.clear_all_rounded),
                                label: const Text('Xóa bộ lọc'),
                              ),
                            ],
                          ),
                        );
                      }

                      final pageCount = appPageCount(
                        filteredItems.length,
                        _pageSize,
                      );
                      final currentPage = _pageIndex.clamp(1, pageCount);
                      final pageItems = pageSlice(
                        filteredItems,
                        currentPage,
                        _pageSize,
                      );

                      return Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, box) {
                                if (box.maxWidth >= 768) {
                                  return _buildTable(context, pageItems);
                                }
                                return ListView.separated(
                                  itemCount: pageItems.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) =>
                                      _buildGradebookCard(
                                        context,
                                        pageItems[index],
                                      ),
                                );
                              },
                            ),
                          ),
                          AppListFooter(
                            total: filteredItems.length,
                            page: currentPage,
                            pageSize: _pageSize,
                            loadingMore: _loader.loadingMore,
                            itemLabel: 'bảng điểm',
                            onPageChanged: (p) =>
                                setState(() => _pageIndex = p),
                            onPageSizeChanged: (size) => setState(() {
                              _pageSize = size;
                              _pageIndex = 1;
                            }),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<GradebookDto> items) {
    final t = context.tokens;
    final radius = BorderRadius.circular(AppRadius.md);

    return DecoratedBox(
      key: const ValueKey('gradebooks-table'),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: radius,
        border: Border.all(color: t.line),
      ),
      child: ClipRRect(
        borderRadius: radius,
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

            const minLop = 76.0;
            const minMon = 130.0;
            const minHk = 96.0;
            const minStatus = 120.0;
            const minAction = 86.0;
            const minRequired = minLop + minMon + minHk + minStatus + minAction;

            final double colLop;
            final double colMon;
            final double colHk;
            final double colStatus;
            final double colAction;

            if (availableTotalWidth > minRequired) {
              final extra = availableTotalWidth - minRequired;
              colLop = minLop + extra * 0.12;
              colMon = minMon + extra * 0.30;
              colHk = minHk + extra * 0.18;
              colStatus = minStatus + extra * 0.18;
              colAction = minAction + extra * 0.12;
            } else {
              colLop = minLop;
              colMon = minMon;
              colHk = minHk;
              colStatus = minStatus;
              colAction = minAction;
            }

            // Cuộn dọc khi nhiều dòng, cuộn ngang khi bảng rộng hơn khung.
            return SingleChildScrollView(
              key: const ValueKey('gradebooks-table-vertical-scroll'),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    showCheckboxColumn: false,
                    columnSpacing: colSpacing,
                    horizontalMargin: hMargin,
                    columns: [
                      DataColumn(
                        label: SizedBox(
                          width: colLop,
                          child: const Text('LỚP'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: colMon,
                          child: const Text('MÔN HỌC'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: colHk,
                          child: const Text('HỌC KỲ'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: colStatus,
                          child: const Text('TRẠNG THÁI'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: colAction,
                          child: const Align(
                            alignment: Alignment.centerRight,
                            child: Text('THAO TÁC'),
                          ),
                        ),
                      ),
                    ],
                    rows: [
                      for (final b in items)
                        DataRow(
                          onSelectChanged: (_) =>
                              context.go('/gradebooks/${b.id}'),
                          cells: [
                            DataCell(
                              SizedBox(
                                width: colLop,
                                child: Text(
                                  b.className,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: t.ink,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: colMon,
                                child: Text(
                                  b.subjectName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: t.ink),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: colHk,
                                child: Text(
                                  b.termName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: t.ink2),
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
                                        context.go('/gradebooks/${b.id}'),
                                    child: Text(
                                      (teacher && b.status.value != 'DA_CHOT')
                                          ? 'Nhập điểm'
                                          : 'Xem',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGradebookCard(BuildContext context, GradebookDto b) {
    final t = context.tokens;
    final locked = b.status.value == 'DA_CHOT';
    final canEnter = teacher && !locked;
    void open() => context.go('/gradebooks/${b.id}');

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: open,
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
                        fontSize: 15,
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
              const SizedBox(width: AppSpacing.sm),
              FilledButton.tonal(
                key: ValueKey('view-gradebook-${b.id}'),
                onPressed: open,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(canEnter ? 'Nhập điểm' : 'Xem'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
