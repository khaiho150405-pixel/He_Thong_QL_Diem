import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_dialog.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../app/widgets/app_select_field.dart';
import 'academic_year_scope.dart';
import 'repository.dart';
import 'semester_deadlines_repository.dart';

String formatDeadline(BuildContext context, DateTime? date) {
  if (date == null) return 'Chưa đặt lịch';
  final local = MaterialLocalizations.of(context);
  final localDate = date.toLocal();
  return '${local.formatShortDate(localDate)} ${local.formatTimeOfDay(TimeOfDay.fromDateTime(localDate), alwaysUse24HourFormat: true)}';
}

String _deadlineTypeName(SemesterDeadlineDtoTypeEnum type) => switch (type) {
  SemesterDeadlineDtoTypeEnum.TX => 'Điểm thường xuyên (TX)',
  SemesterDeadlineDtoTypeEnum.GK => 'Điểm giữa kỳ (GK)',
  SemesterDeadlineDtoTypeEnum.CK => 'Điểm cuối kỳ (CK)',
};

String _getYearName(
  SemestersDto s,
  List<Json> years,
  ViewingYear? viewingYear,
) {
  for (final y in years) {
    if (y['ma_nam_hoc'] == s.maNamHoc) {
      final name = y['ten'] ?? y['label'];
      if (name != null && name.toString().isNotEmpty) {
        return name.toString();
      }
    }
  }
  if (viewingYear?.id == s.maNamHoc && viewingYear!.name.isNotEmpty) {
    return viewingYear.name;
  }
  final label = s.label;
  final match = RegExp(r'\(([^)]+)\)').firstMatch(label);
  if (match != null) {
    return match.group(1)!;
  }
  return '${s.maNamHoc}';
}

String _formatSemesterYearText(String semesterName, String yearName) {
  final semText = semesterName.toLowerCase().startsWith('học kỳ')
      ? semesterName
      : 'Học kỳ $semesterName';
  final yrText = yearName.toLowerCase().startsWith('năm')
      ? yearName
      : 'Năm học $yearName';
  return '$semText · $yrText';
}

bool _isCurrentDateInSemester(SemestersDto s) {
  try {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime.parse(s.ngayBatDau);
    final end = DateTime.parse(s.ngayKetThuc);
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    return !today.isBefore(startDate) && !today.isAfter(endDate);
  } catch (_) {
    return false;
  }
}

num? _resolveEffectiveYearId(ViewingYear? viewingYear, List<Json> years) {
  if (viewingYear != null && !viewingYear.isAll && viewingYear.id != null) {
    return viewingYear.id;
  }
  for (final y in years) {
    if (y['hien_hanh'] == true) {
      return y['ma_nam_hoc'] as num?;
    }
  }
  return years.isNotEmpty ? years.first['ma_nam_hoc'] as num? : null;
}

class SemesterDeadlinesScreen extends ConsumerStatefulWidget {
  const SemesterDeadlinesScreen({super.key});

  @override
  ConsumerState<SemesterDeadlinesScreen> createState() =>
      _SemesterDeadlinesScreenState();
}

class _SemesterDeadlinesScreenState
    extends ConsumerState<SemesterDeadlinesScreen> {
  Future<List<SemestersDto>>? _semestersFuture;
  num? _selectedSemesterId;
  Future<SemesterDeadlinesDto>? _deadlinesFuture;
  bool _initializing = false;
  num? _lastLoadedYearId;
  List<SemestersDto> _loadedSemesters = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(academicYearsProvider);
    });
    final viewingYear = ref.read(viewingYearProvider);
    final years = ref.read(academicYearsProvider).valueOrNull ?? const [];
    final effectiveYearId = _resolveEffectiveYearId(viewingYear, years);
    _loadSemesters(yearId: effectiveYearId);
  }

  void _refresh() {
    ref.invalidate(academicYearsProvider);
    final viewingYear = ref.read(viewingYearProvider);
    final years = ref.read(academicYearsProvider).valueOrNull ?? const [];
    final effectiveYearId = _resolveEffectiveYearId(viewingYear, years);
    _loadSemesters(yearId: effectiveYearId);
  }

  void _loadSemesters({num? yearId}) {
    _lastLoadedYearId = yearId;
    final future = ref
        .read(semesterDeadlinesRepositoryProvider)
        .listSemesters(yearId: yearId);
    setState(() {
      _semestersFuture = future;
      _deadlinesFuture = null;
    });
    future.then((semesters) {
      if (!mounted) return;
      if (_lastLoadedYearId != yearId) return;
      setState(() {
        _loadedSemesters = semesters;
        if (semesters.isEmpty) {
          _selectedSemesterId = null;
          _deadlinesFuture = null;
        } else {
          final isSelectedValid = semesters.any(
            (s) => s.maHocKy == _selectedSemesterId,
          );
          if (!isSelectedValid) {
            SemestersDto? defaultSem;
            for (final s in semesters) {
              if (_isCurrentDateInSemester(s)) {
                defaultSem = s;
                break;
              }
            }
            defaultSem ??= semesters.first;
            _selectedSemesterId = defaultSem.maHocKy;
          }
          _loadDeadlines();
        }
      });
    });
  }

  void _onViewingYearChanged(num? newYearId) {
    setState(() {
      _selectedSemesterId = null;
      _deadlinesFuture = null;
    });
    _loadSemesters(yearId: newYearId);
  }

  void _loadDeadlines() {
    if (_selectedSemesterId != null) {
      setState(() {
        _deadlinesFuture = ref
            .read(semesterDeadlinesRepositoryProvider)
            .getDeadlines(_selectedSemesterId!);
      });
    }
  }

  Future<void> _initializeGradebooks(String semesterYearLabel) async {
    if (_selectedSemesterId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khởi tạo bảng điểm còn thiếu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              semesterYearLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sau khi có bảng điểm, cấu trúc thành phần điểm của môn sẽ không sửa được.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Khởi tạo'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _initializing = true);
    InitializeGradebooksResultDto? result;
    try {
      final key =
          'init-$_selectedSemesterId-${DateTime.now().millisecondsSinceEpoch}';
      result = await ref
          .read(semesterDeadlinesRepositoryProvider)
          .initializeGradebooks(
            semesterId: _selectedSemesterId!,
            idempotencyKey: key,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(deadlineErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _initializing = false);
    }

    if (result != null && mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Kết quả khởi tạo'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Số bảng đã tạo: ${result!.created.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (result.skipped.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Danh sách bỏ qua (${result.skipped.length}):',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    for (final item in result.skipped)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${item.className} – ${item.subjectName}: ${item.reason == SkippedGradebookDtoReasonEnum.EMPTY_ROSTER ? "Lớp chưa có học sinh" : "Môn chưa có thành phần điểm"}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openEditDialog(
    SemesterDeadlineDto item,
    String semesterYearLabel,
  ) async {
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SemesterDeadlineEditDialog(
        semesterId: _selectedSemesterId!,
        item: item,
        semesterYearLabel: semesterYearLabel,
      ),
    );
    if (updated == true && mounted) {
      _loadDeadlines();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ViewingYear?>(viewingYearProvider, (prev, next) {
      final years = ref.read(academicYearsProvider).valueOrNull ?? const [];
      final prevYearId = _resolveEffectiveYearId(prev, years);
      final nextYearId = _resolveEffectiveYearId(next, years);
      if (prevYearId != nextYearId) {
        _onViewingYearChanged(nextYearId);
      }
    });

    ref.listen<AsyncValue<List<Json>>>(academicYearsProvider, (prev, next) {
      final yearsList = next.valueOrNull ?? const [];
      final vy = ref.read(viewingYearProvider);
      final effId = _resolveEffectiveYearId(vy, yearsList);
      if (effId != null && _lastLoadedYearId == null) {
        _onViewingYearChanged(effId);
      }
    });

    final t = context.tokens;
    final years = ref.watch(academicYearsProvider).valueOrNull ?? const [];
    final viewingYear = ref.watch(viewingYearProvider);

    return AppScaffold(
      title: 'Lịch nhập điểm học kỳ',
      currentPath: '/admin/semester-deadlines',
      body: FutureBuilder<List<SemestersDto>>(
        future: _semestersFuture,
        builder: (context, semSnapshot) {
          if (semSnapshot.connectionState != ConnectionState.done &&
              _selectedSemesterId == null &&
              _loadedSemesters.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (semSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Không thể tải danh sách học kỳ.',
                    style: TextStyle(color: t.bad),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => _onViewingYearChanged(_lastLoadedYearId),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final semesters = semSnapshot.data ?? _loadedSemesters;

          String semesterYearLabel = '';
          if (_selectedSemesterId != null) {
            final sem = semesters
                .where((s) => s.maHocKy == _selectedSemesterId)
                .firstOrNull;
            if (sem != null) {
              final yrName = _getYearName(sem, years, viewingYear);
              semesterYearLabel = _formatSemesterYearText(sem.ten, yrName);
            }
          }

          final selectedDropdownValue =
              semesters.any((s) => s.maHocKy == _selectedSemesterId)
              ? _selectedSemesterId
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AcademicYearFilterControl(
                          years: years,
                          width: 270,
                          allowAll: false,
                          onChanged: () {
                            ref.invalidate(academicYearsProvider);
                            final cur = ref.read(viewingYearProvider);
                            final effId = _resolveEffectiveYearId(cur, years);
                            _onViewingYearChanged(effId);
                          },
                        ),
                        SizedBox(
                          width: 280,
                          child: AppSelectField<num>(
                            key: ValueKey(selectedDropdownValue),
                            value: selectedDropdownValue,
                            label: 'Chọn học kỳ',
                            dense: true,
                            hintText: 'Tất cả',
                            items: [
                              for (final s in semesters)
                                DropdownMenuItem(
                                  value: s.maHocKy,
                                  child: Text(
                                    '${s.ten} · ${_getYearName(s, years, viewingYear)}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: semesters.isEmpty
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedSemesterId = val;
                                        _loadDeadlines();
                                      });
                                    }
                                  },
                          ),
                        ),
                        FilledButton.icon(
                          onPressed:
                              _initializing || _selectedSemesterId == null
                              ? null
                              : () => _initializeGradebooks(semesterYearLabel),
                          icon: _initializing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.playlist_add_check),
                          label: const Text('Khởi tạo bảng điểm còn thiếu'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (semesters.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Năm học này chưa có học kỳ',
                        style: TextStyle(color: t.ink2, fontSize: 15),
                      ),
                    ),
                  )
                else if (_deadlinesFuture != null)
                  FutureBuilder<SemesterDeadlinesDto>(
                    future: _deadlinesFuture,
                    builder: (context, deadSnapshot) {
                      if (deadSnapshot.connectionState !=
                          ConnectionState.done) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (deadSnapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                deadlineErrorMessage(deadSnapshot.error!),
                                style: TextStyle(color: t.bad),
                              ),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: _loadDeadlines,
                                child: const Text('Tải lại lịch'),
                              ),
                            ],
                          ),
                        );
                      }

                      final items = deadSnapshot.data?.items ?? [];
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 720;
                          final cards = items.map((item) {
                            return _buildDeadlineCard(
                              context,
                              item,
                              semesterYearLabel,
                            );
                          }).toList();

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (int i = 0; i < cards.length; i++) ...[
                                  if (i > 0)
                                    const SizedBox(width: AppSpacing.md),
                                  Expanded(child: cards[i]),
                                ],
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (int i = 0; i < cards.length; i++) ...[
                                if (i > 0)
                                  const SizedBox(height: AppSpacing.md),
                                cards[i],
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _semesterDeadlineStatusBadge(SemesterDeadlineDto item) {
    final opensAt = item.opensAt?.toLocal();
    final closesAt = item.closesAt?.toLocal();
    if (closesAt == null || opensAt == null) {
      return const AppBadge('Chưa đặt lịch', dot: false);
    }
    final now = DateTime.now();
    if (now.isBefore(opensAt)) {
      return const AppBadge('Chưa mở', tone: AppBadgeTone.neutral, dot: false);
    }
    if (item.expired || !now.isBefore(closesAt)) {
      return const AppBadge.warn('Đã hết hạn', dot: false);
    }
    return const AppBadge.ok('Đang hiệu lực', dot: false);
  }

  Widget _buildDeadlineCard(
    BuildContext context,
    SemesterDeadlineDto item,
    String semesterYearLabel,
  ) {
    final t = context.tokens;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _deadlineTypeName(item.type),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _semesterDeadlineStatusBadge(item),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Mở: ${formatDeadline(context, item.opensAt)}\nHạn: ${formatDeadline(context, item.closesAt)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: t.ink2, height: 1.5),
            ),
            const SizedBox(height: 16),
            if (item.expired)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Lịch đã qua hạn, không sửa được',
                  style: TextStyle(
                    color: t.ink3,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _openEditDialog(item, semesterYearLabel),
                icon: const Icon(Icons.event_outlined),
                label: Text(item.closesAt == null ? 'Đặt lịch' : 'Sửa lịch'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SemesterDeadlineEditDialog extends ConsumerStatefulWidget {
  const _SemesterDeadlineEditDialog({
    required this.semesterId,
    required this.item,
    required this.semesterYearLabel,
  });

  final num semesterId;
  final SemesterDeadlineDto item;
  final String semesterYearLabel;

  @override
  ConsumerState<_SemesterDeadlineEditDialog> createState() =>
      _SemesterDeadlineEditDialogState();
}

class _SemesterDeadlineEditDialogState
    extends ConsumerState<_SemesterDeadlineEditDialog> {
  late DateTime opens, closes;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    opens = widget.item.opensAt?.toLocal() ?? DateTime.now();
    closes =
        widget.item.closesAt?.toLocal() ??
        DateTime.now().add(const Duration(days: 7));
  }

  Future<void> pick(bool opening) async {
    final value = opening ? opens : closes;
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    setState(() {
      final selected = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (opening) {
        opens = selected;
      } else {
        closes = selected;
      }
    });
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(semesterDeadlinesRepositoryProvider)
          .setDeadline(
            semesterId: widget.semesterId,
            type: widget.item.type.value,
            opensAt: opens.toUtc(),
            closesAt: closes.toUtc(),
            expectedVersion: widget.item.version,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = deadlineErrorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppDialog(
      title: 'Lịch nhập · ${_deadlineTypeName(widget.item.type)}',
      confirmLabel: 'Lưu lịch nhập',
      confirmEnabled: !busy,
      onConfirm: save,
      onCancel: () {
        if (!busy) Navigator.pop(context, false);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.semesterYearLabel.isNotEmpty) ...[
            Text(
              widget.semesterYearLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
          ],
          const Text(
            'Giờ hiển thị theo thiết bị hiện tại. Đến hạn, điểm thiếu/chưa duyệt được ghi 0 và không thể mở lại cột đã khóa.',
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: busy ? null : () => pick(true),
            icon: const Icon(Icons.calendar_today),
            label: Text('Mở nhập: ${formatDeadline(context, opens)}'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : () => pick(false),
            icon: const Icon(Icons.timer_outlined),
            label: Text('Hạn nhập: ${formatDeadline(context, closes)}'),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(error!, style: TextStyle(color: t.bad)),
            ),
          if (busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
