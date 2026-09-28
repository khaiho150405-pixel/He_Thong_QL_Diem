import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
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
  int _selectedDay = 2; // Thứ 2 default, or current weekday
  num? _selectedClassId;
  num? _selectedTeacherId;
  num? _selectedSemesterId;
  List<Json> _classes = [];
  List<Json> _teachers = [];
  List<Json> _semesters = [];
  List<Json> _assignments = [];
  bool _loadingMeta = true;

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
    final role = ref.read(sessionProvider)?.role.value;
    if (role == 'QUAN_TRI_VIEN') {
      try {
        final classesRes = await ref
            .read(catalogRepositoryProvider)
            .list('classes');
        final teachersRes = await ref
            .read(catalogRepositoryProvider)
            .list('teachers');
        final semestersRes = await ref
            .read(catalogRepositoryProvider)
            .list('semesters');
        final assignmentsRes = await ref
            .read(catalogRepositoryProvider)
            .list('assignments');
        if (mounted) {
          setState(() {
            _classes = classesRes.items;
            _teachers = teachersRes.items;
            _semesters = semestersRes.items;
            _assignments = assignmentsRes.items;
            _loadingMeta = false;
          });
          _loadTimetable();
        }
      } catch (_) {
        if (mounted) setState(() => _loadingMeta = false);
      }
    } else {
      if (mounted) setState(() => _loadingMeta = false);
    }
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

  Future<void> _showEditor([TimetableItem? item]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => TimetableEditDialog(
        assignments: _assignments,
        item: item,
        repository: ref.read(timetableRepositoryProvider),
      ),
    );
    if (saved == true) _loadTimetable();
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

    return Scaffold(
      backgroundColor: AppTheme.warmIvoryBg,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (role == 'QUAN_TRI_VIEN')
            IconButton(
              tooltip: 'Thêm tiết học',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _assignments.isEmpty ? null : () => _showEditor(),
            ),
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh),
            onPressed: _loadTimetable,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    padding: const EdgeInsets.all(16),
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

                        const SizedBox(height: 14),

                        // Filters & Controls Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
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
                                    onChanged: (v) {
                                      setState(() {
                                        _selectedClassId = v;
                                      });
                                      _loadTimetable();
                                    },
                                  ),
                                  AppFilterDropdown<num>(
                                    label: 'Giáo viên',
                                    icon: Icons.badge_outlined,
                                    value: _selectedTeacherId,
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
                                    onChanged: (v) {
                                      setState(() {
                                        _selectedTeacherId = v;
                                      });
                                      _loadTimetable();
                                    },
                                  ),
                                  AppFilterDropdown<num>(
                                    label: 'Học kỳ',
                                    icon: Icons.calendar_month_outlined,
                                    value: _selectedSemesterId,
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
                                ],
                              ],

                              // View Mode Toggle (Grid vs Day List)
                              SizedBox(
                                height: AppControlMetrics.height,
                                child: SegmentedButton<bool>(
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
                                  style: const ButtonStyle(
                                    visualDensity: VisualDensity.compact,
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

                const SizedBox(height: 14),

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
      final byClass = <int, List<TimetableItem>>{};
      for (final item in items) {
        byClass.putIfAbsent(item.maLop, () => []).add(item);
      }
      final groups = byClass.entries.toList()
        ..sort((a, b) => a.value.first.tenLop.compareTo(b.value.first.tenLop));
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
                        'Lớp ${group.value.first.tenLop}',
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
    // Map items by [thu][tiet]
    final matrix = <int, Map<int, List<TimetableItem>>>{};
    for (var thu = 2; thu <= 8; thu++) {
      matrix[thu] = {};
    }
    for (final item in items) {
      matrix.putIfAbsent(item.thu, () => {});
      matrix[item.thu]!.putIfAbsent(item.tiet, () => []).add(item);
    }

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
            columnSpacing: 14,
            horizontalMargin: 14,
            headingRowHeight: 46,
            dataRowMinHeight: 72,
            dataRowMaxHeight: 120,
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
              const DataColumn(
                label: Text(
                  'Tiết',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              for (final d in days)
                DataColumn(
                  label: Text(
                    dayNames[d]!,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
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
                                  fontSize: 11,
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
                                fontSize: 9.5,
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
    ColorScheme colorScheme,
  ) {
    if (cellItems.isEmpty) {
      return const SizedBox(
        width: 140,
        child: Text('—', style: TextStyle(color: Colors.grey)),
      );
    }

    final item = cellItems.first;
    final subColor = _getSubjectColor(item.tenMon);
    final subBg = _getSubjectBgColor(item.tenMon);

    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      margin: const EdgeInsets.symmetric(vertical: 4),
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
              fontSize: 12,
              color: subColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            role == 'HOC_SINH' ? item.tenGiaoVien : item.tenLop,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.phongHoc != null && item.phongHoc!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.phongHoc!,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: subColor,
                ),
              ),
            ),
          ],
          if (cellItems.length > 1) ...[
            const SizedBox(height: 2),
            Text(
              '+ ${cellItems.length - 1} lớp khác',
              style: TextStyle(fontSize: 9.5, color: subColor),
            ),
          ],
        ],
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
                            if (item.phongHoc != null &&
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
                                onPressed: () => _showEditor(item),
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
