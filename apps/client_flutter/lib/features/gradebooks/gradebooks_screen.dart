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

  Widget _buildFilterBar(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    if (_loadingCatalog) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchBar(
          controller: _searchController,
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(t.surface),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm + 2),
              side: BorderSide(color: t.line2),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14),
          ),
          leading: Icon(Icons.search_rounded, color: t.ink3),
          hintText: 'Tìm kiếm lớp, môn học, học kỳ…',
          hintStyle: WidgetStatePropertyAll(
            theme.textTheme.bodyMedium?.copyWith(color: t.ink3),
          ),
          trailing: [
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear_rounded, size: 20),
                tooltip: 'Xóa tìm kiếm',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
          ],
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AcademicYearFilterControl(
              years: _years,
              width: 170,
              onChanged: () {
                cursors.clear();
                cursors.add(null);
                setState(reload);
              },
            ),
            AppFilterDropdown<String>(
              label: 'Trạng thái',
              icon: Icons.tune_rounded,
              value: _filterStatus,
              width: 170,
              items: const [
                DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
                DropdownMenuItem(
                  value: 'DANG_NHAP_LIEU',
                  child: Text('Đang nhập liệu'),
                ),
                DropdownMenuItem(value: 'DA_CHOT', child: Text('Đã khóa')),
              ],
              onChanged: (val) => setState(() => _filterStatus = val),
            ),
            AppFilterDropdown<num>(
              label: 'Lớp học',
              icon: Icons.meeting_room_outlined,
              value: _filterClassId,
              width: 170,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Tất cả các lớp'),
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
            ),
            AppFilterDropdown<num>(
              label: 'Môn học',
              icon: Icons.menu_book_outlined,
              value: _filterSubjectId,
              width: 180,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Tất cả môn học'),
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
            ),
            if (_hasFilter)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Đặt lại'),
                onPressed: _clearFilters,
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;

    return AppScaffold(
      title: teacher ? 'Bảng điểm' : 'Bảng điểm toàn trường',
      currentPath: '/gradebooks',
      showBackButton: true,
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          onPressed: () => setState(reload),
          icon: const Icon(Icons.refresh),
        ),
      ],
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
                                icon: const Icon(Icons.refresh_rounded),
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
                            padding: EdgeInsets.only(
                              top: 14,
                              bottom: teacher ? 72 : 20,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: t.priSoft,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                    border: Border.all(color: t.priLine),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      'Trang ${cursors.length}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: t.priLink,
                                          ),
                                    ),
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

  /// Bảng (từ 768 px) theo `gv-sheets`: chỉ những cột có dữ liệu trong
  /// `GradebookDto`. Tiến độ, sĩ số, hạn nhập và ngày cập nhật của prototype
  /// không có trong DTO nên không vẽ (xem docs/design/open-questions.md).
  Widget _buildTable(BuildContext context, List<GradebookDto> items) {
    final t = context.tokens;
    final radius = BorderRadius.circular(AppRadius.md);
    return ListView(
      children: [
        DecoratedBox(
          key: const ValueKey('gradebooks-table'),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: radius,
            border: Border.all(color: t.line),
            boxShadow: t.shadow,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _tableHeader(context),
                for (final book in items) ...[
                  Divider(height: 1, thickness: 1, color: t.line),
                  _tableRow(context, book),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static const double _versionColumnWidth = 96;
  static const double _statusColumnWidth = 160;
  static const double _actionColumnWidth = 132;

  Widget _tableHeader(BuildContext context) {
    final t = context.tokens;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: t.ink3,
    );
    Widget cell(String label, {int flex = 0, double? width}) {
      final text = Text(label.toUpperCase(), style: style, maxLines: 1);
      return width != null
          ? SizedBox(width: width, child: text)
          : Expanded(flex: flex, child: text);
    }

    return ColoredBox(
      color: t.subtle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            cell('Lớp', flex: 2),
            cell('Môn học', flex: 3),
            cell('Học kỳ', flex: 3),
            cell('Phiên bản', width: _versionColumnWidth),
            cell('Trạng thái', width: _statusColumnWidth),
            const SizedBox(width: _actionColumnWidth),
          ],
        ),
      ),
    );
  }

  Widget _tableRow(BuildContext context, GradebookDto book) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final locked = book.status.value == 'DA_CHOT';
    final canEnter = teacher && !locked;
    void open() => context.go('/gradebooks/${book.id}');
    return InkWell(
      onTap: open,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                book.className,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: t.heading,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                book.subjectName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: t.ink),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                book.termName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: t.ink2),
              ),
            ),
            SizedBox(
              width: _versionColumnWidth,
              child: Text(
                'v${book.version}',
                style: theme.textTheme.bodySmall?.copyWith(color: t.ink3),
              ),
            ),
            SizedBox(
              width: _statusColumnWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GradebookStatusBadge(book.status.value),
              ),
            ),
            SizedBox(
              width: _actionColumnWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: canEnter
                    ? FilledButton(
                        onPressed: open,
                        child: const Text('Nhập điểm'),
                      )
                    : OutlinedButton(onPressed: open, child: const Text('Xem')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thẻ cho màn hẹp theo `m-sheets` (`.msheet`): tiêu đề lớp · môn, nhãn
  /// trạng thái, dòng phụ là học kỳ và phiên bản.
  Widget _buildGradebookCard(BuildContext context, GradebookDto book) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Material(
      color: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: t.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/gradebooks/${book.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${book.className} · ${book.subjectName}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: t.heading,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GradebookStatusBadge(book.status.value),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: t.ink3),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      book.termName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: t.ink2),
                    ),
                  ),
                  Text(
                    'v${book.version}',
                    style: theme.textTheme.bodySmall?.copyWith(color: t.ink3),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18, color: t.ink3),
                ],
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

  @override
  void initState() {
    super.initState();
    options = _loadOptions();
  }

  Future<List<List<Json>>> _loadOptions() async {
    final results = await Future.wait([
      _allCatalogItems('classes'),
      _allCatalogItems('subjects'),
      _allCatalogItems('semesters'),
    ]);
    final viewingYear = ref.read(viewingYearProvider);
    if (viewingYear != null && viewingYear.id != null) {
      final yId = viewingYear.id;
      int compareWithYear(Json a, Json b) {
        final aMatch = a['ma_nam_hoc'] == yId ? 0 : 1;
        final bMatch = b['ma_nam_hoc'] == yId ? 0 : 1;
        return aMatch.compareTo(bMatch);
      }

      results[0].sort(compareWithYear);
      results[2].sort(compareWithYear);

      if (!_initializedDefaults) {
        _initializedDefaults = true;
        final matchingClass = results[0].firstWhere(
          (c) => c['ma_nam_hoc'] == yId,
          orElse: () => <String, dynamic>{},
        );
        if (matchingClass.isNotEmpty) {
          classId = matchingClass['ma_lop'] as num?;
        }
        final matchingTerm = results[2].firstWhere(
          (s) => s['ma_nam_hoc'] == yId,
          orElse: () => <String, dynamic>{},
        );
        if (matchingTerm.isNotEmpty) {
          termId = matchingTerm['ma_hoc_ky'] as num?;
        }
      }
    }
    return results;
  }

  Future<List<Json>> _allCatalogItems(String resource) async {
    String? cursor;
    final items = <Json>[];
    final seen = <String>{};
    do {
      final page = await ref
          .read(catalogRepositoryProvider)
          .list(resource, cursor: cursor);
      items.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor != null && !seen.add(cursor)) {
        throw StateError('Cursor danh mục bị lặp.');
      }
    } while (cursor != null);
    return items;
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

    return AppDialog(
      title: 'Tạo bảng điểm',
      confirmLabel: 'Tạo',
      confirmEnabled: !busy,
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
          final values = snapshot.data!;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ReferenceDropdown(
                label: 'Lớp',
                items: values[0],
                idKey: 'ma_lop',
                initialValue: classId,
                onChanged: (value) => classId = value,
              ),
              const SizedBox(height: 14),
              _ReferenceDropdown(
                label: 'Môn học',
                items: values[1],
                idKey: 'ma_mon',
                initialValue: subjectId,
                onChanged: (value) => subjectId = value,
              ),
              const SizedBox(height: 14),
              _ReferenceDropdown(
                label: 'Học kỳ',
                items: values[2],
                idKey: 'ma_hoc_ky',
                initialValue: termId,
                onChanged: (value) => termId = value,
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
  });

  final String label;
  final List<Json> items;
  final String idKey;
  final ValueChanged<num?> onChanged;
  final num? initialValue;

  @override
  Widget build(BuildContext context) => AppSelectField<num>(
    value: initialValue != null && items.any((i) => i[idKey] == initialValue)
        ? initialValue
        : null,
    label: label,
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
