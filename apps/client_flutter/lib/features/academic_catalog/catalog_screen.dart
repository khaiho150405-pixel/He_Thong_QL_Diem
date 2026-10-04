import '../../app/widgets/app_edge_scrollbar.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/widgets/app_controls.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/role_badge.dart';
import '../../app/widgets/shimmer_loading.dart';
import '../authentication/session.dart';
import '../../core/vietnamese_sort.dart';
import 'repository.dart';
import 'fields.dart';
import 'edit_dialog.dart';
import 'catalog_import_dialog.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key, required this.resource});
  final String resource;
  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  late Future<CatalogPageData> page;
  final cursors = <String?>[null];
  final searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  List<String> _searchSuggestions = const [];
  String filter = '';
  String _studentSortBy = 'name'; // 'name' | 'class' | 'status'
  bool _sortAscending = true;
  int _clientPage = 0;

  // System References cache
  Map<String, List<Json>> _references = {};
  bool _loadingReferences = false;

  // Filter States
  num? _filterClassId;
  num? _filterSubjectId;
  num? _filterTeacherId;
  num? _filterSemesterId;
  num? _filterYearId;
  int? _filterGrade;
  String? _filterStudentStatus; // null | 'active' | 'inactive'
  String? _filterRole; // null | 'QUAN_TRI_VIEN' | 'GIAO_VIEN' | 'HOC_SINH'
  bool? _filterAccountActive; // null | true | false
  String? _filterDepartment; // null | department string
  int? _filterPeriods; // null | 1 | 2 | 3 | 4
  bool? _filterRequired; // null | true | false
  bool? _filterCurrentYear; // null | true | false

  ResourceSpec get spec =>
      resources.firstWhere((r) => r.key == widget.resource);
  bool get admin => ref.read(sessionProvider)?.role.value == 'QUAN_TRI_VIEN';
  bool get studentViewer => ref.read(sessionProvider)?.role.value == 'HOC_SINH';

  bool get _hasActiveFilter =>
      filter.isNotEmpty ||
      _filterClassId != null ||
      _filterSubjectId != null ||
      _filterTeacherId != null ||
      _filterSemesterId != null ||
      _filterYearId != null ||
      _filterGrade != null ||
      _filterStudentStatus != null ||
      _filterRole != null ||
      _filterAccountActive != null ||
      _filterDepartment != null ||
      _filterPeriods != null ||
      _filterRequired != null ||
      _filterCurrentYear != null;

  final Map<num, int> _studentSchoolStt = {};
  final Map<num, int> _studentClassStt = {};

  /// STT is meaningful only for the complete school list or the class view.
  /// Search, attendance and other sort modes show a subset/reordered list, so
  /// hiding it prevents users from treating a position in that subset as rank.
  bool get _showsStudentStt {
    if (_studentSortBy == 'status') return false;
    if (_studentSortBy == 'class' || _filterClassId != null) return true;
    return _studentSortBy == 'name' && !_hasActiveFilter;
  }

  bool get _showsClassStudentStt =>
      _showsStudentStt && (_studentSortBy == 'class' || _filterClassId != null);

  void _calculateStudentOrders(List<Json> allStudents) {
    final orders = StudentOrderIndex.from(allStudents);
    _studentSchoolStt.clear();
    _studentSchoolStt.addAll(orders.school);
    _studentClassStt.clear();
    _studentClassStt.addAll(orders.byClass);
  }

  int _compareVietnameseNames(String a, String b) {
    return VietnameseCollation.compareStudentNames(a, b);
  }

  String _extractClassName(Json row) {
    final label = row['label']?.toString() ?? '';
    if (label.contains(' · ')) {
      return label.split(' · ').last.trim();
    }
    if (row['ten_lop'] != null) {
      return row['ten_lop'].toString();
    }
    if (row['ma_lop'] != null) {
      return 'Lớp ${row['ma_lop']}';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _loadReferences();
    _loadSearchSuggestions();
    reload();
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(CatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resource != widget.resource) {
      if (widget.resource == 'students') {
        _fetchAll('students')
            .then((items) {
              if (mounted) setState(() => _calculateStudentOrders(items));
            })
            .catchError((_) {});
      }
      _resetFilters();
      _loadSearchSuggestions();
    }
  }

  Future<void> _loadReferences() async {
    if (_references.isNotEmpty) return;
    final role = ref.read(sessionProvider)?.role.value;
    if (role == 'HOC_SINH') {
      // Học sinh chỉ có quyền xem học sinh của mình, không tải danh mục quản trị khác
      return;
    }
    if (mounted) setState(() => _loadingReferences = true);
    try {
      final classes = await _fetchAll('classes').catchError((_) => <Json>[]);
      final subjects = await _fetchAll('subjects').catchError((_) => <Json>[]);
      final teachers = await _fetchAll('teachers').catchError((_) => <Json>[]);
      final years = await _fetchAll('years').catchError((_) => <Json>[]);
      final semesters = await _fetchAll(
        'semesters',
      ).catchError((_) => <Json>[]);
      if (widget.resource == 'students') {
        final allStudents = await _fetchAll(
          'students',
        ).catchError((_) => <Json>[]);
        _calculateStudentOrders(allStudents);
      }
      if (!mounted) return;
      setState(() {
        _references = {
          'classes': classes,
          'subjects': subjects,
          'teachers': teachers,
          'years': years,
          'semesters': semesters,
        };
        _loadingReferences = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingReferences = false);
    }
  }

  Future<List<Json>> _fetchAll(String resource) async {
    final items = <Json>[];
    String? cursor;
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

  Future<void> _loadSearchSuggestions() async {
    try {
      final rows = await _fetchAll(widget.resource);
      if (!mounted) return;
      setState(() {
        _searchSuggestions = rows
            .map(rowLabel)
            .where((label) => label.trim().isNotEmpty)
            .toSet()
            .take(300)
            .toList();
      });
    } catch (_) {
      // Search still works against the loaded rows when suggestions are unavailable.
    }
  }

  String _normalized(String value) {
    const source =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const target =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    var result = value.toLowerCase();
    for (var i = 0; i < source.length; i++) {
      result = result.replaceAll(source[i], target[i]);
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _searchAsYouType(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() {
        filter = value.trim();
        _clientPage = 0;
        cursors
          ..clear()
          ..add(null);
        reload();
      });
    });
  }

  void reload() {
    if (widget.resource == 'students' || _hasActiveFilter) {
      page = _fetchAll(widget.resource).then((items) {
        if (widget.resource == 'students') {
          _calculateStudentOrders(items);
        }
        return CatalogPageData(items, null);
      });
    } else {
      page = ref
          .read(catalogRepositoryProvider)
          .list(widget.resource, cursor: cursors.last, q: filter);
    }
  }

  void _resetFilters() {
    searchController.clear();
    filter = '';
    _filterClassId = null;
    _filterSubjectId = null;
    _filterTeacherId = null;
    _filterSemesterId = null;
    _filterYearId = null;
    _filterGrade = null;
    _filterStudentStatus = null;
    _filterRole = null;
    _filterAccountActive = null;
    _filterDepartment = null;
    _filterPeriods = null;
    _filterRequired = null;
    _filterCurrentYear = null;
    _clientPage = 0;
    cursors.clear();
    cursors.add(null);
    reload();
  }

  bool _matchesRow(Json row) {
    if (filter.isNotEmpty) {
      final text = _normalized(row.values.join(' '));
      if (!text.contains(_normalized(filter))) return false;
    }

    switch (widget.resource) {
      case 'students':
        if (_filterClassId != null && row['ma_lop'] != _filterClassId) {
          return false;
        }
        if (_filterStudentStatus != null) {
          final isActive = row['dang_theo_hoc'] == true;
          if (_filterStudentStatus == 'active' && !isActive) return false;
          if (_filterStudentStatus == 'inactive' && isActive) return false;
        }
        break;
      case 'classes':
        if (_filterGrade != null && row['khoi'] != _filterGrade) {
          return false;
        }
        if (_filterYearId != null && row['ma_nam_hoc'] != _filterYearId) {
          return false;
        }
        if (_filterTeacherId != null &&
            row['ma_gv_chu_nhiem'] != _filterTeacherId) {
          return false;
        }
        break;
      case 'assignments':
        if (_filterClassId != null && row['ma_lop'] != _filterClassId) {
          return false;
        }
        if (_filterSubjectId != null && row['ma_mon'] != _filterSubjectId) {
          return false;
        }
        if (_filterTeacherId != null &&
            row['ma_giao_vien'] != _filterTeacherId) {
          return false;
        }
        if (_filterSemesterId != null &&
            row['ma_hoc_ky'] != _filterSemesterId) {
          return false;
        }
        break;
      case 'components':
        if (_filterSubjectId != null && row['ma_mon'] != _filterSubjectId) {
          return false;
        }
        if (_filterRequired != null && row['bat_buoc'] != _filterRequired) {
          return false;
        }
        break;
      case 'accounts':
        if (_filterRole != null && row['role'] != _filterRole) {
          return false;
        }
        if (_filterAccountActive != null &&
            row['active'] != _filterAccountActive) {
          return false;
        }
        break;
      case 'teachers':
        if (_filterDepartment != null &&
            row['to_chuyen_mon'] != _filterDepartment) {
          return false;
        }
        break;
      case 'semesters':
        if (_filterYearId != null && row['ma_nam_hoc'] != _filterYearId) {
          return false;
        }
        break;
      case 'subjects':
        if (_filterPeriods != null && row['so_tiet_tuan'] != _filterPeriods) {
          return false;
        }
        break;
      case 'years':
        if (_filterCurrentYear != null &&
            row['hien_hanh'] != _filterCurrentYear) {
          return false;
        }
        break;
    }
    return true;
  }

  Future<void> edit([Json? row]) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditDialog(spec: spec, row: row),
    );
    if (changed == true && mounted) setState(reload);
  }

  bool get _supportsImport =>
      const {'accounts', 'teachers', 'students'}.contains(widget.resource);

  Future<void> _showImport() async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CatalogImportDialog(
        resource: widget.resource,
        repository: ref.read(catalogRepositoryProvider),
      ),
    );
    if (changed == true && mounted) {
      await _loadSearchSuggestions();
      setState(reload);
    }
  }

  Future<void> remove(Json row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bản ghi chưa sử dụng?'),
        content: Text(
          'Xóa ${rowLabel(row)}? Dữ liệu đã được tham chiếu sẽ được giữ lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(catalogRepositoryProvider)
          .remove(spec.key, row[spec.id] as num);
      if (mounted) setState(reload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage(e))));
      }
    }
  }

  IconData _iconForResource(String key) {
    switch (key) {
      case 'years':
        return Icons.calendar_month_outlined;
      case 'semesters':
        return Icons.date_range_outlined;
      case 'classes':
        return Icons.meeting_room_outlined;
      case 'students':
        return Icons.people_alt_outlined;
      case 'subjects':
        return Icons.menu_book_outlined;
      case 'components':
        return Icons.percent_outlined;
      case 'teachers':
        return Icons.badge_outlined;
      case 'assignments':
        return Icons.assignment_ind_outlined;
      case 'accounts':
        return Icons.manage_accounts_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(spec.label),
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
      floatingActionButton: admin
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_supportsImport) ...[
                  AppActionButton(
                    key: ValueKey('catalog-import-${widget.resource}'),
                    kind: AppActionButtonKind.secondary,
                    onPressed: _showImport,
                    icon: Icons.upload_file_outlined,
                    label: 'Nhập từ file',
                  ),
                  const SizedBox(height: AppControlMetrics.spacing),
                ],
                AppActionButton(
                  key: ValueKey('catalog-add-${widget.resource}'),
                  onPressed: () => edit(),
                  icon: Icons.add,
                  label: 'Thêm mới',
                ),
              ],
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
                  // Học sinh chỉ nhận đúng hồ sơ của mình từ backend, nên không
                  // hiển thị bộ lọc/tìm kiếm không có ý nghĩa cho một bản ghi.
                  if (!studentViewer) _buildFilterBar(colorScheme, theme),

                  // Student Sort Toolbar
                  if (spec.key == 'students' && !studentViewer) ...[
                    const SizedBox(height: 8),
                    _buildStudentSortToolbar(colorScheme, theme),
                  ],

                  const SizedBox(height: 16),

                  // Main Content
                  Expanded(
                    child: FutureBuilder<CatalogPageData>(
                      future: page,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const ShimmerLoading(
                            itemCount: 6,
                            itemHeight: 76,
                          );
                        }
                        if (snapshot.hasError) {
                          return EmptyState(
                            icon: Icons.error_outline,
                            title: 'Lỗi tải dữ liệu',
                            message: errorMessage(snapshot.error!),
                            actionLabel: 'Thử lại',
                            onAction: () => setState(reload),
                          );
                        }
                        final data = snapshot.data!;
                        var rows = data.items.where(_matchesRow).toList();

                        // Student Sorting Logic & STT Calculation
                        if (spec.key == 'students') {
                          _calculateStudentOrders(data.items);
                          rows.sort((a, b) {
                            int res = 0;
                            if (_studentSortBy == 'name') {
                              final nameA = (a['ho_ten'] ?? rowLabel(a))
                                  .toString();
                              final nameB = (b['ho_ten'] ?? rowLabel(b))
                                  .toString();
                              res = _compareVietnameseNames(nameA, nameB);
                            } else if (_studentSortBy == 'class') {
                              final classA = _extractClassName(a);
                              final classB = _extractClassName(b);
                              res = classA.compareTo(classB);
                              if (res == 0) {
                                final nameA = (a['ho_ten'] ?? rowLabel(a))
                                    .toString();
                                final nameB = (b['ho_ten'] ?? rowLabel(b))
                                    .toString();
                                res = _compareVietnameseNames(nameA, nameB);
                              }
                            } else if (_studentSortBy == 'status') {
                              final statusA = a['dang_theo_hoc'] == true
                                  ? 1
                                  : 0;
                              final statusB = b['dang_theo_hoc'] == true
                                  ? 1
                                  : 0;
                              res = statusB.compareTo(
                                statusA,
                              ); // active (1) first by default
                              if (res == 0) {
                                final nameA = (a['ho_ten'] ?? rowLabel(a))
                                    .toString();
                                final nameB = (b['ho_ten'] ?? rowLabel(b))
                                    .toString();
                                res = _compareVietnameseNames(nameA, nameB);
                              }
                            }
                            return _sortAscending ? res : -res;
                          });
                        }

                        if (rows.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                const Text('Chưa có dữ liệu phù hợp.'),
                                if (_hasActiveFilter) ...[
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: _resetFilters,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Xóa bộ lọc'),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }

                        final isClientPaged = data.nextCursor == null;
                        const pageSize = 50;
                        final totalClientPages = (rows.length / pageSize)
                            .ceil();
                        final safeClientPage = _clientPage.clamp(
                          0,
                          (totalClientPages - 1).clamp(0, 9999),
                        );
                        final displayRows =
                            isClientPaged && rows.length > pageSize
                            ? rows
                                  .skip(safeClientPage * pageSize)
                                  .take(pageSize)
                                  .toList()
                            : rows;

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
                                            mainAxisExtent: 94,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 10,
                                          ),
                                      itemCount: displayRows.length,
                                      itemBuilder: (context, index) =>
                                          _buildRowCard(
                                            context,
                                            displayRows[index],
                                            colorScheme,
                                            theme,
                                          ),
                                    );
                                  }
                                  return ListView.separated(
                                    itemCount: displayRows.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) =>
                                        _buildRowCard(
                                          context,
                                          displayRows[index],
                                          colorScheme,
                                          theme,
                                        ),
                                  );
                                },
                              ),
                            ),

                            // Pagination Controls
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (isClientPaged &&
                                      totalClientPages > 1) ...[
                                    TextButton(
                                      onPressed: safeClientPage > 0
                                          ? () => setState(
                                              () => _clientPage =
                                                  safeClientPage - 1,
                                            )
                                          : null,
                                      child: const Text('Trang trước'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        'Trang ${safeClientPage + 1} / $totalClientPages (${rows.length} mục)',
                                      ),
                                    ),
                                    TextButton(
                                      onPressed:
                                          safeClientPage < totalClientPages - 1
                                          ? () => setState(
                                              () => _clientPage =
                                                  safeClientPage + 1,
                                            )
                                          : null,
                                      child: const Text('Trang sau'),
                                    ),
                                  ] else ...[
                                    TextButton(
                                      onPressed: cursors.length > 1
                                          ? () => setState(() {
                                              cursors.removeLast();
                                              reload();
                                            })
                                          : null,
                                      child: const Text('Trang trước'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        'Trang ${cursors.length} (${rows.length} mục)',
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: data.nextCursor != null
                                          ? () => setState(() {
                                              cursors.add(data.nextCursor);
                                              reload();
                                            })
                                          : null,
                                      child: const Text('Trang sau'),
                                    ),
                                  ],
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

  Widget _buildFilterBar(ColorScheme colorScheme, ThemeData theme) {
    if (_loadingReferences) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    final activeCount = [
      filter.isNotEmpty,
      _filterClassId != null,
      _filterSubjectId != null,
      _filterTeacherId != null,
      _filterSemesterId != null,
      _filterYearId != null,
      _filterGrade != null,
      _filterStudentStatus != null,
      _filterRole != null,
      _filterAccountActive != null,
      _filterDepartment != null,
      _filterPeriods != null,
      _filterRequired != null,
      _filterCurrentYear != null,
    ].where((b) => b).length;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bộ lọc hệ thống',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (activeCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$activeCount đang chọn',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_hasActiveFilter)
                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Đặt lại bộ lọc'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ..._buildResourceDropdowns(colorScheme),
                SizedBox(
                  width: AppControlMetrics.responsiveFieldWidth(context),
                  height: AppControlMetrics.height,
                  child: RawAutocomplete<String>(
                    textEditingController: searchController,
                    focusNode: _searchFocusNode,
                    displayStringForOption: (option) => option,
                    optionsBuilder: (value) {
                      final query = _normalized(value.text);
                      if (query.isEmpty) return const Iterable<String>.empty();
                      return _searchSuggestions
                          .where((item) => _normalized(item).contains(query))
                          .take(8);
                    },
                    onSelected: (value) {
                      searchController.text = value;
                      _searchAsYouType(value);
                    },
                    optionsViewBuilder: (context, onSelected, options) => Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(10),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 360,
                            maxHeight: 280,
                          ),
                          child: ListView(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shrinkWrap: true,
                            children: [
                              for (final option in options)
                                ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.search, size: 18),
                                  title: Text(option, maxLines: 2),
                                  onTap: () => onSelected(option),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    fieldViewBuilder:
                        (context, controller, focusNode, onSubmitted) =>
                            TextField(
                              controller: controller,
                              focusNode: focusNode,
                              textAlignVertical: TextAlignVertical.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface,
                              ),
                              decoration: AppControlMetrics.decoration(
                                context,
                                label: 'Tìm kiếm',
                                icon: Icons.search,
                                hintText: 'Từ khóa tìm kiếm...',
                                suffixIcon: filter.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        onPressed: () {
                                          searchController.clear();
                                          setState(() {
                                            filter = '';
                                            _clientPage = 0;
                                            reload();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              textInputAction: TextInputAction.search,
                              onChanged: _searchAsYouType,
                              onSubmitted: (_) => onSubmitted(),
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResourceDropdowns(ColorScheme colorScheme) {
    switch (widget.resource) {
      case 'students':
        final classes = _references['classes'] ?? [];
        return [
          _buildDropdown<num>(
            label: 'Lớp học',
            icon: Icons.meeting_room_outlined,
            value: _filterClassId,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Tất cả các lớp'),
              ),
              for (final c in classes)
                DropdownMenuItem(
                  value: c['ma_lop'] as num?,
                  child: Text(c['ten_lop']?.toString() ?? 'Lớp ${c['ma_lop']}'),
                ),
            ],
            onChanged: (val) => setState(() {
              _filterClassId = val;
              _clientPage = 0;
              reload();
            }),
          ),
          _buildDropdown<String>(
            label: 'Tình trạng',
            icon: Icons.verified_user_outlined,
            value: _filterStudentStatus,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả tình trạng')),
              DropdownMenuItem(value: 'active', child: Text('Đang theo học')),
              DropdownMenuItem(value: 'inactive', child: Text('Đã ngừng học')),
            ],
            onChanged: (val) => setState(() {
              _filterStudentStatus = val;
              _clientPage = 0;
              reload();
            }),
          ),
        ];

      case 'classes':
        final years = _references['years'] ?? [];
        final teachers = _references['teachers'] ?? [];
        return [
          _buildDropdown<int>(
            label: 'Khối lớp',
            icon: Icons.filter_list_rounded,
            value: _filterGrade,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả các khối')),
              DropdownMenuItem(value: 10, child: Text('Khối 10')),
              DropdownMenuItem(value: 11, child: Text('Khối 11')),
              DropdownMenuItem(value: 12, child: Text('Khối 12')),
            ],
            onChanged: (val) => setState(() {
              _filterGrade = val;
              _clientPage = 0;
              reload();
            }),
          ),
          _buildDropdown<num>(
            label: 'Năm học',
            icon: Icons.calendar_month_outlined,
            value: _filterYearId,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Tất cả năm học'),
              ),
              for (final y in years)
                DropdownMenuItem(
                  value: y['ma_nam_hoc'] as num?,
                  child: Text(y['ten']?.toString() ?? 'Năm ${y['ma_nam_hoc']}'),
                ),
            ],
            onChanged: (val) => setState(() {
              _filterYearId = val;
              _clientPage = 0;
              reload();
            }),
          ),
          _buildDropdown<num>(
            label: 'Giáo viên chủ nhiệm',
            icon: Icons.person_pin_outlined,
            value: _filterTeacherId,
            items: [
              const DropdownMenuItem(value: null, child: Text('Tất cả GVCN')),
              for (final t in teachers)
                DropdownMenuItem(
                  value: t['ma_giao_vien'] as num?,
                  child: Text(
                    t['ho_ten']?.toString() ?? 'GV ${t['ma_giao_vien']}',
                  ),
                ),
            ],
            onChanged: (val) => setState(() {
              _filterTeacherId = val;
              _clientPage = 0;
              reload();
            }),
          ),
        ];

      case 'assignments':
        final classes = _references['classes'] ?? [];
        final subjects = _references['subjects'] ?? [];
        final teachers = _references['teachers'] ?? [];
        final semesters = _references['semesters'] ?? [];
        return [
          _buildDropdown<num>(
            label: 'Lớp học',
            icon: Icons.meeting_room_outlined,
            value: _filterClassId,
            items: [
              const DropdownMenuItem(value: null, child: Text('Tất cả lớp')),
              for (final c in classes)
                DropdownMenuItem(
                  value: c['ma_lop'] as num?,
                  child: Text(c['ten_lop']?.toString() ?? 'Lớp ${c['ma_lop']}'),
                ),
            ],
            onChanged: (val) => setState(() {
              _filterClassId = val;
              _clientPage = 0;
              reload();
            }),
          ),
          _buildDropdown<num>(
            label: 'Môn học',
            icon: Icons.menu_book_outlined,
            value: _filterSubjectId,
            items: [
              const DropdownMenuItem(value: null, child: Text('Tất cả môn')),
              for (final s in subjects)
                DropdownMenuItem(
                  value: s['ma_mon'] as num?,
                  child: Text(s['ten_mon']?.toString() ?? 'Môn ${s['ma_mon']}'),
                ),
            ],
            onChanged: (val) => setState(() {
              _filterSubjectId = val;
              _clientPage = 0;
              reload();
            }),
          ),
          _buildDropdown<num>(
            label: 'Giáo viên',
            icon: Icons.badge_outlined,
            value: _filterTeacherId,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Tất cả giáo viên'),
              ),
              for (final t in teachers)
                DropdownMenuItem(
                  value: t['ma_giao_vien'] as num?,
                  child: Text(
                    t['ho_ten']?.toString() ?? 'GV ${t['ma_giao_vien']}',
                  ),
                ),
            ],
            onChanged: (val) => setState(() {
              _filterTeacherId = val;
              _clientPage = 0;
              reload();
            }),
          ),
          _buildDropdown<num>(
            label: 'Học kỳ',
            icon: Icons.date_range_outlined,
            value: _filterSemesterId,
            items: [
              const DropdownMenuItem(value: null, child: Text('Tất cả học kỳ')),
              for (final sem in semesters)
                DropdownMenuItem(
                  value: sem['ma_hoc_ky'] as num?,
                  child: Text(
                    sem['ten']?.toString() ?? 'HK ${sem['ma_hoc_ky']}',
                  ),
                ),
            ],
            onChanged: (val) => setState(() {
              _filterSemesterId = val;
              _clientPage = 0;
              reload();
            }),
          ),
        ];

      case 'components':
        final subjects = _references['subjects'] ?? [];
        return [
          _buildDropdown<num>(
            label: 'Môn học',
            icon: Icons.menu_book_outlined,
            value: _filterSubjectId,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Tất cả môn học'),
              ),
              for (final s in subjects)
                DropdownMenuItem(
                  value: s['ma_mon'] as num?,
                  child: Text(s['ten_mon']?.toString() ?? 'Môn ${s['ma_mon']}'),
                ),
            ],
            onChanged: (val) => setState(() {
              _filterSubjectId = val;
              _clientPage = 0;
              reload();
            }),
          ),
          _buildDropdown<bool>(
            label: 'Tính chất',
            icon: Icons.percent_outlined,
            value: _filterRequired,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả tính chất')),
              DropdownMenuItem(value: true, child: Text('Bắt buộc')),
              DropdownMenuItem(value: false, child: Text('Tùy chọn')),
            ],
            onChanged: (val) => setState(() {
              _filterRequired = val;
              _clientPage = 0;
              reload();
            }),
          ),
        ];

      case 'accounts':
        return [
          _buildDropdown<String>(
            label: 'Vai trò',
            icon: Icons.manage_accounts_outlined,
            value: _filterRole,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả vai trò')),
              DropdownMenuItem(
                value: 'QUAN_TRI_VIEN',
                child: Text('Quản trị viên'),
              ),
              DropdownMenuItem(value: 'GIAO_VIEN', child: Text('Giáo viên')),
              DropdownMenuItem(value: 'HOC_SINH', child: Text('Học sinh')),
            ],
            onChanged: (val) => setState(() {
              _filterRole = val;
              _clientPage = 0;
              reload();
            }),
          ),
          _buildDropdown<bool>(
            label: 'Trạng thái',
            icon: Icons.lock_open_outlined,
            value: _filterAccountActive,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
              DropdownMenuItem(value: true, child: Text('Đang hoạt động')),
              DropdownMenuItem(value: false, child: Text('Đã khóa')),
            ],
            onChanged: (val) => setState(() {
              _filterAccountActive = val;
              _clientPage = 0;
              reload();
            }),
          ),
        ];

      case 'teachers':
        final teachers = _references['teachers'] ?? [];
        final depts = teachers
            .map((t) => t['to_chuyen_mon']?.toString())
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
        return [
          _buildDropdown<String>(
            label: 'Tổ chuyên môn',
            icon: Icons.badge_outlined,
            value: _filterDepartment,
            items: [
              const DropdownMenuItem(value: null, child: Text('Tất cả tổ')),
              for (final d in depts) DropdownMenuItem(value: d, child: Text(d)),
            ],
            onChanged: (val) => setState(() {
              _filterDepartment = val;
              _clientPage = 0;
              reload();
            }),
          ),
        ];

      case 'semesters':
        final years = _references['years'] ?? [];
        return [
          _buildDropdown<num>(
            label: 'Năm học',
            icon: Icons.calendar_month_outlined,
            value: _filterYearId,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Tất cả năm học'),
              ),
              for (final y in years)
                DropdownMenuItem(
                  value: y['ma_nam_hoc'] as num?,
                  child: Text(y['ten']?.toString() ?? 'Năm ${y['ma_nam_hoc']}'),
                ),
            ],
            onChanged: (val) => setState(() {
              _filterYearId = val;
              _clientPage = 0;
              reload();
            }),
          ),
        ];

      case 'subjects':
        return [
          _buildDropdown<int>(
            label: 'Số tiết / tuần',
            icon: Icons.schedule_outlined,
            value: _filterPeriods,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả số tiết')),
              DropdownMenuItem(value: 1, child: Text('1 tiết / tuần')),
              DropdownMenuItem(value: 2, child: Text('2 tiết / tuần')),
              DropdownMenuItem(value: 3, child: Text('3 tiết / tuần')),
              DropdownMenuItem(value: 4, child: Text('4 tiết / tuần')),
            ],
            onChanged: (val) => setState(() {
              _filterPeriods = val;
              _clientPage = 0;
              reload();
            }),
          ),
        ];

      case 'years':
        return [
          _buildDropdown<bool>(
            label: 'Trạng thái',
            icon: Icons.event_available_outlined,
            value: _filterCurrentYear,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
              DropdownMenuItem(value: true, child: Text('Năm hiện hành')),
              DropdownMenuItem(value: false, child: Text('Năm lưu trữ')),
            ],
            onChanged: (val) => setState(() {
              _filterCurrentYear = val;
              _clientPage = 0;
              reload();
            }),
          ),
        ];

      default:
        return [];
    }
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    double width = 300,
  }) {
    return AppFilterDropdown<T>(
      label: label,
      icon: icon,
      value: value,
      items: items,
      onChanged: onChanged,
      width: width == AppControlMetrics.fieldWidth
          ? AppControlMetrics.responsiveFieldWidth(context)
          : width,
    );
  }

  Widget _buildStudentSortToolbar(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.sort_rounded, size: 16, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                'Sắp xếp:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              _buildSortChip(
                'name',
                'Tên học sinh',
                Icons.person_outline,
                colorScheme,
              ),
              _buildSortChip(
                'class',
                'Lớp',
                Icons.meeting_room_outlined,
                colorScheme,
              ),
              _buildSortChip(
                'status',
                'Tình trạng',
                Icons.check_circle_outline,
                colorScheme,
              ),
            ],
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _sortAscending = !_sortAscending),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(120),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outlineVariant.withAlpha(100),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _sortAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _sortAscending ? 'Tăng dần (A–Z)' : 'Giảm dần (Z–A)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(
    String key,
    String label,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    final isSelected = _studentSortBy == key;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          if (_studentSortBy == key) {
            _sortAscending = !_sortAscending;
          } else {
            _studentSortBy = key;
            _sortAscending = true;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withAlpha(120),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowCard(
    BuildContext context,
    Json row,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final isAccount = spec.key == 'accounts';
    final isStudent = spec.key == 'students';
    final studentId = isStudent ? (row['ma_hoc_sinh'] as num?) : null;
    final classStt =
        (row['stt_lop'] as num?)?.toInt() ??
        (studentId != null ? _studentClassStt[studentId] : null);
    final schoolStt =
        (row['stt_toan_truong'] as num?)?.toInt() ??
        (studentId != null ? _studentSchoolStt[studentId] : null);
    final studentViewer = ref.read(sessionProvider)?.role.value == 'HOC_SINH';
    final showStt = isStudent && (studentViewer || _showsStudentStt);
    final classScope = _showsClassStudentStt;
    final visibleStt = showStt ? (classScope ? classStt : schoolStt) : null;
    final visibleSttLabel = classScope ? 'STT lớp' : 'STT toàn trường';
    final visibleSttShortLabel = classScope ? 'LỚP' : 'TRƯỜNG';
    final sttBackground = classScope
        ? const Color(0xFFE8EAF6)
        : const Color(0xFFE0F2F1);
    final sttBorder = classScope
        ? const Color(0xFF9FA8DA)
        : const Color(0xFF80CBC4);
    final sttForeground = classScope
        ? const Color(0xFF1A237E)
        : const Color(0xFF004D40);

    Widget? badgeWidget;
    if (isAccount) {
      final roleVal = row['role'] as String?;
      final isActive = row['active'] == true;
      badgeWidget = Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (roleVal != null) RoleBadge(role: roleVal, compact: true),
          Text(
            isActive ? 'Hoạt động' : 'Đã khóa',
            style: TextStyle(
              color: isActive ? Colors.green.shade800 : Colors.red.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else if (isStudent) {
      final attending = row['dang_theo_hoc'] == true;
      final className = _extractClassName(row);
      final dob = row['ngay_sinh']?.toString();

      badgeWidget = Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (visibleStt != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: sttBackground,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: sttBorder),
              ),
              child: Text(
                '$visibleSttLabel: #$visibleStt',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: sttForeground,
                ),
              ),
            ),
          if (studentViewer && classStt != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFF9FA8DA)),
              ),
              child: Text(
                'STT lớp: #$classStt',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A237E),
                ),
              ),
            ),
          if (className.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: colorScheme.outlineVariant.withAlpha(80),
                ),
              ),
              child: Text(
                className,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: attending
                  ? const Color(0xFFD5EDE5)
                  : const Color(0xFFFBE4DC),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              attending ? 'Đang theo học' : 'Ngừng theo dõi',
              style: TextStyle(
                color: attending
                    ? const Color(0xFF256848)
                    : const Color(0xFF9B4430),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (dob != null && dob.isNotEmpty)
            Text(
              '· NS: $dob',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
        ],
      );
    } else if (spec.key == 'semester-weights') {
      badgeWidget = Text(
        'Hệ số: ${row['he_so']}',
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      );
    } else if (spec.key == 'components') {
      final isOpen = row['cho_phep_nhap'] != false;
      final weight = row['loai_he_so']?.toString() ?? 'TX';
      badgeWidget = Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: colorScheme.outlineVariant.withAlpha(80),
              ),
            ),
            child: Text(
              'Nhóm $weight · hệ số theo học kỳ',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: isOpen ? const Color(0xFFD5EDE5) : const Color(0xFFFBE4DC),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOpen ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                  size: 11,
                  color: isOpen
                      ? const Color(0xFF256848)
                      : const Color(0xFF9B4430),
                ),
                const SizedBox(width: 3),
                Text(
                  isOpen ? 'Đang mở nhập' : 'Đang khóa nhập',
                  style: TextStyle(
                    color: isOpen
                        ? const Color(0xFF256848)
                        : const Color(0xFF9B4430),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final studentName = row['ho_ten']?.toString() ?? rowLabel(row);
    final titleText = isStudent ? studentName : rowLabel(row);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: isStudent && visibleStt != null
            ? Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sttBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sttBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '#$visibleStt',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: sttForeground,
                      ),
                    ),
                    Text(
                      visibleSttShortLabel,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: sttForeground,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(140),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconForResource(spec.key),
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),

        title: Text(
          titleText,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child:
              badgeWidget ??
              Text(
                'Mã: ${row[spec.id]}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        ),
        onTap: () => edit(row),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (admin && !['accounts', 'students'].contains(spec.key))
              IconButton(
                tooltip: 'Xóa',
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: colorScheme.error,
                ),
                onPressed: () => remove(row),
              ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant.withAlpha(140),
            ),
          ],
        ),
      ),
    );
  }
}
