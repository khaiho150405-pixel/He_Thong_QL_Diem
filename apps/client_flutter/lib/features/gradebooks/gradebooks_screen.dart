import '../../app/design_tokens.dart';
import '../../app/widgets/app_controls.dart';
import '../../app/widgets/app_dialog.dart';
import '../../app/widgets/app_scaffold.dart';
import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/shimmer_loading.dart';
import '../academic_catalog/academic_year_scope.dart';
import '../academic_catalog/fields.dart';
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
  final cursors = <num?>[null];

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
    if (teacher) {
      return ref
          .read(gradebooksRepositoryProvider)
          .list(cursor: cursors.last, yearId: yearId);
    }
    return _allBooks(yearId: yearId);
  }

  Future<GradebookListDto> _allBooks({num? yearId}) async {
    num? cursor;
    final items = <GradebookDto>[];
    final seen = <num>{};
    do {
      final result = await ref
          .read(gradebooksRepositoryProvider)
          .list(cursor: cursor, yearId: yearId);
      items.addAll(result.items);
      cursor = result.nextCursor;
      if (cursor != null && !seen.add(cursor)) {
        throw StateError('Không thể tải tiếp danh sách bảng điểm.');
      }
    } while (cursor != null);
    return GradebookListDto(items: items, nextCursor: null);
  }

  Future<void> create() async {
    if (!teacher) return;
    final book = await showDialog<GradebookDto>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CreateGradebookDialog(),
    );
    if (book != null && mounted) context.go('/gradebooks/${book.id}');
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
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        cursors.clear();
        cursors.add(null);
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
      onChanged: (val) => setState(() => _filterStatus = val),
    );

    final classControl = AppFilterDropdown<num>(
      label: 'Lớp học',
      icon: Icons.meeting_room_outlined,
      value: _filterClassId,
      width: isMobile ? double.infinity : 220,
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Tất cả'),
        ),
        for (final c in _classes)
          DropdownMenuItem(
            value: c['ma_lop'] as num?,
            child: Text(
              c['ten_lop']?.toString() ?? 'Lớp ${c['ma_lop']}',
            ),
          ),
      ],
      onChanged: (val) => setState(() => _filterClassId = val),
    );

    final subjectControl = AppFilterDropdown<num>(
      label: 'Môn học',
      icon: Icons.menu_book_outlined,
      value: _filterSubjectId,
      width: isMobile ? double.infinity : 220,
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Tất cả'),
        ),
        for (final s in _subjects)
          DropdownMenuItem(
            value: s['ma_mon'] as num?,
            child: Text(
              s['ten_mon']?.toString() ?? 'Môn ${s['ma_mon']}',
            ),
          ),
      ],
      onChanged: (val) => setState(() => _filterSubjectId = val),
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
                  if (_hasFilter) ...[
                    const SizedBox(height: 12),
                    resetButton,
                  ],
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
                        label: Text(_filterStatus == 'DANG_NHAP_LIEU' ? 'Đang nhập' : 'Đã khóa'),
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
                        onDeleted: () => setState(() => _filterSubjectId = null),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  TextButton(
                    onPressed: _clearFilters,
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Text('Xóa lọc', style: TextStyle(fontSize: 12)),
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
      floatingActionButton: teacher
          ? FloatingActionButton.extended(
              onPressed: create,
              icon: const Icon(Icons.add),
              label: const Text('Tạo bảng điểm'),
            )
          : null,
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
                      final data = snapshot.data!;

                      if (data.items.isEmpty) {
                        return EmptyState(
                          icon: Icons.table_chart_outlined,
                          title: 'Chưa có bảng điểm',
                          message: teacher
                              ? 'Bạn chưa tạo bảng điểm nào cho các lớp phụ trách.'
                              : 'Hệ thống chưa có bảng điểm nào được tạo.',
                          actionLabel: teacher ? 'Tạo bảng điểm' : null,
                          onAction: teacher ? create : null,
                        );
                      }

                      final filteredItems = data.items.where((book) {
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
                        if (_searchQuery.isNotEmpty) {
                          final q = _searchQuery.toLowerCase();
                          final matchClass = book.className
                              .toLowerCase()
                              .contains(q);
                          final matchSubject = book.subjectName
                              .toLowerCase()
                              .contains(q);
                          final matchTerm = book.termName
                              .toLowerCase()
                              .contains(q);
                          if (!matchClass && !matchSubject && !matchTerm) {
                            return false;
                          }
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

                      return Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, box) {
                                if (box.maxWidth >= 768) {
                                  return _buildTable(context, filteredItems);
                                }
                                return ListView.separated(
                                  itemCount: filteredItems.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) =>
                                      _buildGradebookCard(
                                        context,
                                        filteredItems[index],
                                      ),
                                );
                              },
                            ),
                          ),

                          // Pagination
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              children: [
                                Text(
                                  'Hiển thị ${filteredItems.length} bảng điểm',
                                  style: TextStyle(color: t.ink3, fontSize: 13),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Trang trước',
                                      onPressed: cursors.length > 1
                                          ? () => setState(() {
                                              cursors.removeLast();
                                              reload();
                                            })
                                          : null,
                                      icon: const Icon(Icons.chevron_left),
                                    ),
                                    Text(
                                      'Trang ${cursors.length}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: t.ink,
                                        fontSize: 13,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Trang sau',
                                      onPressed: data.nextCursor == null
                                          ? null
                                          : () => setState(() {
                                              cursors.add(data.nextCursor);
                                              reload();
                                            }),
                                      icon: const Icon(Icons.chevron_right),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
            const totalColumns = 6;
            final hMargin = constraints.maxWidth >= 768 ? AppSpacing.xl : AppSpacing.md;
            const colSpacing = 16.0;
            final availableTotalWidth =
                constraints.maxWidth - (hMargin * 2) - ((totalColumns - 1) * colSpacing);

            const minLop = 76.0;
            const minMon = 130.0;
            const minHk = 96.0;
            const minVersion = 70.0;
            const minStatus = 120.0;
            const minAction = 86.0;
            const minRequired = minLop + minMon + minHk + minVersion + minStatus + minAction;

            final double colLop;
            final double colMon;
            final double colHk;
            final double colVersion;
            final double colStatus;
            final double colAction;

            if (availableTotalWidth > minRequired) {
              final extra = availableTotalWidth - minRequired;
              colLop = minLop + extra * 0.12;
              colMon = minMon + extra * 0.30;
              colHk = minHk + extra * 0.18;
              colVersion = minVersion + extra * 0.10;
              colStatus = minStatus + extra * 0.18;
              colAction = minAction + extra * 0.12;
            } else {
              colLop = minLop;
              colMon = minMon;
              colHk = minHk;
              colVersion = minVersion;
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
                    DataColumn(label: SizedBox(width: colLop, child: const Text('LỚP'))),
                    DataColumn(label: SizedBox(width: colMon, child: const Text('MÔN HỌC'))),
                    DataColumn(label: SizedBox(width: colHk, child: const Text('HỌC KỲ'))),
                    DataColumn(label: SizedBox(width: colVersion, child: const Text('PHIÊN BẢN'))),
                    DataColumn(label: SizedBox(width: colStatus, child: const Text('TRẠNG THÁI'))),
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
                        onSelectChanged: (_) => context.go('/gradebooks/${b.id}'),
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
                              width: colVersion,
                              child: Text(
                                'v${b.version}',
                                style: TextStyle(color: t.ink3, fontSize: 13),
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
                                  onPressed: () => context.go('/gradebooks/${b.id}'),
                                  child: Text((teacher && b.status.value != 'DA_CHOT') ? 'Nhập điểm' : 'Xem'),
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
                      '${b.termName} · v${b.version}',
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

class CreateGradebookDialog extends ConsumerStatefulWidget {
  const CreateGradebookDialog({super.key});

  @override
  ConsumerState<CreateGradebookDialog> createState() =>
      _CreateGradebookDialogState();
}

class _CreateGradebookDialogState extends ConsumerState<CreateGradebookDialog> {
  late Future<List<List<Json>>> options;
  num? classId;
  num? subjectId;
  num? termId;
  bool busy = false;
  String? error;
  bool _initializedDefaults = false;

  List<Json> _allClasses = [];
  List<Json> _allSubjects = [];
  List<Json> _allSemesters = [];
  List<Json> _assignments = [];

  @override
  void initState() {
    super.initState();
    options = _loadOptions();
  }

  Future<List<List<Json>>> _loadOptions() async {
    final viewingYear = ref.read(viewingYearProvider);
    final yId = viewingYear?.id;

    final results = await Future.wait([
      _allCatalogItems('classes'),
      _allCatalogItems('subjects'),
      _allCatalogItems('semesters'),
      _allCatalogItems('assignments', yearId: yId),
    ]);

    _allClasses = results[0];
    _allSubjects = results[1];
    _allSemesters = results[2];
    _assignments = results[3];

    if (yId != null) {
      int compareWithYear(Json a, Json b) {
        final aMatch = a['ma_nam_hoc'] == yId ? 0 : 1;
        final bMatch = b['ma_nam_hoc'] == yId ? 0 : 1;
        return aMatch.compareTo(bMatch);
      }

      _allClasses.sort(compareWithYear);
      _allSemesters.sort(compareWithYear);
    }

    if (!_initializedDefaults) {
      _initializedDefaults = true;
      final validClasses = _availableClasses;
      if (validClasses.isNotEmpty) {
        if (validClasses.length == 1) {
          classId = validClasses.first['ma_lop'] as num?;
        } else if (yId != null) {
          final matchingClass = validClasses.firstWhere(
            (c) => c['ma_nam_hoc'] == yId,
            orElse: () => <String, dynamic>{},
          );
          if (matchingClass.isNotEmpty) {
            classId = matchingClass['ma_lop'] as num?;
          }
        }

        if (classId != null) {
          final validSubjects = _availableSubjects;
          if (validSubjects.length == 1) {
            subjectId = validSubjects.first['ma_mon'] as num?;
          }

          if (subjectId != null) {
            final validTerms = _availableSemesters;
            if (validTerms.length == 1) {
              termId = validTerms.first['ma_hoc_ky'] as num?;
            } else if (yId != null) {
              final matchingTerm = validTerms.firstWhere(
                (s) => s['ma_nam_hoc'] == yId,
                orElse: () => <String, dynamic>{},
              );
              if (matchingTerm.isNotEmpty) {
                termId = matchingTerm['ma_hoc_ky'] as num?;
              }
            }
          }
        }
      }
    }

    return results;
  }

  Future<List<Json>> _allCatalogItems(String resource, {num? yearId}) async {
    String? cursor;
    final items = <Json>[];
    final seen = <String>{};
    do {
      final page = await ref
          .read(catalogRepositoryProvider)
          .list(resource, cursor: cursor, yearId: yearId);
      items.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor != null && !seen.add(cursor)) {
        throw StateError('Cursor danh mục bị lặp.');
      }
    } while (cursor != null);
    return items;
  }

  List<Json> get _availableClasses {
    final assignedClassIds = _assignments
        .map((a) => a['ma_lop'])
        .whereType<num>()
        .toSet();
    return _allClasses
        .where((c) => assignedClassIds.contains(c['ma_lop']))
        .toList();
  }

  List<Json> get _availableSubjects {
    if (classId == null) return const [];
    final assignedSubjectIds = _assignments
        .where((a) => a['ma_lop'] == classId)
        .map((a) => a['ma_mon'])
        .whereType<num>()
        .toSet();
    return _allSubjects
        .where((s) => assignedSubjectIds.contains(s['ma_mon']))
        .toList();
  }

  List<Json> get _availableSemesters {
    if (classId == null || subjectId == null) return const [];
    final assignedTermIds = _assignments
        .where((a) => a['ma_lop'] == classId && a['ma_mon'] == subjectId)
        .map((a) => a['ma_hoc_ky'])
        .whereType<num>()
        .toSet();
    return _allSemesters
        .where((s) => assignedTermIds.contains(s['ma_hoc_ky']))
        .toList();
  }

  void _onClassChanged(num? value) {
    setState(() {
      classId = value;
      error = null;

      final validSubjects = _availableSubjects;
      if (subjectId != null &&
          !validSubjects.any((s) => s['ma_mon'] == subjectId)) {
        subjectId = null;
      }
      if (subjectId == null && validSubjects.length == 1) {
        subjectId = validSubjects.first['ma_mon'] as num?;
      }

      final validTerms = _availableSemesters;
      if (termId != null && !validTerms.any((t) => t['ma_hoc_ky'] == termId)) {
        termId = null;
      }
      if (termId == null && validTerms.length == 1) {
        termId = validTerms.first['ma_hoc_ky'] as num?;
      }
    });
  }

  void _onSubjectChanged(num? value) {
    setState(() {
      subjectId = value;
      error = null;

      final validTerms = _availableSemesters;
      if (termId != null && !validTerms.any((t) => t['ma_hoc_ky'] == termId)) {
        termId = null;
      }
      if (termId == null && validTerms.length == 1) {
        termId = validTerms.first['ma_hoc_ky'] as num?;
      }
    });
  }

  void _onTermChanged(num? value) {
    setState(() {
      termId = value;
      error = null;
    });
  }

  Future<void> submit() async {
    if (classId == null || subjectId == null || termId == null) {
      setState(() => error = 'Chọn đủ lớp, môn học và học kỳ.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final book = await ref
          .read(gradebooksRepositoryProvider)
          .create(classId: classId!, subjectId: subjectId!, termId: termId!);
      if (mounted) Navigator.pop(context, book);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = errorMessage(e);
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final canSubmit =
        !busy &&
        _availableClasses.isNotEmpty &&
        classId != null &&
        subjectId != null &&
        termId != null;

    return AppDialog(
      title: 'Tạo bảng điểm',
      confirmLabel: 'Tạo',
      confirmEnabled: canSubmit,
      onConfirm: submit,
      onCancel: () {
        if (!busy) Navigator.pop(context);
      },
      child: FutureBuilder<List<List<Json>>>(
        future: options,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 120,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Đang tải danh mục…'),
                  ],
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return Text(errorMessage(snapshot.error!));
          }

          final hasNoAssignments = _availableClasses.isEmpty;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasNoAssignments) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.badSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                    border: Border.all(color: t.badLine),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: t.bad, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bạn chưa được phân công giảng dạy lớp nào trong năm học này.',
                            style: TextStyle(
                              color: t.bad,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _ReferenceDropdown(
                label: 'Lớp',
                items: _availableClasses,
                idKey: 'ma_lop',
                initialValue: classId,
                enabled: !hasNoAssignments,
                onChanged: _onClassChanged,
              ),
              const SizedBox(height: 14),
              _ReferenceDropdown(
                label: 'Môn học',
                items: _availableSubjects,
                idKey: 'ma_mon',
                initialValue: subjectId,
                enabled: classId != null,
                hintText: classId == null ? 'Chọn lớp trước' : null,
                helperText: classId == null ? 'Chọn lớp trước' : null,
                onChanged: _onSubjectChanged,
              ),
              const SizedBox(height: 14),
              _ReferenceDropdown(
                label: 'Học kỳ',
                items: _availableSemesters,
                idKey: 'ma_hoc_ky',
                initialValue: termId,
                enabled: classId != null && subjectId != null,
                hintText: classId == null
                    ? 'Chọn lớp trước'
                    : (subjectId == null ? 'Chọn môn học trước' : null),
                helperText: classId == null
                    ? 'Chọn lớp trước'
                    : (subjectId == null ? 'Chọn môn học trước' : null),
                onChanged: _onTermChanged,
              ),
              if (error != null) ...[
                const SizedBox(height: 14),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.badSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                    border: Border.all(color: t.badLine),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: t.bad, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error!,
                            style: TextStyle(color: t.bad, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ReferenceDropdown extends StatelessWidget {
  const _ReferenceDropdown({
    required this.label,
    required this.items,
    required this.idKey,
    required this.onChanged,
    this.initialValue,
    this.enabled = true,
    this.hintText,
    this.helperText,
  });

  final String label;
  final List<Json> items;
  final String idKey;
  final ValueChanged<num?> onChanged;
  final num? initialValue;
  final bool enabled;
  final String? hintText;
  final String? helperText;

  @override
  Widget build(BuildContext context) => AppSelectField<num>(
    value: initialValue != null && items.any((i) => i[idKey] == initialValue)
        ? initialValue
        : null,
    label: label,
    enabled: enabled,
    hintText: hintText,
    helperText: helperText,
    items: items
        .map(
          (item) => DropdownMenuItem<num>(
            value: item[idKey] as num,
            child: Text(rowLabel(item), overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: onChanged,
  );
}
