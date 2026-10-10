import '../../app/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/widgets/app_controls.dart';
import '../../app/widgets/role_badge.dart';
import '../../app/widgets/shimmer_loading.dart';
import '../academic_catalog/repository.dart';
import '../authentication/session.dart';
import 'timetable_model.dart';
import 'timetable_edit_dialog.dart';
import 'timetable_repository.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  bool _isWeeklyView = true;
  bool _groupByRoom = false;
  int _selectedDay = 2; // Thứ 2 default, or current weekday
  num? _selectedClassId;
  num? _selectedTeacherId;
  num? _selectedSemesterId;
  List<Json> _classes = [];
  List<Json> _teachers = [];
  List<Json> _semesters = [];
  List<Json> _assignments = [];
  bool _loadingMeta = true;
  String? _metadataError;

  late Future<List<TimetableItem>> _timetableFuture;

  @override
  void initState() {
    super.initState();
    // Highlight today's weekday
    final nowWeekday = DateTime.now().weekday; // 1 = Monday, ..., 7 = Sunday
    _selectedDay = nowWeekday + 1; // 2 = Thứ Hai, ..., 8 = Chủ nhật
    _loadMetadata();
    _loadTimetable();
  }

  Future<void> _loadMetadata() async {
    if (mounted) {
      setState(() {
        _loadingMeta = true;
        _metadataError = null;
      });
    }
    final role = ref.read(sessionProvider)?.role.value;
    if (role == 'QUAN_TRI_VIEN') {
      try {
        final classesRes = await _allMetadata('classes');
        final teachersRes = await _allMetadata('teachers');
        final semestersRes = await _allMetadata('semesters');
        final assignmentsRes = await _allMetadata('assignments');
        if (mounted) {
          setState(() {
            _classes = classesRes;
            _teachers = teachersRes;
            _semesters = semestersRes;
            _assignments = assignmentsRes;
            _loadingMeta = false;
          });
          _loadTimetable();
        }
      } catch (error) {
        if (mounted) {
          setState(() {
            _loadingMeta = false;
            _metadataError = errorMessage(error);
          });
        }
      }
    } else {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  Future<List<Json>> _allMetadata(String resource) async {
    final items = <Json>[];
    String? cursor;
    final seen = <String>{};
    do {
      final page = await ref
          .read(catalogRepositoryProvider)
          .list(resource, cursor: cursor);
      items.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor != null && !seen.add(cursor)) {
        throw StateError('Không tải được đầy đủ danh mục.');
      }
    } while (cursor != null);
    return items;
  }

  void _loadTimetable() {
    setState(() {
      _timetableFuture = ref
          .read(timetableRepositoryProvider)
          .getTimetable(
            classId: _selectedClassId,
            teacherId: _selectedTeacherId,
            semesterId: _selectedSemesterId,
          );
    });
  }

  Future<void> _showEditor({
    TimetableItem? item,
    int? day,
    int? period,
    num? classId,
    bool moving = false,
  }) async {
    final targetClass = item?.maLop ?? classId ?? _selectedClassId;
    final targetTerm = item?.maHocKy ?? _selectedSemesterId;
    final assignments = _assignments
        .where(
          (row) =>
              (targetClass == null || row['ma_lop'] == targetClass) &&
              (targetTerm == null || row['ma_hoc_ky'] == targetTerm),
        )
        .toList();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TimetableEditDialog(
        assignments: assignments,
        item: item,
        repository: ref.read(timetableRepositoryProvider),
        initialDay: day ?? _selectedDay,
        initialPeriod: period,
        moving: moving,
      ),
    );
    if (saved == true && mounted) _loadTimetable();
  }

  Future<void> _showSlotActions(List<TimetableItem> items) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .65,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sắp xếp tiết học',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final item in items)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.tenMon,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${item.tenLop} · ${item.tenGiaoVien}\n${item.thuLabel} · Tiết ${item.tiet}${item.phongHoc == null ? '' : ' · ${item.phongHoc}'}',
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _assignments.isEmpty
                                  ? null
                                  : () {
                                      Navigator.pop(sheetContext);
                                      _showEditor(item: item);
                                    },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Sửa môn / giáo viên'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _assignments.isEmpty
                                  ? null
                                  : () {
                                      Navigator.pop(sheetContext);
                                      _showEditor(item: item, moving: true);
                                    },
                              icon: const Icon(Icons.swap_horiz),
                              label: const Text('Chuyển ngày / tiết'),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                _deleteItem(item);
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Xóa khỏi lịch'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteItem(TimetableItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tiết học?'),
        content: Text(
          '${item.tenMon} · ${item.tenLop} · ${item.thuLabel}, tiết ${item.tiet}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(timetableRepositoryProvider).deleteItem(item.maTietHoc);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa tiết học.')));
      _loadTimetable();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
    }
  }

  Color _getSubjectColor(String subjectName) {
    final name = subjectName.toLowerCase();
    if (name.contains('toán')) return const Color(0xFF1565C0);
    if (name.contains('văn')) return const Color(0xFFC2185B);
    if (name.contains('anh')) return const Color(0xFF2E7D32);
    if (name.contains('lí') || name.contains('lý')) {
      return const Color(0xFF512DA8);
    }
    if (name.contains('hóa')) return const Color(0xFFE65100);
    if (name.contains('sinh')) return const Color(0xFF00695C);
    if (name.contains('sử') || name.contains('địa')) {
      return const Color(0xFF6D4C41);
    }
    return const Color(0xFF37474F);
  }

  Color _getSubjectBgColor(String subjectName) {
    final name = subjectName.toLowerCase();
    if (name.contains('toán')) return const Color(0xFFE3F2FD);
    if (name.contains('văn')) return const Color(0xFFFCE4EC);
    if (name.contains('anh')) return const Color(0xFFE8F5E9);
    if (name.contains('lí') || name.contains('lý')) {
      return const Color(0xFFEDE7F6);
    }
    if (name.contains('hóa')) return const Color(0xFFFFF3E0);
    if (name.contains('sinh')) return const Color(0xFFE0F2F1);
    if (name.contains('sử') || name.contains('địa')) {
      return const Color(0xFFEFEBE9);
    }
    return const Color(0xFFECEFF1);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider);
    final role = user?.role.value ?? '';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    String title;
    String subtitle;
    if (role == 'QUAN_TRI_VIEN') {
      title = 'Thời khóa biểu toàn trường';
      subtitle =
          'Quản lý và tra cứu lịch học các lớp, lịch giảng dạy giáo viên';
    } else if (role == 'GIAO_VIEN') {
      title = 'Lịch giảng dạy bộ môn';
      subtitle =
          'Lịch các tiết dạy trong tuần của thầy/cô tại các lớp phụ trách';
    } else {
      title = 'Thời khóa biểu của tôi';
      subtitle = 'Lịch học các môn trong tuần của lớp';
    }

    return AppScaffold(
      title: title,
      currentPath: '/timetable',
      showBackButton: true,
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          icon: const Icon(Icons.refresh),
          onPressed: () {
            _loadMetadata();
            _loadTimetable();
          },
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 16,
              vertical: isMobile ? 8 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Banner
                Card(
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withAlpha(80),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 10 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.calendar_today_rounded,
                                color: colorScheme.onPrimaryContainer,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: RoleBadge(
                                          role: role,
                                          compact: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (isMobile) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<bool>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(
                                  value: true,
                                  icon: Icon(Icons.grid_view_rounded, size: 16),
                                  label: Text('Lưới tuần'),
                                ),
                                ButtonSegment(
                                  value: false,
                                  icon: Icon(
                                    Icons.view_agenda_rounded,
                                    size: 16,
                                  ),
                                  label: Text('Theo ngày'),
                                ),
                              ],
                              selected: {_isWeeklyView},
                              onSelectionChanged: (set) {
                                setState(() => _isWeeklyView = set.first);
                              },
                              style: SegmentedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),

                        // Filters & Controls Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.only(top: 10, bottom: 6),
                          child: Wrap(
                            spacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Admin Class/Teacher Filter
                              if (role == 'QUAN_TRI_VIEN') ...[
                                if (_loadingMeta)
                                  const SizedBox(
                                    width: 120,
                                    child: LinearProgressIndicator(),
                                  )
                                else ...[
                                  AppFilterDropdown<num>(
                                    label: 'Lớp học',
                                    icon: Icons.meeting_room_outlined,
                                    value: _selectedClassId,
                                    width: 170,
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Tất cả lớp'),
                                      ),
                                      for (final c in _classes)
                                        DropdownMenuItem(
                                          value: c['ma_lop'] as num?,
                                          child: Text(
                                            c['ten_lop']?.toString() ?? 'Lớp',
                                          ),
                                        ),
                                    ],
                                    onChanged: (value) {
                                      setState(() => _selectedClassId = value);
                                      _loadTimetable();
                                    },
                                  ),
                                  AppFilterDropdown<num>(
                                    label: 'Giáo viên',
                                    icon: Icons.badge_outlined,
                                    value: _selectedTeacherId,
                                    width: 200,
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Tất cả giáo viên'),
                                      ),
                                      for (final t in _teachers)
                                        DropdownMenuItem(
                                          value: t['ma_giao_vien'] as num?,
                                          child: Text(
                                            t['ho_ten']?.toString() ?? 'GV',
                                          ),
                                        ),
                                    ],
                                    onChanged: (value) {
                                      setState(
                                        () => _selectedTeacherId = value,
                                      );
                                      _loadTimetable();
                                    },
                                  ),
                                  AppFilterDropdown<num>(
                                    label: 'Học kỳ',
                                    icon: Icons.calendar_month_outlined,
                                    value: _selectedSemesterId,
                                    width: 205,
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Học kỳ hiện hành'),
                                      ),
                                      for (final semester in _semesters)
                                        DropdownMenuItem(
                                          value: semester['ma_hoc_ky'] as num?,
                                          child: Text(
                                            semester['ten']?.toString() ??
                                                'Học kỳ',
                                          ),
                                        ),
                                    ],
                                    onChanged: (value) {
                                      setState(
                                        () => _selectedSemesterId = value,
                                      );
                                      _loadTimetable();
                                    },
                                  ),
                                  AppFilterDropdown<bool>(
                                    label: 'Hiển thị lịch theo',
                                    icon: Icons.layers_outlined,
                                    value: _groupByRoom,
                                    width: 180,
                                    items: const [
                                      DropdownMenuItem(
                                        value: false,
                                        child: Text('Lớp học'),
                                      ),
                                      DropdownMenuItem(
                                        value: true,
                                        child: Text('Phòng học'),
                                      ),
                                    ],
                                    onChanged: (v) => setState(
                                      () => _groupByRoom = v ?? false,
                                    ),
                                  ),
                                ],
                              ],
                              if (role == 'QUAN_TRI_VIEN') ...[
                                FilledButton.icon(
                                  onPressed:
                                      _loadingMeta || _assignments.isEmpty
                                      ? null
                                      : () => _showEditor(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Thêm môn vào lịch'),
                                ),
                                if (_metadataError != null)
                                  Text(
                                    'Không tải được phân công: $_metadataError',
                                  ),
                                if (!_loadingMeta &&
                                    _metadataError == null &&
                                    _assignments.isEmpty)
                                  const Text(
                                    'Tạo phân công giảng dạy trước khi xếp lịch.',
                                  ),
                                const Text(
                                  'Ô trống: thêm môn · Ô có môn: sửa, chuyển hoặc xóa',
                                ),
                              ],
                              // View Mode Toggle (Grid vs Day List)
                              if (!isMobile)
                                SizedBox(
                                  width: 280,
                                  child: SegmentedButton<bool>(
                                    showSelectedIcon: false,
                                    segments: const [
                                      ButtonSegment(
                                        value: true,
                                        icon: Icon(
                                          Icons.grid_view_rounded,
                                          size: 16,
                                        ),
                                        label: Text('Lưới tuần'),
                                      ),
                                      ButtonSegment(
                                        value: false,
                                        icon: Icon(
                                          Icons.view_agenda_rounded,
                                          size: 16,
                                        ),
                                        label: Text('Theo ngày'),
                                      ),
                                    ],
                                    selected: {_isWeeklyView},
                                    onSelectionChanged: (set) {
                                      setState(() => _isWeeklyView = set.first);
                                    },
                                    style: SegmentedButton.styleFrom(
                                      minimumSize: const Size(120, 48),
                                      visualDensity: VisualDensity.standard,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isMobile ? 8 : 14),

                // Main Content
                Expanded(
                  child: FutureBuilder<List<TimetableItem>>(
                    future: _timetableFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const ShimmerLoading(
                          itemCount: 6,
                          itemHeight: 80,
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 40,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 10),
                              Text('Lỗi: ${snapshot.error}'),
                              const SizedBox(height: 10),
                              FilledButton.tonal(
                                onPressed: _loadTimetable,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        );
                      }

                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_busy_outlined,
                                size: 48,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Chưa có dữ liệu thời khóa biểu',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Thời khóa biểu cho phạm vi này hiện chưa được xếp lịch.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return _isWeeklyView
                          ? _buildWeeklyGrid(items, role, colorScheme, theme)
                          : _buildDayAgenda(items, role, colorScheme, theme);
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

  // ── 1. WEEKLY GRID VIEW ───────────────────────────────────────────────────
  Widget _buildWeeklyGrid(
    List<TimetableItem> items,
    String role,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final isWholeSchool =
        role == 'QUAN_TRI_VIEN' &&
        _selectedClassId == null &&
        _selectedTeacherId == null;
    if (isWholeSchool) {
      final byClass = <String, List<TimetableItem>>{};
      for (final item in items) {
        final groupKey = _groupByRoom
            ? (item.phongHoc?.trim().isNotEmpty == true
                  ? item.phongHoc!
                  : 'Chưa có phòng')
            : item.tenLop;
        byClass.putIfAbsent(groupKey, () => []).add(item);
      }
      final groups = byClass.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      return ListView.separated(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: groups.length,
        separatorBuilder: (_, _) => const SizedBox(height: 18),
        itemBuilder: (context, index) {
          final group = groups[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.meeting_room_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_groupByRoom ? 'Phòng' : 'Lớp'} ${group.key}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${group.value.length} tiết',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _buildWeeklyGridTable(group.value, role, colorScheme),
            ],
          );
        },
      );
    }
    return SingleChildScrollView(
      key: const ValueKey('timetable-weekly-vertical-scroll'),
      primary: true,
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildWeeklyGridTable(items, role, colorScheme),
    );
  }

  Widget _buildWeeklyGridTable(
    List<TimetableItem> items,
    String role,
    ColorScheme colorScheme,
  ) {
    final slotClassId =
        _selectedClassId ??
        (!_groupByRoom && items.isNotEmpty ? items.first.maLop : null);
    // Map items by [thu][tiet]
    final matrix = <int, Map<int, List<TimetableItem>>>{};
    for (var thu = 2; thu <= 8; thu++) {
      matrix[thu] = {};
    }
    for (final item in items) {
      matrix.putIfAbsent(item.thu, () => {});
      matrix[item.thu]!.putIfAbsent(item.tiet, () => []).add(item);
    }

    final isMobile = MediaQuery.sizeOf(context).width < 600;
    const days = [2, 3, 4, 5, 6, 7, 8];
    final dayNames = isMobile
        ? {2: 'T2', 3: 'T3', 4: 'T4', 5: 'T5', 6: 'T6', 7: 'T7', 8: 'CN'}
        : {
            2: 'Thứ Hai',
            3: 'Thứ Ba',
            4: 'Thứ Tư',
            5: 'Thứ Năm',
            6: 'Thứ Sáu',
            7: 'Thứ Bảy',
            8: 'Chủ nhật',
          };

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: isMobile ? 6 : 14,
            horizontalMargin: isMobile ? 6 : 14,
            headingRowHeight: isMobile ? 40 : 46,
            dataRowMinHeight: isMobile ? 64 : 72,
            dataRowMaxHeight: isMobile ? 104 : 120,
            headingRowColor: WidgetStatePropertyAll(
              colorScheme.surfaceContainerHighest.withAlpha(120),
            ),
            border: TableBorder(
              horizontalInside: BorderSide(
                color: colorScheme.outlineVariant.withAlpha(40),
              ),
              verticalInside: BorderSide(
                color: colorScheme.outlineVariant.withAlpha(40),
              ),
            ),
            columns: [
              DataColumn(
                label: Text(
                  'Tiết',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 12 : 13,
                  ),
                ),
              ),
              for (final d in days)
                DataColumn(
                  label: Text(
                    dayNames[d]!,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 12 : 13,
                      color: d == _selectedDay ? colorScheme.primary : null,
                    ),
                  ),
                ),
            ],
            rows: [
              for (var tiet = 1; tiet <= 10; tiet++)
                DataRow(
                  cells: [
                    // Period column
                    DataCell(
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 6 : 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tiet <= 5
                                    ? colorScheme.primaryContainer
                                    : colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'T$tiet',
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 11,
                                  fontWeight: FontWeight.w800,
                                  color: tiet <= 5
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tiet <= 5 ? 'Sáng' : 'Chiều',
                              style: TextStyle(
                                fontSize: isMobile ? 8.5 : 9.5,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Day columns
                    for (final d in days)
                      DataCell(
                        _buildGridCell(
                          matrix[d]?[tiet] ?? [],
                          role,
                          colorScheme,
                          day: d,
                          period: tiet,
                          classId: slotClassId,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCell(
    List<TimetableItem> cellItems,
    String role,
    ColorScheme colorScheme, {
    required int day,
    required int period,
    num? classId,
  }) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final cellWidth = isMobile ? 102.0 : 140.0;

    if (cellItems.isEmpty) {
      if (role == 'QUAN_TRI_VIEN') {
        return SizedBox(
          width: cellWidth,
          child: OutlinedButton.icon(
            key: ValueKey('add-slot-$classId-$day-$period'),
            onPressed: _loadingMeta || _assignments.isEmpty
                ? null
                : () => _showEditor(day: day, period: period, classId: classId),
            icon: Icon(Icons.add, size: isMobile ? 13 : 16),
            label: Text(
              isMobile ? 'Thêm' : 'Thêm môn',
              style: TextStyle(fontSize: isMobile ? 10.5 : 12),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 4 : 8,
                vertical: isMobile ? 2 : 6,
              ),
            ),
          ),
        );
      }
      return SizedBox(
        width: cellWidth,
        child: const Center(
          child: Text('—', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final item = cellItems.first;
    final subColor = _getSubjectColor(item.tenMon);
    final subBg = _getSubjectBgColor(item.tenMon);

    return Tooltip(
      message: cellItems
          .map((i) => '${i.tenMon} · ${i.tenLop} · ${i.tenGiaoVien}')
          .join('\n'),
      child: InkWell(
        onTap: role == 'QUAN_TRI_VIEN'
            ? () => _showSlotActions(cellItems)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: cellWidth,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 5 : 8,
            vertical: isMobile ? 4 : 6,
          ),
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: subBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: subColor.withAlpha(90)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.tenMon,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isMobile ? 11 : 12,
                  color: subColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                role == 'HOC_SINH' ? item.tenGiaoVien : item.tenLop,
                style: TextStyle(
                  fontSize: isMobile ? 9.5 : 10.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (role != 'HOC_SINH' &&
                  item.phongHoc != null &&
                  item.phongHoc!.isNotEmpty) ...[
                const SizedBox(height: 1),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.phongHoc!,
                    style: TextStyle(
                      fontSize: isMobile ? 8.5 : 9,
                      fontWeight: FontWeight.w700,
                      color: subColor,
                    ),
                  ),
                ),
              ],
              if (cellItems.length > 1) ...[
                const SizedBox(height: 1),
                Text(
                  '+ ${cellItems.length - 1} lớp khác',
                  style: TextStyle(
                    fontSize: isMobile ? 8.5 : 9.5,
                    color: subColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── 2. DAY-BY-DAY AGENDA VIEW ─────────────────────────────────────────────
  Widget _buildDayAgenda(
    List<TimetableItem> allItems,
    String role,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    const days = [2, 3, 4, 5, 6, 7, 8];
    final dayNames = {
      2: 'Thứ Hai',
      3: 'Thứ Ba',
      4: 'Thứ Tư',
      5: 'Thứ Năm',
      6: 'Thứ Sáu',
      7: 'Thứ Bảy',
      8: 'Chủ nhật',
    };

    final dayItems = allItems.where((i) => i.thu == _selectedDay).toList()
      ..sort((a, b) => a.tiet.compareTo(b.tiet));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Day selector tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final d in days)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(dayNames[d]!),
                    selected: _selectedDay == d,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedDay = d);
                    },
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: dayItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.weekend_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Không có tiết học vào ${dayNames[_selectedDay]}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: dayItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = dayItems[index];
                    final subColor = _getSubjectColor(item.tenMon);
                    final subBg = _getSubjectBgColor(item.tenMon);

                    return Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withAlpha(80),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Period indicator
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: subBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: subColor.withAlpha(90),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'T${item.tiet}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: subColor,
                                    ),
                                  ),
                                  Text(
                                    item.tiet <= 5 ? 'Sáng' : 'Chiều',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: subColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.tenMon,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          item.timeSlotLabel,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Lớp: ${item.tenLop} · GV: ${item.tenGiaoVien}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (item.ghiChu != null &&
                                      item.ghiChu!.isNotEmpty)
                                    Text(
                                      'Nội dung: ${item.ghiChu}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (role != 'HOC_SINH' &&
                                item.phongHoc != null &&
                                item.phongHoc!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: subBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.room_outlined,
                                      size: 13,
                                      color: subColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.phongHoc!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: subColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (role == 'QUAN_TRI_VIEN') ...[
                              const SizedBox(width: 4),
                              IconButton(
                                tooltip: 'Sửa tiết học',
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showEditor(item: item),
                              ),
                              IconButton(
                                tooltip: 'Xóa tiết học',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                ),
                                color: colorScheme.error,
                                onPressed: () => _deleteItem(item),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
