import '../../app/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_controls.dart';
import '../../app/widgets/app_dialog.dart';
import '../../app/widgets/app_tabs.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/shimmer_loading.dart';
import '../academic_catalog/repository.dart';
import '../authentication/session.dart';
import 'timetable_model.dart';
import 'timetable_edit_dialog.dart';
import 'mobile/timetable_mobile_view.dart';
import 'timetable_repository.dart';
import 'timetable_slot_group.dart';
import 'timetable_week.dart';
import 'web/timetable_block.dart';
import 'web/timetable_toolbar.dart';
import 'web/timetable_week_board.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  /// [today] chỉ để test cố định ngày; mặc định lấy giờ thiết bị.
  const TimetableScreen({super.key, this.today});

  final DateTime? today;

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  bool _isWeeklyView = true;
  bool _groupByRoom = false;
  bool _byPeriod = false; // QTV: lưới chi tiết từng tiết thay vì theo buổi
  String? _studentClass;
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

  late Future<TimetableResult> _timetableFuture;

  // Tuần đang xem (thứ Hai) và học kỳ của danh sách; đặt khi dữ liệu về.
  DateTime? _weekStart;
  TimetableSemester? _semester;
  num? _weekSemesterId;
  final _mobile = TimetableMobileController();

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  DateTime get _today => dateOnly(widget.today ?? DateTime.now());

  @override
  void initState() {
    super.initState();
    final nowWeekday = _today.weekday; // 1 = Monday, ..., 7 = Sunday
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
          )
          .then((result) {
            final adopted = _adoptWeek(result);
            // Thanh công cụ nằm ngoài FutureBuilder: cần dựng lại khi có tuần/học kỳ.
            if (mounted) setState(() {});
            return adopted;
          });
    });
  }

  /// Về tuần mặc định khi lần đầu có dữ liệu hoặc học kỳ đổi; tải lại sau khi
  /// sửa/xóa tiết thì giữ nguyên tuần đang xem.
  TimetableResult _adoptWeek(TimetableResult result) {
    _semester = result.semester;
    _studentClass = result.items.isEmpty ? null : result.items.first.tenLop;
    if (_weekStart == null || result.semester?.id != _weekSemesterId) {
      _weekSemesterId = result.semester?.id;
      _weekStart = defaultWeekStart(result.semester, _today);
      _mobile.reset(result.semester, _today);
    }
    return result;
  }

  DateTime _dateOf(int thu) => _weekStart!.add(Duration(days: thu - 2));

  void _moveWeek(int weeks) =>
      setState(() => _weekStart = _weekStart!.add(Duration(days: 7 * weeks)));

  Future<void> _pickDate() async {
    DateTime local(DateTime d) => DateTime(d.year, d.month, d.day);
    final s = _semester;
    final current = _dateOf(_selectedDay);
    final picked = await showDatePicker(
      context: context,
      initialDate: local(defaultDay(s, current)),
      firstDate: local(
        s?.startDate ?? current.subtract(const Duration(days: 365)),
      ),
      lastDate: local(s?.endDate ?? current.add(const Duration(days: 365))),
      helpText: 'Chọn ngày',
    );
    if (picked == null || !mounted) return;
    final day = dateOnly(picked);
    setState(() {
      _weekStart = mondayOf(day);
      _selectedDay = day.weekday + 1;
    });
  }

  Widget _buildToolbar(
    String role,
    AppTokens t,
    Widget viewTabs,
    Widget? below,
  ) {
    final s = _semester;
    final start = _weekStart;
    final first = firstWeekStart(s);
    final last = lastWeekStart(s);
    final title = switch (role) {
      'QUAN_TRI_VIEN' => 'Thời khóa biểu',
      'GIAO_VIEN' => 'Lịch giảng dạy bộ môn',
      _ =>
        _studentClass == null
            ? 'Thời khóa biểu của tôi'
            : 'Thời khóa biểu lớp $_studentClass',
    };
    return TimetableToolbar(
      title: title,
      semesterLabel: s == null ? null : '${s.name} · ${s.yearName}',
      weekNumberLabel: s == null || start == null
          ? null
          : 'Tuần ${weekNumber(s, start)}',
      weekLabel: start == null
          ? null
          : '${formatDayMonth(start)} – '
                '${formatFullDate(start.add(const Duration(days: 6)))}',
      dateLabel: start == null ? null : formatFullDate(_dateOf(_selectedDay)),
      tabs: viewTabs,
      extras: [
        if (role == 'QUAN_TRI_VIEN')
          for (final (label, byPeriod) in const [
            ('Theo buổi', false),
            ('Theo tiết', true),
          ])
            ChoiceChip(
              label: Text(label),
              selected: _byPeriod == byPeriod,
              onSelected: (_) => setState(() => _byPeriod = byPeriod),
            ),
      ],
      below: below,
      onPickDate: start == null ? null : _pickDate,
      onToday: start == null || !inSemester(s, _today)
          ? null
          : () => setState(() {
              _weekStart = mondayOf(_today);
              _selectedDay = _today.weekday + 1;
            }),
      onPrev: start == null || (first != null && !start.isAfter(first))
          ? null
          : () => _moveWeek(-1),
      onNext: start == null || (last != null && !start.isBefore(last))
          ? null
          : () => _moveWeek(1),
    );
  }

  /// Cờ hiển thị trên khối môn theo vai trò: GV thấy Lớp, HS thấy GV (và không
  /// thấy phòng), QTV thấy Lớp khi xem theo giáo viên/phòng, GV khi xem theo lớp.
  ({bool cls, bool teacher, bool room}) _blockFlags(String role) {
    if (role == 'HOC_SINH') return (cls: false, teacher: true, room: false);
    if (role == 'GIAO_VIEN') return (cls: true, teacher: false, room: true);
    if (_selectedTeacherId != null) {
      return (cls: true, teacher: false, room: true);
    }
    return (cls: _groupByRoom, teacher: true, room: true);
  }

  ValueChanged<TimetableSlot> _onBlockTap(String role) =>
      role == 'QUAN_TRI_VIEN'
      ? (slot) => _showSlotActions(slot.items)
      : (slot) =>
            showTimetableSlotInfo(context, slot, showRoom: role != 'HOC_SINH');

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
      builder: (sheetContext) {
        final t = sheetContext.tokens;
        final theme = Theme.of(sheetContext);
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .65,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sắp xếp tiết học',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: t.heading,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: t.line),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.tenMon,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: t.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${item.tenLop} · ${item.tenGiaoVien}\n${item.thuLabel} · Tiết ${item.tiet}${item.phongHoc == null ? '' : ' · ${item.phongHoc}'}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: t.ink2,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
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
                                  style: TextButton.styleFrom(
                                    foregroundColor: t.bad,
                                  ),
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
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteItem(TimetableItem item) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: 'Xóa tiết học?',
        confirmLabel: 'Xóa',
        danger: true,
        child: Text(
          '${item.tenMon} · ${item.tenLop} · ${item.thuLabel}, tiết ${item.tiet}',
        ),
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

  /// Khung thẻ của prototype (`.card`): nền surface, viền `line`, bo
  /// [AppRadius.md], đổ bóng nhẹ.
  BoxDecoration _cardDecoration(AppTokens t) => BoxDecoration(
    color: t.surface,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(color: t.line),
    boxShadow: t.shadow,
  );

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider);
    final role = user?.role.value ?? '';
    final theme = Theme.of(context);
    final t = context.tokens;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    String title;
    if (role == 'QUAN_TRI_VIEN') {
      title = 'Thời khóa biểu toàn trường';
    } else if (role == 'GIAO_VIEN') {
      title = 'Lịch giảng dạy bộ môn';
    } else {
      title = 'Thời khóa biểu của tôi';
    }

    if (isMobile) return _buildMobile(role, title, t);

    final viewTabs = AppTabs(
      tabs: const [
        AppTabItem(label: 'Lưới tuần'),
        AppTabItem(label: 'Theo ngày'),
      ],
      selectedIndex: _isWeeklyView ? 0 : 1,
      onChanged: (index) => setState(() => _isWeeklyView = index == 0),
    );

    final hintStyle = TextStyle(fontSize: 12, color: t.ink3);
    final controls = <Widget>[
      // Admin Class/Teacher Filter
      if (role == 'QUAN_TRI_VIEN') ...[
        if (_loadingMeta)
          const SizedBox(width: 120, child: LinearProgressIndicator())
        else ...[
          ..._filterDropdowns(),
          AppFilterDropdown<bool>(
            label: 'Hiển thị lịch theo',
            icon: Icons.layers_outlined,
            value: _groupByRoom,
            width: 210,
            searchable: false,
            items: const [
              DropdownMenuItem(value: false, child: Text('Lớp học')),
              DropdownMenuItem(value: true, child: Text('Phòng học')),
            ],
            onChanged: (v) => setState(() => _groupByRoom = v ?? false),
          ),
        ],
      ],
      if (role == 'QUAN_TRI_VIEN') ...[
        FilledButton.icon(
          onPressed: _loadingMeta || _assignments.isEmpty
              ? null
              : () => _showEditor(),
          icon: const Icon(Icons.add),
          label: const Text('Thêm môn vào lịch'),
        ),
        if (_metadataError != null)
          Text(
            'Không tải được phân công: $_metadataError',
            style: TextStyle(fontSize: 12, color: t.bad),
          ),
        if (!_loadingMeta && _metadataError == null && _assignments.isEmpty)
          Text('Tạo phân công giảng dạy trước khi xếp lịch.', style: hintStyle),
        Text(
          'Ô trống: thêm môn · Ô có môn: sửa, chuyển hoặc xóa',
          style: hintStyle,
        ),
      ],
    ];

    return AppScaffold(
      title: title,
      currentPath: '/timetable',
      showBackButton: true,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.md : AppSpacing.page,
              vertical: isMobile ? AppSpacing.md : AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildToolbar(
                  role,
                  t,
                  viewTabs,
                  role == 'QUAN_TRI_VIEN'
                      ? Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.md,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: controls,
                        )
                      : null,
                ),

                const SizedBox(height: 14),

                // Main Content
                Expanded(
                  child: FutureBuilder<TimetableResult>(
                    future: _timetableFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const ShimmerLoading(
                          itemCount: 6,
                          itemHeight: 80,
                        );
                      }
                      if (snapshot.hasError) {
                        return _buildError(snapshot.error!, t);
                      }

                      final items = snapshot.data?.items ?? [];
                      if (items.isEmpty || _weekStart == null) {
                        return const EmptyState(
                          title: 'Chưa có dữ liệu thời khóa biểu',
                          message:
                              'Thời khóa biểu cho phạm vi này hiện chưa được xếp lịch.',
                          icon: Icons.event_busy_outlined,
                        );
                      }

                      return _isWeeklyView
                          ? _buildWeeklyGrid(items, role, t, theme)
                          : _buildDayAgenda(items, role, t);
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

  List<Widget> _filterDropdowns({double? width, VoidCallback? refresh}) => [
    AppFilterDropdown<num>(
      label: 'Lớp học',
      icon: Icons.meeting_room_outlined,
      value: _selectedClassId,
      width: width ?? 220,
      items: [
        const DropdownMenuItem(value: null, child: Text('Tất cả')),
        for (final c in _classes)
          DropdownMenuItem(
            value: c['ma_lop'] as num?,
            child: Text(c['ten_lop']?.toString() ?? 'Lớp'),
          ),
      ],
      onChanged: (value) {
        setState(() => _selectedClassId = value);
        _loadTimetable();
        refresh?.call();
      },
    ),
    AppFilterDropdown<num>(
      label: 'Giáo viên',
      icon: Icons.badge_outlined,
      value: _selectedTeacherId,
      width: width ?? 220,
      items: [
        const DropdownMenuItem(value: null, child: Text('Tất cả')),
        for (final teacher in _teachers)
          DropdownMenuItem(
            value: teacher['ma_giao_vien'] as num?,
            child: Text(teacher['ho_ten']?.toString() ?? 'GV'),
          ),
      ],
      onChanged: (value) {
        setState(() => _selectedTeacherId = value);
        _loadTimetable();
        refresh?.call();
      },
    ),
    AppFilterDropdown<num>(
      label: 'Học kỳ',
      icon: Icons.calendar_month_outlined,
      value: _selectedSemesterId,
      width: width ?? 220,
      items: [
        const DropdownMenuItem(value: null, child: Text('Học kỳ hiện hành')),
        for (final semester in _semesters)
          DropdownMenuItem(
            value: semester['ma_hoc_ky'] as num?,
            child: Text(semester['ten']?.toString() ?? 'Học kỳ'),
          ),
      ],
      onChanged: (value) {
        setState(() => _selectedSemesterId = value);
        _loadTimetable();
        refresh?.call();
      },
    ),
  ];

  Widget _buildError(Object error, AppTokens t) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: t.bad),
            const SizedBox(height: 10),
            Text(
              'Lỗi: $error',
              style: TextStyle(color: t.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: _loadTimetable,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  // ── MOBILE (màn < 600): chế độ Ngày / Tuần / Tháng ──────────────────────────
  Widget _buildMobile(String role, String title, AppTokens t) {
    final isAdmin = role == 'QUAN_TRI_VIEN';
    return AppScaffold(
      title: title,
      currentPath: '/timetable',
      showBackButton: true,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          0,
        ),
        child: FutureBuilder<TimetableResult>(
          future: _timetableFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const ShimmerLoading(itemCount: 4, itemHeight: 120);
            }
            if (snapshot.hasError) return _buildError(snapshot.error!, t);
            final result = snapshot.data!;
            return TimetableMobileView(
              controller: _mobile,
              items: result.items,
              semester: result.semester,
              role: role,
              today: _today,
              onSlotTap: isAdmin
                  ? (slot) => _showSlotActions(slot.items)
                  : null,
              adminBar: isAdmin ? _buildAdminBar : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildAdminBar(DateTime selected) {
    final t = context.tokens;
    final hint = TextStyle(fontSize: 12, color: t.ink3);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: _loadingMeta ? null : _showFilterSheet,
          icon: const Icon(Icons.tune, size: 18),
          label: const Text('Bộ lọc'),
        ),
        FilledButton.icon(
          onPressed: _loadingMeta || _assignments.isEmpty
              ? null
              : () => _showEditor(day: selected.weekday + 1),
          icon: const Icon(Icons.add),
          label: const Text('Thêm môn vào lịch'),
        ),
        if (_metadataError != null)
          Text(
            'Không tải được phân công: $_metadataError',
            style: TextStyle(fontSize: 12, color: t.bad),
          ),
        if (!_loadingMeta && _metadataError == null && _assignments.isEmpty)
          Text('Tạo phân công giảng dạy trước khi xếp lịch.', style: hint),
      ],
    );
  }

  Future<void> _showFilterSheet() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bộ lọc thời khóa biểu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.tokens.heading,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final dropdown in _filterDropdowns(
              width: MediaQuery.sizeOf(context).width - 2 * AppSpacing.xl,
              refresh: () => setSheetState(() {}),
            )) ...[dropdown, const SizedBox(height: AppSpacing.md)],
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Xong'),
            ),
          ],
        ),
      ),
    ),
  );

  // ── 1. WEEKLY GRID VIEW ───────────────────────────────────────────────────
  Widget _buildWeeklyGrid(
    List<TimetableItem> items,
    String role,
    AppTokens t,
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
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        itemCount: groups.length,
        separatorBuilder: (_, _) => const SizedBox(height: 18),
        itemBuilder: (context, index) {
          final group = groups[index];
          return _buildGroupBoard(
            group.value,
            role,
            t,
            header: _buildGroupHeader(
              '${_groupByRoom ? 'Phòng' : 'Lớp'} ${group.key}',
              '${group.value.length} tiết',
              t,
              theme,
            ),
          );
        },
      );
    }
    return SingleChildScrollView(
      key: const ValueKey('timetable-weekly-vertical-scroll'),
      primary: true,
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: _buildGroupBoard(items, role, t),
    );
  }

  /// Lưới theo buổi (mặc định); QTV bật "Theo tiết" thì dùng lưới từng tiết.
  Widget _buildGroupBoard(
    List<TimetableItem> items,
    String role,
    AppTokens t, {
    Widget? header,
  }) {
    if (role == 'QUAN_TRI_VIEN' && _byPeriod) {
      return _buildWeeklyGridTable(items, role, t, header: header);
    }
    final flags = _blockFlags(role);
    final slotClassId =
        _selectedClassId ??
        (!_groupByRoom && items.isNotEmpty ? items.first.maLop : null);
    final board = TimetableWeekBoard(
      items: items,
      weekStart: _weekStart!,
      semester: _semester,
      today: _today,
      showClass: flags.cls,
      showTeacher: flags.teacher,
      showRoom: flags.room,
      onBlockTap: _onBlockTap(role),
      onAdd: role == 'QUAN_TRI_VIEN' && !_loadingMeta && _assignments.isNotEmpty
          ? (thu, period) =>
                _showEditor(day: thu, period: period, classId: slotClassId)
          : null,
    );
    return DecoratedBox(
      decoration: _cardDecoration(t),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: header == null
            ? board
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [header, board],
              ),
      ),
    );
  }

  /// Tiêu đề thẻ (`.hd`) của từng nhóm lớp/phòng: tên nhóm và số tiết.
  Widget _buildGroupHeader(
    String label,
    String count,
    AppTokens t,
    ThemeData theme,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(Icons.meeting_room_outlined, size: 18, color: t.priLink),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: t.heading,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppBadge(count, dot: false),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyGridTable(
    List<TimetableItem> items,
    String role,
    AppTokens t, {
    Widget? header,
  }) {
    final slotClassId =
        _selectedClassId ??
        (!_groupByRoom && items.isNotEmpty ? items.first.maLop : null);
    // Map items by [thu][tiet]
    final matrix = <int, Map<int, List<TimetableItem>>>{};
    for (var thu = 2; thu <= 8; thu++) {
      matrix[thu] = {};
    }
    for (final item in items) {
      // TKB chỉ áp dụng trong học kỳ: ngày ngoài học kỳ không hiện tiết.
      if (!inSemester(_semester, _dateOf(item.thu))) continue;
      matrix.putIfAbsent(item.thu, () => {});
      matrix[item.thu]!.putIfAbsent(item.tiet, () => []).add(item);
    }

    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final cellWidth = isMobile ? 102.0 : 140.0;
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

    // Tiêu đề cột: chữ 12 hoa, đậm vừa, màu ink3 (`th` của prototype).
    TextStyle headStyle({Color? color}) => TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: .6,
      color: color ?? t.ink3,
    );

    // Hàng phân cách buổi (`.sep`): nền subtle, chữ hoa. Nhãn tràn sang các ô
    // trống bên cạnh để không làm rộng cột "Tiết".
    DataRow separatorRow(String label) => DataRow(
      color: WidgetStatePropertyAll(t.subtle),
      cells: [
        DataCell(
          SizedBox(
            width: 0,
            height: 28,
            child: OverflowBox(
              minWidth: 0,
              maxWidth: 240,
              alignment: Alignment.centerLeft,
              child: Text(label, softWrap: false, style: headStyle()),
            ),
          ),
        ),
        for (final _ in days) const DataCell(SizedBox.shrink()),
      ],
    );

    final table = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: isMobile ? 6 : 14,
        horizontalMargin: isMobile ? 6 : 14,
        headingRowHeight: isMobile ? 52 : 56,
        dataRowMinHeight: 28,
        dataRowMaxHeight: double.infinity,
        headingRowColor: WidgetStatePropertyAll(t.subtle),
        border: TableBorder(horizontalInside: BorderSide(color: t.line)),
        columns: [
          DataColumn(label: Text('TIẾT', style: headStyle())),
          for (final d in days)
            DataColumn(
              label: SizedBox(
                width: cellWidth,
                child: Opacity(
                  opacity: inSemester(_semester, _dateOf(d)) ? 1 : .45,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dayNames[d]!.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: headStyle(
                          color: _dateOf(d) == _today ? t.priLink : null,
                        ),
                      ),
                      Text(
                        formatDayMonth(_dateOf(d)),
                        textAlign: TextAlign.center,
                        style:
                            headStyle(
                              color: _dateOf(d) == _today ? t.priLink : null,
                            ).copyWith(
                              letterSpacing: 0,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
        rows: [
          for (var tiet = 1; tiet <= 10; tiet++) ...[
            if (tiet == 1) separatorRow('BUỔI SÁNG'),
            if (tiet == 6) separatorRow('BUỔI CHIỀU'),
            DataRow(
              cells: [
                // Period column
                DataCell(
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: isMobile ? 52 : 56),
                    child: Center(
                      heightFactor: 1,
                      child: Text(
                        'T$tiet',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.w700,
                          color: t.ink2,
                        ),
                      ),
                    ),
                  ),
                ),
                // Day columns
                for (final d in days)
                  DataCell(
                    _buildGridCell(
                      matrix[d]?[tiet] ?? [],
                      role,
                      t,
                      day: d,
                      period: tiet,
                      classId: slotClassId,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    return DecoratedBox(
      decoration: _cardDecoration(t),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: header == null
            ? table
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [header, table],
              ),
      ),
    );
  }

  Widget _buildGridCell(
    List<TimetableItem> cellItems,
    String role,
    AppTokens t, {
    required int day,
    required int period,
    num? classId,
  }) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final cellWidth = isMobile ? 102.0 : 140.0;

    if (cellItems.isEmpty) {
      // Ngày ngoài học kỳ không xếp lịch; thêm tiết ở tuần khác trong học kỳ.
      if (role == 'QUAN_TRI_VIEN' && inSemester(_semester, _dateOf(day))) {
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
              foregroundColor: t.ink3,
              side: BorderSide(color: t.line),
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
        child: Center(
          heightFactor: 1,
          child: Text('—', style: TextStyle(color: t.ink3)),
        ),
      );
    }

    final item = cellItems.first;
    final isStudent = role == 'HOC_SINH';
    // Chip tiết (`.tc`): giáo viên/quản trị nền primary nhạt; học sinh nền
    // trung tính (`.tc.sub`).
    final chipBg = isStudent ? t.hover : t.priSoft;
    final chipFg = isStudent ? t.ink : t.priLink;
    final chipLine = isStudent ? t.line : t.priLine;

    return Tooltip(
      message: cellItems
          .map((i) => '${i.tenMon} · ${i.tenLop} · ${i.tenGiaoVien}')
          .join('\n'),
      child: InkWell(
        onTap: role == 'QUAN_TRI_VIEN'
            ? () => _showSlotActions(cellItems)
            : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: cellWidth,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 5 : 8,
            vertical: isMobile ? 4 : 6,
          ),
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: chipLine),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.tenMon,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 11 : 12,
                  color: chipFg,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                isStudent ? item.tenGiaoVien : item.tenLop,
                style: TextStyle(
                  fontSize: isMobile ? 9.5 : 10.5,
                  fontWeight: FontWeight.w500,
                  color: t.ink2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isStudent &&
                  item.phongHoc != null &&
                  item.phongHoc!.isNotEmpty) ...[
                const SizedBox(height: 1),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    child: Text(
                      item.phongHoc!,
                      style: TextStyle(
                        fontSize: isMobile ? 8.5 : 9,
                        fontWeight: FontWeight.w600,
                        color: chipFg,
                      ),
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
                    color: chipFg,
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
    AppTokens t,
  ) {
    const days = [2, 3, 4, 5, 6, 7, 8];
    const shortNames = {
      2: 'T2',
      3: 'T3',
      4: 'T4',
      5: 'T5',
      6: 'T6',
      7: 'T7',
      8: 'CN',
    };
    const fullNames = {
      2: 'Thứ Hai',
      3: 'Thứ Ba',
      4: 'Thứ Tư',
      5: 'Thứ Năm',
      6: 'Thứ Sáu',
      7: 'Thứ Bảy',
      8: 'Chủ nhật',
    };
    final inTerm = inSemester(_semester, _dateOf(_selectedDay));
    final slots = inTerm
        ? groupSlots(allItems.where((i) => i.thu == _selectedDay))
        : <TimetableSlot>[];
    final flags = _blockFlags(role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final d in days)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(
                      '${shortNames[d]} · ${formatDayMonth(_dateOf(d))}',
                    ),
                    selected: _selectedDay == d,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedDay = d);
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: TimetableDayList(
            slots: slots,
            emptyMessage: inTerm
                ? 'Không có tiết học vào ${fullNames[_selectedDay]}'
                : 'Ngày này nằm ngoài học kỳ',
            showClass: flags.cls,
            showTeacher: flags.teacher,
            showRoom: flags.room,
            onBlockTap: _onBlockTap(role),
          ),
        ),
      ],
    );
  }
}
