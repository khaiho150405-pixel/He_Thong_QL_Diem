import 'dart:math';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_dialog.dart';
import '../../app/widgets/empty_state.dart';
import '../authentication/session.dart';
import '../gradebooks/repository.dart';
import 'repository.dart';
import 'student_results_screen.dart'
    show classificationBadgeOf, classificationLabel;

/// Định dạng `dd/MM/yyyy HH:mm` theo giờ máy (không thêm package `intl`).
String _formatDateTime(DateTime value) {
  final d = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

/// Xếp loại hiển thị theo MÃ backend trả về, ánh xạ nhãn tiếng Việt qua [classificationBadgeOf].
Widget _classificationBadge(String code) {
  final badge = classificationBadgeOf(code);
  return AppBadge(badge.label, tone: badge.tone);
}

enum _ResultGroup { all, exempted, skipped }

enum _ResultSort { sttAsc, sttDesc, scoreDesc, scoreAsc }

class FinalResultsPanel extends ConsumerStatefulWidget {
  const FinalResultsPanel({
    super.key,
    required this.gradebookId,
    required this.gradebookVersion,
    this.showResults = true,
    this.initialSummary,
    this.resultsOutdated,
  });

  final num gradebookId;
  final num gradebookVersion;
  final bool showResults;
  final CalculateFinalResultsDto? initialSummary;
  final bool? resultsOutdated;

  @override
  ConsumerState<FinalResultsPanel> createState() => FinalResultsPanelState();
}

class FinalResultsPanelState extends ConsumerState<FinalResultsPanel> {
  late Future<FinalResultListDto> results;
  late Future<Map<num, num?>> _studentSttFuture;
  bool busy = false;
  CalculateFinalResultsDto? _lastSummary;
  late bool _resultsOutdated;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _classificationFilter;
  _ResultGroup _activeGroup = _ResultGroup.all;
  _ResultSort _sort = _ResultSort.sttAsc;
  int _page = 0;
  static const int _pageSize = 25;
  bool _mobileFiltersOpen = false;

  bool get teacher => ref.read(sessionProvider)?.role.value == 'GIAO_VIEN';

  @override
  void initState() {
    super.initState();
    _resultsOutdated = widget.resultsOutdated ?? false;
    _lastSummary = widget.initialSummary;
    results = ref.read(finalResultsRepositoryProvider).list(widget.gradebookId);
    _studentSttFuture = _loadStudentStt();
  }

  @override
  void didUpdateWidget(covariant FinalResultsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resultsOutdated != null &&
        widget.resultsOutdated != oldWidget.resultsOutdated) {
      _resultsOutdated = widget.resultsOutdated!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<num, num?>> _loadStudentStt() async {
    try {
      final cells =
          await ref.read(gradebooksRepositoryProvider).cells(widget.gradebookId);
      if (widget.resultsOutdated == null && cells.book.resultsOutdated == true) {
        if (mounted) setState(() => _resultsOutdated = true);
      }
      final map = <num, num?>{};
      for (final cell in cells.items) {
        if (cell.stt != null) {
          map[cell.studentId] = cell.stt;
        }
      }
      return map;
    } catch (_) {
      return const {};
    }
  }

  void reload() => setState(() {
        busy = false;
        results =
            ref.read(finalResultsRepositoryProvider).list(widget.gradebookId);
        _studentSttFuture = _loadStudentStt();
      });

  Future<String?> askReason() async {
    var reason = '';
    String? error;
    return showAppDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final t = context.tokens;
          return AppDialog(
            title: 'Tính kết quả tổng kết',
            confirmLabel: 'Tính kết quả',
            cancelLabel: 'Hủy',
            onCancel: () => Navigator.pop(dialogContext),
            onConfirm: () {
              final normalized = reason.trim();
              if (normalized.isEmpty) {
                setDialogState(() => error = 'Cần nhập lý do.');
                return;
              }
              Navigator.pop(dialogContext, normalized);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chỉ điểm đã duyệt được tính. Hệ thống lưu bộ hệ số, '
                  'phiên bản chính sách và lịch sử của lần tính này.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: t.ink2),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  autofocus: true,
                  maxLength: 500,
                  maxLines: 3,
                  onChanged: (value) => reason = value,
                  decoration: InputDecoration(
                    labelText: 'Lý do tính hoặc tính lại',
                    hintText: 'Ví dụ: Tổng kết học kỳ I',
                    errorText: error,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> calculate() async {
    final reason = await askReason();
    if (reason == null || !mounted) return;
    setState(() => busy = true);
    try {
      final summary = await ref
          .read(finalResultsRepositoryProvider)
          .calculate(
            gradebookId: widget.gradebookId,
            expectedVersion: widget.gradebookVersion,
            reason: reason,
          );
      if (!mounted) return;
      setState(() {
        _lastSummary = summary;
        _resultsOutdated = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã tính ${summary.calculatedStudents} học sinh; '
            'bỏ qua ${summary.skippedStudents}. '
            'Policy ${summary.policyVersion}.',
          ),
        ),
      );
      reload();
    } catch (error) {
      if (!mounted) return;
      setState(() => busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_message(error))));
    }
  }

  String _message(Object error) {
    if (error is DioException && error.response?.statusCode == 409) {
      return 'Không thể tính: bảng chưa chốt, phiên bản đã đổi, còn điểm chờ '
          'đối chiếu hoặc cấu hình chưa hợp lệ.';
    }
    return 'Không tải được kết quả tổng kết. Vui lòng thử lại.';
  }

  Future<void> showHistory(FinalResultDto item) async {
    await showAppDialog<void>(
      context: context,
      builder: (_) => _FinalResultHistoryDialog(
        gradebookId: widget.gradebookId,
        result: item,
      ),
    );
  }

  Widget _header(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final canClose = ModalRoute.of(context) is PopupRoute;
    final titleBlock = Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: t.priSoft,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(Icons.calculate_outlined, size: 20, color: t.priLink),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kết quả tổng kết và xếp loại',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: t.ink,
                ),
              ),
              Text(
                'Hiển thị dưới bảng điểm · UC14–UC15',
                style: theme.textTheme.bodySmall?.copyWith(color: t.ink3),
              ),
            ],
          ),
        ),
        if (canClose)
          IconButton(
            tooltip: 'Đóng',
            color: t.ink2,
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
      ],
    );
    if (!teacher) return titleBlock;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        titleBlock,
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const ValueKey('calculate-final-results'),
            onPressed: busy ? null : calculate,
            icon: const Icon(Icons.functions),
            label: const Text('Tính kết quả'),
          ),
        ),
      ],
    );
  }

  Widget _stateMessage(BuildContext context, String text, {Widget? action}) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: t.ink2),
            ),
            if (action != null) action,
          ],
        ),
      ),
    );
  }

  /// Thông tin phiên bản hệ số, chính sách và thời điểm tính duy nhất của bảng điểm.
  Widget _metaSummary(BuildContext context, FinalResultDto first) {
    final t = context.tokens;
    return Container(
      key: const ValueKey('final-results-meta-summary'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: t.subtle,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: t.line),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: t.priLink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Tính lúc ${_formatDateTime(first.calculatedAt)} · '
              'Hệ số ${first.weightVersion} · '
              'Chính sách ${first.policyVersion}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: t.ink2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Thanh công cụ: tìm tên, lọc xếp loại, nhóm (Tất cả / Miễn môn / Thiếu điểm), sắp xếp.
  Widget _toolbar(
    BuildContext context, {
    required int totalCount,
    required int exemptedCount,
    required int skippedCount,
    required List<String> availableClassifications,
    required bool isMobile,
  }) {
    final searchField = TextField(
      key: const ValueKey('final-results-search'),
      controller: _searchController,
      onChanged: (v) => setState(() {
        _searchQuery = v;
        _page = 0;
      }),
      decoration: InputDecoration(
        hintText: 'Tìm theo tên học sinh...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _page = 0;
                  });
                },
              )
            : null,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );

    final groupSelector = Wrap(
      spacing: AppSpacing.xs,
      children: [
        ChoiceChip(
          key: const ValueKey('group-tab-all'),
          label: Text('Tất cả ($totalCount)'),
          selected: _activeGroup == _ResultGroup.all,
          onSelected: (_) => setState(() {
            _activeGroup = _ResultGroup.all;
            _page = 0;
          }),
        ),
        ChoiceChip(
          key: const ValueKey('group-tab-exempted'),
          label: Text('Miễn môn ($exemptedCount)'),
          selected: _activeGroup == _ResultGroup.exempted,
          onSelected: (_) => setState(() {
            _activeGroup = _ResultGroup.exempted;
            _page = 0;
          }),
        ),
        ChoiceChip(
          key: const ValueKey('group-tab-skipped'),
          label: Text('Thiếu điểm ($skippedCount)'),
          selected: _activeGroup == _ResultGroup.skipped,
          onSelected: (_) => setState(() {
            _activeGroup = _ResultGroup.skipped;
            _page = 0;
          }),
        ),
      ],
    );

    final classificationDropdown = DropdownButtonFormField<String?>(
      key: const ValueKey('final-results-classification-filter'),
      initialValue: _classificationFilter,
      isDense: true,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Lọc xếp loại',
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Tất cả xếp loại')),
        for (final c in availableClassifications)
          DropdownMenuItem(
            value: c,
            child: Text(classificationLabel(c)),
          ),
      ],
      onChanged: (v) => setState(() {
        _classificationFilter = v;
        _page = 0;
      }),
    );

    final sortDropdown = DropdownButtonFormField<_ResultSort>(
      key: const ValueKey('final-results-sort'),
      initialValue: _sort,
      isDense: true,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Sắp xếp',
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(
          value: _ResultSort.sttAsc,
          child: Text('STT (tăng dần)'),
        ),
        DropdownMenuItem(
          value: _ResultSort.sttDesc,
          child: Text('STT (giảm dần)'),
        ),
        DropdownMenuItem(
          value: _ResultSort.scoreDesc,
          child: Text('ĐTB (cao → thấp)'),
        ),
        DropdownMenuItem(
          value: _ResultSort.scoreAsc,
          child: Text('ĐTB (thấp → cao)'),
        ),
      ],
      onChanged: (v) => setState(() {
        if (v != null) _sort = v;
      }),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                key: const ValueKey('mobile-filters-toggle'),
                onPressed: () =>
                    setState(() => _mobileFiltersOpen = !_mobileFiltersOpen),
                icon: Icon(
                  _mobileFiltersOpen
                      ? Icons.filter_alt_off
                      : Icons.filter_alt_outlined,
                  size: 18,
                ),
                label: const Text('Bộ lọc'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          groupSelector,
          if (_mobileFiltersOpen) ...[
            const SizedBox(height: AppSpacing.md),
            classificationDropdown,
            const SizedBox(height: AppSpacing.sm),
            sortDropdown,
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 3, child: searchField),
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: 2, child: classificationDropdown),
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: 2, child: sortDropdown),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        groupSelector,
      ],
    );
  }

  int _compareStudents(
    FinalResultDto a,
    FinalResultDto b,
    Map<num, num?> sttMap,
  ) {
    switch (_sort) {
      case _ResultSort.sttAsc:
        return _cmpStt(a, b, sttMap, true);
      case _ResultSort.sttDesc:
        return _cmpStt(a, b, sttMap, false);
      case _ResultSort.scoreDesc:
        final sa = double.tryParse(a.finalScore) ?? -1;
        final sb = double.tryParse(b.finalScore) ?? -1;
        final cmp = sb.compareTo(sa);
        return cmp != 0 ? cmp : _cmpStt(a, b, sttMap, true);
      case _ResultSort.scoreAsc:
        final sa = double.tryParse(a.finalScore) ?? -1;
        final sb = double.tryParse(b.finalScore) ?? -1;
        final cmp = sa.compareTo(sb);
        return cmp != 0 ? cmp : _cmpStt(a, b, sttMap, true);
    }
  }

  int _cmpStt(
    FinalResultDto a,
    FinalResultDto b,
    Map<num, num?> sttMap,
    bool asc,
  ) {
    final sttA = sttMap[a.studentId];
    final sttB = sttMap[b.studentId];
    int cmp;
    if (sttA != null && sttB != null) {
      cmp = sttA.compareTo(sttB);
    } else if (sttA != null && sttB == null) {
      cmp = -1;
    } else if (sttA == null && sttB != null) {
      cmp = 1;
    } else {
      cmp = a.studentId.compareTo(b.studentId);
    }
    return asc ? cmp : -cmp;
  }

  Widget _exemptedList(BuildContext context, List<ExemptedStudentDto> items) {
    final t = context.tokens;
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'Không có học sinh miễn môn',
        message: 'Tất cả học sinh trong bảng điểm đều tham gia đánh giá đầy đủ.',
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: t.subtle,
              child: Icon(Icons.person_outline, color: t.ink2, size: 20),
            ),
            title: Text(
              item.studentName,
              style: TextStyle(fontWeight: FontWeight.w600, color: t.ink),
            ),
            subtitle: Text(
              'Học sinh #${item.studentId}',
              style: TextStyle(color: t.ink3, fontSize: 12),
            ),
            trailing: const AppBadge(
              'Miễn môn',
              tone: AppBadgeTone.neutral,
              dot: false,
            ),
          ),
        );
      },
    );
  }

  Widget _skippedList(BuildContext context, List<SkippedStudentDto> items) {
    final t = context.tokens;
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'Không có học sinh thiếu điểm',
        message: 'Tất cả học sinh đều đã hoàn tất các cột điểm bắt buộc.',
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: t.warnSoft,
                      child: Icon(Icons.warning_amber_rounded,
                          color: t.warn, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.studentName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: t.ink,
                            ),
                          ),
                          Text(
                            'Học sinh #${item.studentId}',
                            style: TextStyle(color: t.ink3, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const AppBadge(
                      'Thiếu điểm',
                      tone: AppBadgeTone.bad,
                      dot: false,
                    ),
                  ],
                ),
                if (item.missingComponents.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Các cột còn thiếu:',
                        style: TextStyle(
                          fontSize: 12,
                          color: t.ink2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      for (final c in item.missingComponents)
                        AppBadge(c.name, tone: AppBadgeTone.bad),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _table(
    BuildContext context,
    List<FinalResultDto> items,
    Map<num, num?> sttMap,
    bool isMobile,
  ) {
    final t = context.tokens;

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: EmptyState(
          icon: Icons.search_off_outlined,
          title: 'Không tìm thấy kết quả',
          message: 'Không có học sinh nào khớp với điều kiện tìm kiếm hoặc lọc.',
        ),
      );
    }

    // Mobile layout: Danh sách thẻ
    if (isMobile) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, index) {
          final item = items[index];
          final rawStt = sttMap[item.studentId];
          final displayStt =
              rawStt != null ? '$rawStt' : '${index + 1 + _page * _pageSize}';

          return Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: t.subtle,
                    child: Text(
                      displayStt,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: t.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.studentName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: t.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'ĐTB: ',
                              style: TextStyle(color: t.ink2, fontSize: 13),
                            ),
                            Text(
                              item.finalScore,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: t.priLink,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _classificationBadge(item.classification),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: 'Lịch sử tính',
                    icon: const Icon(Icons.history, size: 20),
                    color: t.ink2,
                    onPressed: () => showHistory(item),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // Desktop/Tablet layout: Bảng kết quả gọn có tiêu đề cố định
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dataRowMinHeight: 48,
            dataRowMaxHeight: 56,
            columns: const [
              DataColumn(label: Text('STT')),
              DataColumn(label: Text('Học sinh')),
              DataColumn(label: Text('Điểm tổng kết')),
              DataColumn(label: Text('Xếp loại')),
              DataColumn(label: Text('Chi tiết')),
            ],
            rows: [
              for (var i = 0; i < items.length; i++)
                DataRow(
                  cells: [
                    DataCell(
                      Text(
                        sttMap[items[i].studentId] != null
                            ? '${sttMap[items[i].studentId]}'
                            : '${i + 1 + _page * _pageSize}',
                        style: TextStyle(color: t.ink3),
                      ),
                    ),
                    DataCell(
                      Text(
                        items[i].studentName,
                        style: TextStyle(
                          color: t.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        items[i].finalScore,
                        style: TextStyle(
                          color: t.ink,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    DataCell(
                      _classificationBadge(items[i].classification),
                    ),
                    DataCell(
                      IconButton(
                        tooltip: 'Lịch sử tính',
                        color: t.ink2,
                        onPressed: () => showHistory(items[i]),
                        icon: const Icon(Icons.history),
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

  Widget _pagination(BuildContext context, int totalItems) {
    final t = context.tokens;
    final totalPages = max(1, (totalItems / _pageSize).ceil());
    final start = totalItems == 0 ? 0 : _page * _pageSize + 1;
    final end = min((_page + 1) * _pageSize, totalItems);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hiển thị $start–$end / $totalItems học sinh',
            style: TextStyle(color: t.ink3, fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Trang trước',
                onPressed: _page > 0
                    ? () => setState(() => _page--)
                    : null,
              ),
              Text(
                'Trang ${_page + 1} / $totalPages',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                  fontSize: 13,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Trang sau',
                onPressed: _page < totalPages - 1
                    ? () => setState(() => _page++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context, CalculateFinalResultsDto summary) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('calculation-summary-card'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: t.subtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: t.priLink, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đã tính ${summary.calculatedStudents} học sinh; '
                  'bỏ qua ${summary.skippedStudents} học sinh.',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Đóng thông báo',
                onPressed: () => setState(() => _lastSummary = null),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          const SizedBox(height: AppSpacing.lg),
          if (_resultsOutdated) ...[
            Container(
              key: const ValueKey('results-outdated-banner'),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: t.warnSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: t.warnLine),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 20, color: t.warn),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Điểm đã được điều chỉnh — cần Tính kết quả lại',
                      style: TextStyle(
                        color: t.warn,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_lastSummary != null) _summaryCard(context, _lastSummary!),
          if (busy)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: LinearProgressIndicator(
                color: t.pri,
                backgroundColor: t.hover,
              ),
            ),
          if (!widget.showResults)
            Text(
              'Điểm tổng kết và xếp loại được hiển thị trực tiếp trong từng hàng của bảng điểm.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: t.ink2),
            ),
          if (widget.showResults)
            FutureBuilder<FinalResultListDto>(
              future: results,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _stateMessage(
                    context,
                    _message(snapshot.error!),
                    action: TextButton(
                      onPressed: reload,
                      child: const Text('Thử lại'),
                    ),
                  );
                }
                final listDto = snapshot.data!;
                final rawItems = listDto.items;
                final exemptedList = listDto.exempted;
                final skippedList = listDto.skipped;
                final exemptedCount = max(
                  listDto.exemptedStudents.toInt(),
                  exemptedList.length,
                );
                final skippedCount = max(
                  listDto.skippedStudents.toInt(),
                  skippedList.length,
                );

                if (rawItems.isEmpty &&
                    exemptedList.isEmpty &&
                    skippedList.isEmpty) {
                  return _stateMessage(
                    context,
                    'Chưa tính kết quả cho bảng điểm này.',
                  );
                }

                return FutureBuilder<Map<num, num?>>(
                  future: _studentSttFuture,
                  builder: (context, sttSnapshot) {
                    final sttMap = sttSnapshot.data ?? const {};

                    // Thu thập danh sách mã xếp loại có sẵn để lọc
                    final availableClassifications = rawItems
                        .map((i) => i.classification.trim().toUpperCase())
                        .toSet()
                        .toList()
                      ..sort();

                    // Dòng thông tin chung duy nhất phía trên bảng
                    final metaSummaryWidget = rawItems.isNotEmpty
                        ? _metaSummary(context, rawItems.first)
                        : const SizedBox.shrink();

                    // Lọc và sắp xếp nhóm "Tất cả"
                    final query = _searchQuery.trim().toLowerCase();
                    final filteredAll = rawItems.where((item) {
                      if (query.isNotEmpty &&
                          !item.studentName.toLowerCase().contains(query)) {
                        return false;
                      }
                      if (_classificationFilter != null &&
                          item.classification.trim().toUpperCase() !=
                              _classificationFilter) {
                        return false;
                      }
                      return true;
                    }).toList()
                      ..sort((a, b) => _compareStudents(a, b, sttMap));

                    final totalPages =
                        max(1, (filteredAll.length / _pageSize).ceil());
                    if (_page >= totalPages) _page = totalPages - 1;
                    if (_page < 0) _page = 0;

                    final pagedItems = filteredAll
                        .skip(_page * _pageSize)
                        .take(_pageSize)
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        metaSummaryWidget,
                        _toolbar(
                          context,
                          totalCount: rawItems.length,
                          exemptedCount: exemptedCount,
                          skippedCount: skippedCount,
                          availableClassifications: availableClassifications,
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_activeGroup == _ResultGroup.exempted)
                          _exemptedList(context, exemptedList)
                        else if (_activeGroup == _ResultGroup.skipped)
                          _skippedList(context, skippedList)
                        else ...[
                          _table(context, pagedItems, sttMap, isMobile),
                          if (filteredAll.length > _pageSize)
                            _pagination(context, filteredAll.length),
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
  }
}

class _FinalResultHistoryDialog extends ConsumerWidget {
  const _FinalResultHistoryDialog({
    required this.gradebookId,
    required this.result,
  });

  final num gradebookId;
  final FinalResultDto result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return AppDialog(
      title: 'Lịch sử tổng kết · ${result.studentName}',
      maxWidth: 620,
      showFooter: false,
      child: FutureBuilder<List<CalculationHistoryDto>>(
        future: ref
            .read(finalResultsRepositoryProvider)
            .history(gradebookId: gradebookId, resultId: result.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'Không tải được lịch sử.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: t.ink2),
                ),
              ),
            );
          }
          final items = snapshot.data!;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) Divider(color: t.line, height: AppSpacing.xxl),
                _historyEntry(context, items[i]),
              ],
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _historyEntry(BuildContext context, CalculationHistoryDto item) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${item.oldScore ?? 'Chưa có'} → ${item.newScore} · '
          '${classificationLabel(item.newClassification)}',
          style: theme.textTheme.titleSmall?.copyWith(
            color: t.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          item.reason,
          style: theme.textTheme.bodyMedium?.copyWith(color: t.ink2),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Người tính #${item.calculatorId} · '
          '${_formatDateTime(item.calculatedAt)}',
          style: theme.textTheme.bodySmall?.copyWith(color: t.ink3),
        ),
      ],
    );
  }
}
