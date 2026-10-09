import '../../app/widgets/app_edge_scrollbar.dart';
import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/shimmer_loading.dart';
import '../academic_catalog/fields.dart';
import '../academic_catalog/repository.dart';
import '../authentication/session.dart';
import 'repository.dart';

class GradebooksScreen extends ConsumerStatefulWidget {
  const GradebooksScreen({super.key});

  @override
  ConsumerState<GradebooksScreen> createState() => _GradebooksScreenState();
}

class _GradebooksScreenState extends ConsumerState<GradebooksScreen> {
  late Future<GradebookListDto> page;
  final cursors = <num?>[null];

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
      final classes = await _allCatalogItems(
        'classes',
      ).catchError((_) => <Json>[]);
      final subjects = await _allCatalogItems(
        'subjects',
      ).catchError((_) => <Json>[]);
      if (!mounted) return;
      setState(() {
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
    page = teacher
        ? ref.read(gradebooksRepositoryProvider).list(cursor: cursors.last)
        : _allBooks();
  }

  Future<GradebookListDto> _allBooks() async {
    num? cursor;
    final items = <GradebookDto>[];
    final seen = <num>{};
    do {
      final result = await ref
          .read(gradebooksRepositoryProvider)
          .list(cursor: cursor);
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

  Widget _buildFilterBar(ColorScheme colorScheme, ThemeData theme) {
    if (_loadingCatalog) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }

    final statusLabel = switch (_filterStatus) {
      'DANG_NHAP_LIEU' => 'Đang nhập liệu',
      'DA_CHOT' => 'Đã chốt sổ',
      _ => 'Tất cả trạng thái ▾',
    };

    final classLabel = _filterClassId != null
        ? (_classes.firstWhere(
              (c) => c['ma_lop'] == _filterClassId,
              orElse: () => {'ten_lop': 'Lớp $_filterClassId'},
            )['ten_lop']?.toString() ??
            'Lớp $_filterClassId')
        : 'Lớp học ▾';

    final subjectLabel = _filterSubjectId != null
        ? (_subjects.firstWhere(
              (s) => s['ma_mon'] == _filterSubjectId,
              orElse: () => {'ten_mon': 'Môn $_filterSubjectId'},
            )['ten_mon']?.toString() ??
            'Môn $_filterSubjectId')
        : 'Môn học ▾';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchBar(
          controller: _searchController,
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(
            colorScheme.surfaceContainerHighest.withAlpha(120),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outlineVariant.withAlpha(90),
              ),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14),
          ),
          leading: Icon(
            Icons.search_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          hintText: 'Tìm kiếm lớp, môn học, học kỳ…',
          hintStyle: WidgetStatePropertyAll(
            theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withAlpha(180),
            ),
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                avatar: Icon(
                  _filterStatus == null
                      ? Icons.tune_rounded
                      : (_filterStatus == 'DA_CHOT'
                          ? Icons.lock_rounded
                          : Icons.edit_note_rounded),
                  size: 16,
                ),
                label: Text(statusLabel),
                selected: _filterStatus != null,
                onSelected: (_) => _showStatusFilterSheet(context),
                onDeleted: _filterStatus != null
                    ? () => setState(() => _filterStatus = null)
                    : null,
              ),
              const SizedBox(width: 8),
              FilterChip(
                avatar: const Icon(Icons.meeting_room_outlined, size: 16),
                label: Text(classLabel),
                selected: _filterClassId != null,
                onSelected: (_) => _showClassFilterSheet(context),
                onDeleted: _filterClassId != null
                    ? () => setState(() => _filterClassId = null)
                    : null,
              ),
              const SizedBox(width: 8),
              FilterChip(
                avatar: const Icon(Icons.menu_book_outlined, size: 16),
                label: Text(subjectLabel),
                selected: _filterSubjectId != null,
                onSelected: (_) => _showSubjectFilterSheet(context),
                onDeleted: _filterSubjectId != null
                    ? () => setState(() => _filterSubjectId = null)
                    : null,
              ),
              if (_hasFilter) ...[
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Đặt lại'),
                  onPressed: () => setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _filterClassId = null;
                    _filterSubjectId = null;
                    _filterStatus = null;
                  }),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showStatusFilterSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Lọc theo trạng thái',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.all_inclusive_rounded),
              title: const Text('Tất cả trạng thái'),
              trailing: _filterStatus == null
                  ? const Icon(Icons.check_rounded, color: Colors.blue)
                  : null,
              onTap: () => Navigator.pop(ctx, 'ALL'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded, color: Colors.orange),
              title: const Text('Đang nhập liệu'),
              trailing: _filterStatus == 'DANG_NHAP_LIEU'
                  ? const Icon(Icons.check_rounded, color: Colors.blue)
                  : null,
              onTap: () => Navigator.pop(ctx, 'DANG_NHAP_LIEU'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_rounded, color: Colors.green),
              title: const Text('Đã chốt sổ'),
              trailing: _filterStatus == 'DA_CHOT'
                  ? const Icon(Icons.check_rounded, color: Colors.blue)
                  : null,
              onTap: () => Navigator.pop(ctx, 'DA_CHOT'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _filterStatus = selected == 'ALL' ? null : selected);
    }
  }

  Future<void> _showClassFilterSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<num?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Chọn lớp học',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.all_inclusive_rounded),
                title: const Text('Tất cả các lớp'),
                trailing: _filterClassId == null
                    ? const Icon(Icons.check_rounded, color: Colors.blue)
                    : null,
                onTap: () => Navigator.pop(ctx, -1),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: _classes.length,
                  itemBuilder: (context, index) {
                    final c = _classes[index];
                    final id = c['ma_lop'] as num?;
                    final name = c['ten_lop']?.toString() ?? 'Lớp $id';
                    final isSelected = id == _filterClassId;
                    return ListTile(
                      leading: const Icon(Icons.meeting_room_outlined),
                      title: Text(name),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.blue)
                          : null,
                      onTap: () => Navigator.pop(ctx, id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _filterClassId = selected == -1 ? null : selected);
    }
  }

  Future<void> _showSubjectFilterSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<num?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Chọn môn học',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.all_inclusive_rounded),
                title: const Text('Tất cả môn học'),
                trailing: _filterSubjectId == null
                    ? const Icon(Icons.check_rounded, color: Colors.blue)
                    : null,
                onTap: () => Navigator.pop(ctx, -1),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final s = _subjects[index];
                    final id = s['ma_mon'] as num?;
                    final name = s['ten_mon']?.toString() ?? 'Môn $id';
                    final isSelected = id == _filterSubjectId;
                    return ListTile(
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(name),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.blue)
                          : null,
                      onTap: () => Navigator.pop(ctx, id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _filterSubjectId = selected == -1 ? null : selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(teacher ? 'Bảng điểm' : 'Bảng điểm toàn trường'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: () => setState(reload),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: teacher
          ? FloatingActionButton.extended(
              onPressed: create,
              icon: const Icon(Icons.add),
              label: const Text('Tạo bảng điểm'),
            )
          : null,
      body: AppEdgeScrollbar(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1140),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFilterBar(colorScheme, theme),
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
                            final matchClass =
                                book.className.toLowerCase().contains(q);
                            final matchSubject =
                                book.subjectName.toLowerCase().contains(q);
                            final matchTerm =
                                book.termName.toLowerCase().contains(q);
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
                                const Icon(
                                  Icons.filter_alt_off_rounded,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Không có bảng điểm phù hợp với bộ lọc.',
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () => setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _filterClassId = null;
                                    _filterSubjectId = null;
                                    _filterStatus = null;
                                  }),
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
                                    return GridView.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisExtent: 130,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 12,
                                      ),
                                      itemCount: filteredItems.length,
                                      itemBuilder: (context, index) =>
                                          _buildGradebookCard(
                                        context,
                                        filteredItems[index],
                                        colorScheme,
                                        theme,
                                      ),
                                    );
                                  }
                                  return ListView.separated(
                                    itemCount: filteredItems.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) =>
                                        _buildGradebookCard(
                                      context,
                                      filteredItems[index],
                                      colorScheme,
                                      theme,
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: colorScheme.outlineVariant
                                            .withAlpha(80),
                                      ),
                                    ),
                                    child: Text(
                                      'Trang ${cursors.length}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.primary,
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
      ),
    );
  }

  Widget _buildGradebookCard(
    BuildContext context,
    GradebookDto book,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final locked = book.status.value == 'DA_CHOT';
    final classDisplay = book.className;
    final subjectDisplay = book.subjectName;
    final termDisplay = book.termName;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(90),
        ),
      ),
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/gradebooks/${book.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dòng 1: Tên lớp in đậm cỡ lớn, Tên môn học, và Chip trạng thái màu sắc nổi bật
              Row(
                children: [
                  Text(
                    classDisplay,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '·',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      subjectDisplay,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: locked
                          ? (theme.brightness == Brightness.dark
                              ? Colors.green.shade900.withAlpha(80)
                              : Colors.green.shade50)
                          : (theme.brightness == Brightness.dark
                              ? Colors.orange.shade900.withAlpha(80)
                              : Colors.orange.shade50),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: locked
                            ? Colors.green.withAlpha(120)
                            : Colors.orange.withAlpha(120),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          locked
                              ? Icons.lock_outline_rounded
                              : Icons.edit_note_rounded,
                          size: 13,
                          color: locked
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          locked ? 'Đã chốt sổ' : 'Đang nhập liệu',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: locked
                                ? Colors.green.shade700
                                : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Dòng 2: Học kỳ & Năm học, Phiên bản bảng điểm
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      termDisplay,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'v${book.version}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Dòng 3: Sĩ số / thông tin lớp và icon tiến độ trực quan
              Row(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 15,
                    color: colorScheme.primary.withAlpha(180),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Sĩ số học sinh',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    locked
                        ? Icons.check_circle_outline_rounded
                        : Icons.pending_actions_rounded,
                    size: 14,
                    color: locked
                        ? Colors.green.shade600
                        : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    locked ? 'Hoàn tất' : 'Đang xử lý',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: locked
                          ? Colors.green.shade600
                          : Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: colorScheme.outline,
                  ),
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

  @override
  void initState() {
    super.initState();
    options = Future.wait([
      _allCatalogItems('classes'),
      _allCatalogItems('subjects'),
      _allCatalogItems('semesters'),
    ]);
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
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Tạo bảng điểm'),
      content: SizedBox(
        width: 480,
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
                  onChanged: (value) => classId = value,
                ),
                const SizedBox(height: 14),
                _ReferenceDropdown(
                  label: 'Môn học',
                  items: values[1],
                  idKey: 'ma_mon',
                  onChanged: (value) => subjectId = value,
                ),
                const SizedBox(height: 14),
                _ReferenceDropdown(
                  label: 'Học kỳ',
                  items: values[2],
                  idKey: 'ma_hoc_ky',
                  onChanged: (value) => termId = value,
                ),
                if (error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withAlpha(120),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorScheme.error.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: colorScheme.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error!,
                            style: TextStyle(
                              color: colorScheme.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: busy ? null : submit, child: const Text('Tạo')),
      ],
    );
  }
}

class _ReferenceDropdown extends StatelessWidget {
  const _ReferenceDropdown({
    required this.label,
    required this.items,
    required this.idKey,
    required this.onChanged,
  });

  final String label;
  final List<Json> items;
  final String idKey;
  final ValueChanged<num?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<num>(
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
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
