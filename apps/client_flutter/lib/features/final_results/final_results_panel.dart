import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_dialog.dart';
import '../authentication/session.dart';
import 'repository.dart';
import 'student_results_screen.dart' show classificationBadgeOf;

/// Định dạng `dd/MM/yyyy HH:mm` theo giờ máy (không thêm package `intl`).
String _formatDateTime(DateTime value) {
  final d = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

/// Xếp loại hiển thị theo MÃ backend trả về, không so ngưỡng điểm ở client.
Widget _classificationBadge(String code) {
  final badge = classificationBadgeOf(code);
  return AppBadge(badge.label, tone: badge.tone);
}

class FinalResultsPanel extends ConsumerStatefulWidget {
  const FinalResultsPanel({
    super.key,
    required this.gradebookId,
    required this.gradebookVersion,
    this.showResults = true,
  });

  final num gradebookId;
  final num gradebookVersion;
  final bool showResults;

  @override
  ConsumerState<FinalResultsPanel> createState() => _FinalResultsPanelState();
}

class _FinalResultsPanelState extends ConsumerState<FinalResultsPanel> {
  late Future<List<FinalResultDto>> results;
  bool busy = false;

  bool get teacher => ref.read(sessionProvider)?.role.value == 'GIAO_VIEN';

  @override
  void initState() {
    super.initState();
    results = ref.read(finalResultsRepositoryProvider).list(widget.gradebookId);
  }

  void reload() => setState(() {
    busy = false;
    results = ref.read(finalResultsRepositoryProvider).list(widget.gradebookId);
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

  Widget _table(BuildContext context, List<FinalResultDto> items) {
    final t = context.tokens;
    final small = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: t.ink3);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              dataRowMinHeight: 56,
              dataRowMaxHeight: double.infinity,
              columns: const [
                DataColumn(label: Text('STT')),
                DataColumn(label: Text('Học sinh')),
                DataColumn(label: Text('Điểm tổng kết')),
                DataColumn(label: Text('Xếp loại')),
                DataColumn(label: Text('Chi tiết')),
              ],
              rows: [
                for (final entry in items.asMap().entries)
                  DataRow(
                    cells: [
                      DataCell(
                        Text(
                          '${entry.key + 1}',
                          style: TextStyle(color: t.ink3),
                        ),
                      ),
                      DataCell(
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value.studentName,
                              style: TextStyle(
                                color: t.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Hệ số ${entry.value.weightVersion} · '
                              'Chính sách ${entry.value.policyVersion}',
                              style: small,
                            ),
                            Text(
                              'Tính lúc '
                              '${_formatDateTime(entry.value.calculatedAt)}',
                              style: small,
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          entry.value.finalScore,
                          style: TextStyle(
                            color: t.ink,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      DataCell(
                        _classificationBadge(entry.value.classification),
                      ),
                      DataCell(
                        IconButton(
                          tooltip: 'Lịch sử tính',
                          color: t.ink2,
                          onPressed: () => showHistory(entry.value),
                          icon: const Icon(Icons.history),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          const SizedBox(height: AppSpacing.lg),
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
            SizedBox(
              height: 320,
              child: FutureBuilder<List<FinalResultDto>>(
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
                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return _stateMessage(
                      context,
                      'Chưa tính kết quả cho bảng điểm này.',
                    );
                  }
                  return _table(context, items);
                },
              ),
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
          '${item.newClassification}',
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
