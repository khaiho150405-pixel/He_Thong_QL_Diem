import 'dart:async';
import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/design_tokens.dart';
import '../../app/widgets/app_avatar.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_controls.dart';
import '../../app/widgets/app_dialog.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/shimmer_loading.dart';
import '../authentication/session.dart';
import '../../core/vietnamese_sort.dart';
import 'academic_year_scope.dart';
import 'repository.dart';
import 'fields.dart';
import 'edit_dialog.dart';
import 'catalog_import_dialog.dart';
import 'student_enrollment_dialogs.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key, required this.resource});
  final String resource;
  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  static const _yearScopedResources = {
    'classes',
    'semesters',
    'students',
    'assignments',
    'semester-weights',
  };

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
  bool _filterActiveInYear = false;

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
      _filterCurrentYear != null ||
      _filterActiveInYear;

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
    final currentClassName = row['currentClassName']?.toString() ?? '';
    if (currentClassName.isNotEmpty) {
      return currentClassName;
    }
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

  Future<List<Json>> _fetchAll(
    String resource, {
    num? yearId,
    num? activeInYearId,
  }) async {
    final items = <Json>[];
    String? cursor;
    final seen = <String>{};
    do {
      final res = await ref
          .read(catalogRepositoryProvider)
          .list(
            resource,
            cursor: cursor,
            yearId: yearId,
            activeInYearId: activeInYearId,
          );
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
    setState(() {
      page = _loadPage();
    });
  }

  Future<CatalogPageData> _loadPage() async {
    num? scopedYearId;
    if (_yearScopedResources.contains(widget.resource)) {
      var viewingYear = ref.read(viewingYearProvider);
      if (viewingYear == null) {
        final current = await ref.read(currentYearProvider.future);
        if (current != null &&
            ref.read(viewingYearProvider) == null &&
            mounted) {
          ref.read(viewingYearProvider.notifier).setYear(current);
        }
        viewingYear = ref.read(viewingYearProvider);
      }
      scopedYearId = viewingYear?.id;
    }

    num? activeInYearId;
    if (widget.resource == 'teachers' && _filterActiveInYear) {
      var viewingYear = ref.read(viewingYearProvider);
      if (viewingYear == null) {
        final current = await ref.read(currentYearProvider.future);
        if (current != null &&
            ref.read(viewingYearProvider) == null &&
            mounted) {
          ref.read(viewingYearProvider.notifier).setYear(current);
        }
        viewingYear = ref.read(viewingYearProvider);
      }
      activeInYearId = viewingYear?.id;
    }

    if (widget.resource == 'students' || _hasActiveFilter) {
      final items = await _fetchAll(
        widget.resource,
        yearId: scopedYearId,
        activeInYearId: activeInYearId,
      );
      if (widget.resource == 'students') {
        _calculateStudentOrders(items);
      }
      return CatalogPageData(items, null);
    } else {
      return ref
          .read(catalogRepositoryProvider)
          .list(
            widget.resource,
            cursor: cursors.last,
            q: filter,
            yearId: scopedYearId,
            activeInYearId: activeInYearId,
          );
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
    _filterActiveInYear = false;
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
        final studentClassId = row['currentClassId'] ?? row['ma_lop'];
        if (_filterClassId != null && studentClassId != _filterClassId) {
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
    if (changed == true && mounted) {
      if (spec.key == 'years') {
        ref.invalidate(academicYearsProvider);
        ref.invalidate(currentYearProvider);
        _references.clear();
        await _loadReferences();
      }
      setState(reload);
    }
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
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Xóa bản ghi chưa sử dụng?',
        confirmLabel: 'Xóa',
        danger: true,
        child: Text(
          'Xóa ${rowLabel(row)}? Dữ liệu đã được tham chiếu sẽ được giữ lại.',
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(catalogRepositoryProvider)
          .remove(spec.key, row[spec.id] as num);
      if (spec.key == 'years') {
        ref.invalidate(academicYearsProvider);
        ref.invalidate(currentYearProvider);
        final currentViewing = ref.read(viewingYearProvider);
        if (currentViewing?.id == row['ma_nam_hoc']) {
          ref.read(viewingYearProvider.notifier).resetToCurrent();
        }
        _references.clear();
        await _loadReferences();
      }
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

    return AppScaffold(
      title: spec.label,
      currentPath: '/catalog/${widget.resource}',
      showBackButton: true,
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          onPressed: () => setState(reload),
          icon: const Icon(Icons.refresh),
        ),
      ],
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: MediaQuery.sizeOf(context).width < 600 ? 8 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Học sinh chỉ nhận đúng hồ sơ của mình từ backend, nên không
                // hiển thị bộ lọc/tìm kiếm không có ý nghĩa cho một bản ghi.
                if (!studentViewer) _buildFilterBar(theme),

                // Student Sort Toolbar
                if (spec.key == 'students' && !studentViewer) ...[
                  const SizedBox(height: 6),
                  _buildStudentSortToolbar(theme),
                ],

                SizedBox(
                  height: MediaQuery.sizeOf(context).width < 600 ? 8 : 16,
                ),

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
                            final statusA = a['dang_theo_hoc'] == true ? 1 : 0;
                            final statusB = b['dang_theo_hoc'] == true ? 1 : 0;
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

                      if (rows.isEmpty) return _buildEmptyResult();
                      return _buildResults(data, rows);
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

  Widget _buildFilterBar(ThemeData theme) {
    final t = context.tokens;
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
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: MediaQuery.sizeOf(context).width < 600 ? 8 : 12,
        ),
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
                    Icon(Icons.filter_alt_rounded, size: 18, color: t.priLink),
                    const SizedBox(width: 8),
                    Text(
                      'Bộ lọc hệ thống',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: t.ink,
                      ),
                    ),
                    if (activeCount > 0) ...[
                      const SizedBox(width: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: t.pri,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Text(
                            '$activeCount đang chọn',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: t.onPri,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_hasActiveFilter)
                  TextButton.icon(
                    onPressed: () => setState(_resetFilters),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Đặt lại bộ lọc'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            SizedBox(height: MediaQuery.sizeOf(context).width < 600 ? 6 : 12),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ..._buildResourceDropdowns(),
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
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          boxShadow: t.pop,
                        ),
                        child: Material(
                          color: t.surface,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            side: BorderSide(color: t.line),
                          ),
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
                                    hoverColor: t.hover,
                                    leading: Icon(
                                      Icons.search,
                                      size: 18,
                                      color: t.ink3,
                                    ),
                                    title: Text(option, maxLines: 2),
                                    onTap: () => onSelected(option),
                                  ),
                              ],
                            ),
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
                              style: TextStyle(fontSize: 13, color: t.ink),
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

  Widget _buildYearScopeControl(List<Json> years) {
    return AcademicYearFilterControl(
      years: years,
      width: 170,
      onChanged: () {
        // setState để FutureBuilder nhận future mới; thiếu setState thì danh sách giữ dữ liệu năm cũ.
        setState(() {
          cursors
            ..clear()
            ..add(null);
          _clientPage = 0;
          reload();
        });
      },
    );
  }

  List<Widget> _buildResourceDropdowns() {
    final years = _references['years'] ?? [];
    switch (widget.resource) {
      case 'students':
        final classes = _references['classes'] ?? [];
        return [
          _buildYearScopeControl(years),
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
        final teachers = _references['teachers'] ?? [];
        final classes = _references['classes'] ?? [];
        final gvcnIds = classes
            .map((c) => c['ma_gv_chu_nhiem'])
            .whereType<num>()
            .toSet();
        final gvcnTeachers = teachers
            .where((t) => gvcnIds.contains(t['ma_giao_vien']))
            .toList();
        final candidateTeachers = gvcnTeachers.isNotEmpty
            ? gvcnTeachers
            : teachers;
        final seenTeacherNames = <String>{};
        final uniqueTeachers = <Json>[];
        for (final t in candidateTeachers) {
          final name = t['ho_ten']?.toString() ?? 'GV ${t['ma_giao_vien']}';
          if (seenTeacherNames.add(name)) {
            uniqueTeachers.add(t);
          }
        }
        return [
          _buildYearScopeControl(years),
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
            label: 'Giáo viên chủ nhiệm',
            icon: Icons.person_pin_outlined,
            value: _filterTeacherId,
            items: [
              const DropdownMenuItem(value: null, child: Text('Tất cả GVCN')),
              for (final t in uniqueTeachers)
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
        final seenTeacherNames = <String>{};
        final uniqueTeachers = <Json>[];
        for (final t in teachers) {
          final name = t['ho_ten']?.toString() ?? 'GV ${t['ma_giao_vien']}';
          if (seenTeacherNames.add(name)) {
            uniqueTeachers.add(t);
          }
        }
        return [
          _buildYearScopeControl(years),
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
              for (final t in uniqueTeachers)
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
        final viewingYear = ref.watch(viewingYearProvider);
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
          _buildDropdown<bool>(
            label: 'Phân công',
            icon: Icons.assignment_ind_outlined,
            value: _filterActiveInYear ? true : null,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Tất cả giáo viên'),
              ),
              DropdownMenuItem(
                value: true,
                child: Text(
                  viewingYear?.name != null && !viewingYear!.isAll
                      ? 'Có phân công năm ${viewingYear.name}'
                      : 'Có phân công trong năm đang xem',
                ),
              ),
            ],
            onChanged: (val) => setState(() {
              _filterActiveInYear = val == true;
              _clientPage = 0;
              cursors
                ..clear()
                ..add(null);
              reload();
            }),
          ),
        ];

      case 'semesters':
        return [_buildYearScopeControl(years)];

      case 'semester-weights':
        return [_buildYearScopeControl(years)];

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

  Widget _buildStudentSortToolbar(ThemeData theme) {
    final t = context.tokens;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: MediaQuery.sizeOf(context).width < 600 ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: t.subtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
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
              Icon(Icons.sort_rounded, size: 16, color: t.priLink),
              const SizedBox(width: 4),
              Text(
                'Sắp xếp:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: t.ink,
                ),
              ),
              const SizedBox(width: 4),
              _buildSortChip('name', 'Tên học sinh', Icons.person_outline),
              _buildSortChip('class', 'Lớp', Icons.meeting_room_outlined),
              _buildSortChip(
                'status',
                'Tình trạng',
                Icons.check_circle_outline,
              ),
            ],
          ),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: () => setState(() => _sortAscending = !_sortAscending),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: t.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _sortAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 14,
                    color: t.priLink,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _sortAscending ? 'Tăng dần (A–Z)' : 'Giảm dần (Z–A)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: t.ink,
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

  Widget _buildSortChip(String key, String label, IconData icon) {
    final t = context.tokens;
    final isSelected = _studentSortBy == key;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
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
          color: isSelected ? t.priSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: isSelected ? t.priLine : t.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? t.priLink : t.ink2),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? t.priLink : t.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResult() {
    final t = context.tokens;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: t.ink3),
          const SizedBox(height: 12),
          Text('Chưa có dữ liệu phù hợp.', style: TextStyle(color: t.ink2)),
          if (_hasActiveFilter) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(_resetFilters),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Xóa bộ lọc'),
            ),
          ],
        ],
      ),
    );
  }

  /// Học sinh, giáo viên và tài khoản hiển thị dạng bảng khi đủ rộng; các tài
  /// nguyên còn lại giữ dạng thẻ.
  bool get _usesTable =>
      const {'students', 'teachers', 'accounts'}.contains(spec.key);

  Widget _buildResults(CatalogPageData data, List<Json> rows) {
    final isClientPaged = data.nextCursor == null;
    const pageSize = 50;
    final totalClientPages = (rows.length / pageSize).ceil();
    final safeClientPage = _clientPage.clamp(
      0,
      (totalClientPages - 1).clamp(0, 9999),
    );
    final displayRows = isClientPaged && rows.length > pageSize
        ? rows.skip(safeClientPage * pageSize).take(pageSize).toList()
        : rows;

    Widget pagination(EdgeInsets padding) => _buildPagination(
      data: data,
      rowCount: rows.length,
      isClientPaged: isClientPaged,
      totalClientPages: totalClientPages,
      safeClientPage: safeClientPage,
      padding: padding,
    );

    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 768;
        if (wide && _usesTable) {
          return _buildTable(
            displayRows,
            pagination(const EdgeInsets.symmetric(vertical: AppSpacing.sm)),
          );
        }
        final theme = Theme.of(context);
        return Column(
          children: [
            Expanded(
              child: wide
                  ? GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 112,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: displayRows.length,
                      itemBuilder: (context, index) =>
                          _buildRowCard(context, displayRows[index], theme),
                    )
                  : ListView.separated(
                      itemCount: displayRows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _buildRowCard(context, displayRows[index], theme),
                    ),
            ),
            pagination(const EdgeInsets.only(bottom: 24)),
          ],
        );
      },
    );
  }

  Widget _buildPagination({
    required CatalogPageData data,
    required int rowCount,
    required bool isClientPaged,
    required int totalClientPages,
    required int safeClientPage,
    required EdgeInsets padding,
  }) {
    final t = context.tokens;
    return Padding(
      padding: padding,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: t.ink2),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (isClientPaged && totalClientPages > 1) ...[
              TextButton(
                onPressed: safeClientPage > 0
                    ? () => setState(() => _clientPage = safeClientPage - 1)
                    : null,
                child: const Text('Trang trước'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Trang ${safeClientPage + 1} / $totalClientPages ($rowCount mục)',
                ),
              ),
              TextButton(
                onPressed: safeClientPage < totalClientPages - 1
                    ? () => setState(() => _clientPage = safeClientPage + 1)
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
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('Trang ${cursors.length} ($rowCount mục)'),
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
    );
  }

  // ---------------------------------------------------------------- Bảng

  Widget _buildTable(List<Json> rows, Widget pagination) {
    final t = context.tokens;
    final columns = _tableColumns(t);
    final radius = BorderRadius.circular(AppRadius.md);
    const minTableWidth = 780.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableBody = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTableHeader(t, columns),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: rows.length,
                itemBuilder: (context, index) => _buildTableRow(
                  t,
                  columns,
                  rows[index],
                  isLast: index == rows.length - 1,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: t.line)),
              ),
              child: pagination,
            ),
          ],
        );

        final content = constraints.maxWidth < minTableWidth
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: minTableWidth,
                  child: tableBody,
                ),
              )
            : tableBody;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: DecoratedBox(
                key: ValueKey('catalog-table-${spec.key}'),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: radius,
                  border: Border.all(color: t.line),
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: content,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        );
      },
    );
  }

  static const _cellPadding = EdgeInsets.symmetric(horizontal: 14);
  static const _cellGap = 12.0;

  Widget _tableCellFrame(_CatalogColumn column, Widget child) {
    final aligned = Align(alignment: Alignment.centerLeft, child: child);
    return column.width != null
        ? SizedBox(width: column.width, child: aligned)
        : Expanded(flex: column.flex, child: aligned);
  }

  List<Widget> _spaced(List<Widget> cells) => [
    for (var i = 0; i < cells.length; i++) ...[
      if (i > 0) const SizedBox(width: _cellGap),
      cells[i],
    ],
  ];

  Widget _buildTableHeader(AppTokens t, List<_CatalogColumn> columns) {
    final style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.36,
      color: t.ink3,
    );
    return DecoratedBox(
      key: const ValueKey('catalog-table-header'),
      decoration: BoxDecoration(
        color: t.subtle,
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Padding(
        padding: _cellPadding.add(const EdgeInsets.symmetric(vertical: 10)),
        child: Row(
          children: _spaced([
            for (final column in columns)
              _tableCellFrame(
                column,
                Text(
                  column.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTableRow(
    AppTokens t,
    List<_CatalogColumn> columns,
    Json row, {
    required bool isLast,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        hoverColor: t.hover,
        onTap: () => edit(row),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: isLast ? null : Border(bottom: BorderSide(color: t.line)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: _cellPadding.add(
                const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Row(
                children: _spaced([
                  for (final column in columns)
                    _tableCellFrame(column, column.builder(row)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameCell(AppTokens t, String name) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppAvatar(name: name, size: AppAvatarSize.sm),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w500, color: t.ink),
        ),
      ),
    ],
  );

  Widget _textCell(AppTokens t, Object? value) {
    final text = value?.toString() ?? '';
    return Text(
      text.isEmpty ? '—' : text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: text.isEmpty ? t.ink3 : t.ink2),
    );
  }

  Widget _actionsCell(AppTokens t, Json row) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (admin && spec.key == 'classes')
        IconButton(
          key: ValueKey('class-promotion-${row['ma_lop']}'),
          tooltip: 'Lên lớp cuối năm',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          icon: Icon(Icons.school_outlined, size: 20, color: t.priLink),
          onPressed: () async {
            await context.push('/admin/classes/${row['ma_lop']}/promotion');
            if (mounted) reload();
          },
        ),
      if (admin && !['accounts', 'students'].contains(spec.key))
        IconButton(
          tooltip: 'Xóa',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          icon: Icon(Icons.delete_outline, size: 20, color: t.bad),
          onPressed: () => remove(row),
        ),
      Icon(Icons.chevron_right, color: t.ink3),
    ],
  );

  double get _actionsWidth {
    if (admin && spec.key == 'classes') return 124;
    return admin && !['accounts', 'students'].contains(spec.key) ? 84 : 24;
  }

  Widget _studentActionsCell(AppTokens t, Json row) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (admin) _buildStudentMenu(t, row),
      Icon(Icons.chevron_right, color: t.ink3),
    ],
  );

  Widget _buildStudentMenu(AppTokens t, Json row) {
    final studentId = row['ma_hoc_sinh'];
    final isAttending = row['dang_theo_hoc'] == true;
    final classes =
        (_references['classes'] ?? <Json>[]).cast<Map<String, dynamic>>();

    return SizedBox(
      width: 40,
      height: 40,
      child: PopupMenuButton<String>(
        key: ValueKey('student-actions-$studentId'),
        tooltip: 'Thao tác học sinh',
        padding: EdgeInsets.zero,
        icon: Icon(Icons.more_vert, size: 20, color: t.ink2),
      onSelected: (val) async {
        switch (val) {
          case 'transfer':
            final result = await showAppDialog<TransferResultDto>(
              context: context,
              builder: (ctx) => StudentTransferDialog(
                student: row,
                api: ref.read(apiProvider),
                allClasses: classes,
              ),
            );
            if (result != null && mounted) {
              if (result.affectedGradebooks.isNotEmpty) {
                await showAffectedGradebooksNotice(
                  context,
                  affectedGradebooks: result.affectedGradebooks,
                );
              }
              reload();
            }
            break;
          case 'withdraw':
            final result = await showAppDialog<EnrollmentResultDto>(
              context: context,
              builder: (ctx) => StudentWithdrawDialog(
                student: row,
                api: ref.read(apiProvider),
              ),
            );
            if (result != null && mounted) {
              reload();
            }
            break;
          case 'reenroll':
            final result = await showAppDialog<EnrollmentResultDto>(
              context: context,
              builder: (ctx) => StudentReenrollDialog(
                student: row,
                api: ref.read(apiProvider),
                allClasses: classes,
              ),
            );
            if (result != null && mounted) {
              reload();
            }
            break;
          case 'history':
            if (mounted) {
              await showAppDialog<void>(
                context: context,
                builder: (ctx) => StudentEnrollmentHistoryDialog(
                  student: row,
                  api: ref.read(apiProvider),
                ),
              );
            }
            break;
        }
      },
      itemBuilder: (context) => [
        if (isAttending) ...[
          PopupMenuItem(
            key: ValueKey('student-transfer-$studentId'),
            value: 'transfer',
            child: const Row(
              children: [
                Icon(Icons.swap_horiz_rounded, size: 18),
                SizedBox(width: 8),
                Text('Chuyển lớp'),
              ],
            ),
          ),
          PopupMenuItem(
            key: ValueKey('student-withdraw-$studentId'),
            value: 'withdraw',
            child: const Row(
              children: [
                Icon(Icons.person_off_outlined, size: 18),
                SizedBox(width: 8),
                Text('Cho nghỉ học'),
              ],
            ),
          ),
        ] else ...[
          PopupMenuItem(
            key: ValueKey('student-reenroll-$studentId'),
            value: 'reenroll',
            child: const Row(
              children: [
                Icon(Icons.person_add_alt_outlined, size: 18),
                SizedBox(width: 8),
                Text('Học lại'),
              ],
            ),
          ),
        ],
        PopupMenuItem(
          key: ValueKey('student-history-$studentId'),
          value: 'history',
          child: const Row(
            children: [
              Icon(Icons.history_rounded, size: 18),
              SizedBox(width: 8),
              Text('Lịch sử xếp lớp'),
            ],
          ),
        ),
      ],
    ),);
  }

  List<_CatalogColumn> _tableColumns(AppTokens t) {
    switch (spec.key) {
      case 'students':
        return [
          if (studentViewer || _showsStudentStt)
            _CatalogColumn('STT', (row) => _studentSttCell(t, row), width: 112),
          _CatalogColumn(
            'Học sinh',
            (row) => _nameCell(t, row['ho_ten']?.toString() ?? rowLabel(row)),
            flex: 4,
          ),
          _CatalogColumn(
            'Lớp',
            (row) => _textCell(t, _extractClassName(row)),
            flex: 2,
          ),
          _CatalogColumn(
            'Ngày sinh',
            (row) => _textCell(t, row['ngay_sinh']),
            flex: 2,
          ),
          _CatalogColumn(
            'Tình trạng',
            (row) => row['dang_theo_hoc'] == true
                ? const AppBadge.ok('Đang theo học')
                : const AppBadge('Ngừng theo dõi'),
            width: 140,
          ),
          _CatalogColumn(
            'Tài khoản',
            (row) => row['ma_nguoi_dung'] != null
                ? const AppBadge.ok('Đã liên kết')
                : const AppBadge('Chưa liên kết'),
            width: 130,
          ),
          _CatalogColumn(
            '',
            (row) => _studentActionsCell(t, row),
            width: admin ? 72 : 24,
          ),
        ];
      case 'teachers':
        return [
          _CatalogColumn(
            'Giáo viên',
            (row) => _nameCell(t, row['ho_ten']?.toString() ?? rowLabel(row)),
            flex: 4,
          ),
          _CatalogColumn(
            'Tổ chuyên môn',
            (row) => _textCell(t, row['to_chuyen_mon']),
            flex: 3,
          ),
          _CatalogColumn('Email', (row) => _textCell(t, row['email']), flex: 4),
          _CatalogColumn(
            'Điện thoại',
            (row) => _textCell(t, row['dien_thoai']),
            width: 120,
          ),
          _CatalogColumn(
            '',
            (row) => _actionsCell(t, row),
            width: _actionsWidth,
          ),
        ];
      default:
        return [
          _CatalogColumn(
            'Tài khoản',
            (row) => Text(
              rowLabel(row),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w600, color: t.ink),
            ),
            flex: 4,
          ),
          _CatalogColumn('Vai trò', (row) {
            final role = row['role'] as String?;
            return role == null ? _textCell(t, null) : _roleBadge(role);
          }, flex: 3),
          _CatalogColumn(
            'Trạng thái',
            (row) => row['active'] == true
                ? const AppBadge.ok('Hoạt động')
                : const AppBadge('Đã khóa'),
            width: 140,
          ),
          _CatalogColumn('', (row) => _actionsCell(t, row), width: 24),
        ];
    }
  }

  Widget _roleBadge(String role) => roleAppBadge(role);

  // ----------------------------------------------------------------- Thẻ

  _Stt _sttOf(Json row) {
    final studentId = row['ma_hoc_sinh'] as num?;
    final classStt =
        (row['stt_lop'] as num?)?.toInt() ??
        (studentId != null ? _studentClassStt[studentId] : null);
    final schoolStt =
        (row['stt_toan_truong'] as num?)?.toInt() ??
        (studentId != null ? _studentSchoolStt[studentId] : null);
    final show = studentViewer || _showsStudentStt;
    final classScope = _showsClassStudentStt;
    return (
      visible: show ? (classScope ? classStt : schoolStt) : null,
      classStt: classStt,
      classScope: classScope,
      show: show,
    );
  }

  (Color, Color, Color) _sttColors(AppTokens t, bool classScope) => classScope
      ? (t.priSoft, t.priLine, t.priLink)
      : (t.okSoft, t.okLine, t.ok);

  Widget _sttPill(String text, (Color, Color, Color) colors) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: colors.$1,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      border: Border.all(color: colors.$2),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: colors.$3,
      ),
    ),
  );

  /// Ô STT của bảng học sinh: số thứ tự đang hiển thị cùng phạm vi (LỚP hoặc
  /// TRƯỜNG). Học sinh xem hồ sơ của mình còn thấy thêm STT lớp.
  Widget _studentSttCell(AppTokens t, Json row) {
    final stt = _sttOf(row);
    if (stt.visible == null && !(studentViewer && stt.classStt != null)) {
      return _textCell(t, null);
    }
    final colors = _sttColors(t, stt.classScope);
    final scopeLabel = stt.classScope ? 'LỚP' : 'TRƯỜNG';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (stt.visible != null)
          _sttPill('#${stt.visible} $scopeLabel', colors),
        if (studentViewer && stt.classStt != null && !stt.classScope) ...[
          if (stt.visible != null) const SizedBox(height: 4),
          _sttPill('#${stt.classStt} LỚP', _sttColors(t, true)),
        ],
      ],
    );
  }

  Widget _buildRowCard(BuildContext context, Json row, ThemeData theme) {
    final t = context.tokens;
    final isAccount = spec.key == 'accounts';
    final isStudent = spec.key == 'students';
    final isTeacher = spec.key == 'teachers';
    final _Stt stt = isStudent
        ? _sttOf(row)
        : (visible: null, classStt: null, classScope: false, show: false);
    final visibleStt = stt.visible;
    final classScope = stt.classScope;
    final classStt = stt.classStt;
    final visibleSttLabel = classScope ? 'STT lớp' : 'STT toàn trường';
    final visibleSttShortLabel = classScope ? 'LỚP' : 'TRƯỜNG';
    final sttColors = _sttColors(t, classScope);

    Widget? badgeWidget;
    if (isAccount) {
      final roleVal = row['role'] as String?;
      final isActive = row['active'] == true;
      badgeWidget = Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (roleVal != null) _roleBadge(roleVal),
          isActive ? const AppBadge.ok('Hoạt động') : const AppBadge('Đã khóa'),
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
            _sttPill('$visibleSttLabel: #$visibleStt', sttColors),
          if (studentViewer && classStt != null)
            _sttPill('STT lớp: #$classStt', _sttColors(t, true)),
          if (className.isNotEmpty) AppBadge(className, dot: false),
          attending
              ? const AppBadge.ok('Đang theo học')
              : const AppBadge('Ngừng theo dõi'),
          if (dob != null && dob.isNotEmpty)
            Text('· NS: $dob', style: TextStyle(color: t.ink3, fontSize: 12)),
        ],
      );
    } else if (spec.key == 'semester-weights') {
      badgeWidget = Text(
        'Hệ số: ${row['he_so']}',
        style: TextStyle(color: t.priLink, fontWeight: FontWeight.w700),
      );
    } else if (spec.key == 'components') {
      final isOpen = row['cho_phep_nhap'] != false;
      final weight = row['loai_he_so']?.toString() ?? 'TX';
      badgeWidget = Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppBadge('Nhóm $weight · hệ số theo học kỳ', dot: false),
          isOpen
              ? const AppBadge.ok('Đang mở nhập')
              : const AppBadge.warn('Đang khóa nhập'),
        ],
      );
    }

    final studentName = row['ho_ten']?.toString() ?? rowLabel(row);
    final titleText = isStudent ? studentName : rowLabel(row);

    Widget leading;
    if (isStudent && visibleStt != null) {
      leading = Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sttColors.$1,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: sttColors.$2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '#$visibleStt',
              style: TextStyle(
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: sttColors.$3,
              ),
            ),
            Text(
              visibleSttShortLabel,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontSize: 8,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: sttColors.$3,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    } else if (isStudent || isTeacher) {
      leading = AppAvatar(name: titleText);
    } else {
      leading = Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: t.subtle,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: t.line),
        ),
        child: Icon(_iconForResource(spec.key), size: 20, color: t.priLink),
      );
    }

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        hoverColor: t.hover,
        leading: leading,
        title: Text(
          titleText,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: t.ink,
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
                style: theme.textTheme.bodySmall?.copyWith(color: t.ink3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        ),
        onTap: () => edit(row),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (admin && spec.key == 'classes')
              IconButton(
                key: ValueKey('class-promotion-${row['ma_lop']}'),
                tooltip: 'Lên lớp cuối năm',
                icon: Icon(Icons.school_outlined, size: 20, color: t.priLink),
                onPressed: () async {
                  await context.push('/admin/classes/${row['ma_lop']}/promotion');
                  if (mounted) reload();
                },
              ),
            if (admin && spec.key == 'students')
              _buildStudentMenu(t, row),
            if (admin && !['accounts', 'students'].contains(spec.key))
              IconButton(
                tooltip: 'Xóa',
                icon: Icon(Icons.delete_outline, size: 20, color: t.bad),
                onPressed: () => remove(row),
              ),
            Icon(Icons.chevron_right, color: t.ink3),
          ],
        ),
      ),
    );
  }
}

/// Một cột của bảng danh mục: nhãn tiêu đề, độ rộng (cố định hoặc theo `flex`)
/// và hàm dựng ô từ một dòng dữ liệu.
class _CatalogColumn {
  const _CatalogColumn(this.label, this.builder, {this.flex = 1, this.width});

  final String label;
  final Widget Function(Json row) builder;
  final int flex;
  final double? width;
}

typedef _Stt = ({int? visible, int? classStt, bool classScope, bool show});
