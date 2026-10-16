import 'package:api_client_dart/api_client_dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_charts.dart';
import '../../app/widgets/stat_card.dart';
import '../authentication/session.dart';
import '../final_results/student_results_screen.dart'
    show classificationBadgeOf;
import 'repository.dart';

class ReportsPanel extends ConsumerStatefulWidget {
  const ReportsPanel({
    super.key,
    required this.gradebookId,
    this.compact = false,
  });

  final num gradebookId;
  final bool compact;

  @override
  ConsumerState<ReportsPanel> createState() => _ReportsPanelState();
}

class _ReportsPanelState extends ConsumerState<ReportsPanel> {
  late Future<GradebookSummaryDto> summary;
  bool exporting = false;

  @override
  void initState() {
    super.initState();
    summary = ref.read(reportsRepositoryProvider).summary(widget.gradebookId);
  }

  Future<void> export() async {
    setState(() => exporting = true);
    try {
      final bytes = await ref
          .read(reportsRepositoryProvider)
          .export(widget.gradebookId);
      final path = await FilePicker.saveFile(
        dialogTitle: 'Lưu báo cáo Excel',
        fileName: 'bang-diem-${widget.gradebookId}.xlsx',
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        bytes: bytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'Đã hủy lưu báo cáo.'
                : 'Đã xuất báo cáo Excel thành công.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: FutureBuilder<GradebookSummaryDto>(
          future: summary,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  LinearProgressIndicator(
                    color: t.pri,
                    backgroundColor: t.hover,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            }
            if (snapshot.hasError) {
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      errorMessage(snapshot.error!),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: t.ink2,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      summary = ref
                          .read(reportsRepositoryProvider)
                          .summary(widget.gradebookId);
                    }),
                    child: const Text('Thử lại'),
                  ),
                ],
              );
            }
            final data = snapshot.data!;
            if (widget.compact) {
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded, color: t.priLink),
                  Text(
                    'Thống kê · ${data.students} HS · '
                    'ĐTB lớp ${data.average ?? '—'} · '
                    'Cao nhất ${data.highest ?? '—'} · '
                    'Thấp nhất ${data.lowest ?? '—'}',
                    style: theme.textTheme.labelLarge?.copyWith(color: t.ink),
                  ),
                  _exportButton(),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context),
                const SizedBox(height: AppSpacing.xl),
                _stats(data),
                if (data.distribution.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Divider(color: t.line),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Phân bố xếp loại:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: t.ink2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _distribution(context, data.distribution),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _exportButton() => FilledButton.tonalIcon(
    key: const ValueKey('export-xlsx'),
    onPressed: exporting ? null : export,
    icon: exporting
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.download_rounded, size: 18),
    label: const Text('Xuất Excel'),
  );

  Widget _header(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.md,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: t.priSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.bar_chart_rounded,
                    size: 20,
                    color: t.priLink,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thống kê · Báo cáo kết quả',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: t.ink,
                      ),
                    ),
                    Text(
                      'Dữ liệu tổng hợp từ các điểm chính thức đã duyệt',
                      style: theme.textTheme.bodySmall?.copyWith(color: t.ink3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _exportButton(),
      ],
    );
  }

  /// Sáu thẻ số liệu lấy nguyên từ `GradebookSummaryDto`. Từ 720 px xếp 3 cột
  /// (hai hàng), hẹp hơn xếp 2 cột.
  Widget _stats(GradebookSummaryDto data) {
    final cards = <Widget>[
      StatCard(
        title: 'Sĩ số học sinh',
        value: '${data.students}',
        icon: Icons.people_alt_outlined,
      ),
      StatCard(
        title: 'ĐTB lớp',
        value: data.average ?? '—',
        icon: Icons.analytics_outlined,
      ),
      StatCard(
        title: 'Cao nhất',
        value: data.highest ?? '—',
        icon: Icons.arrow_upward_rounded,
        tone: StatTone.ok,
      ),
      StatCard(
        title: 'Thấp nhất',
        value: data.lowest ?? '—',
        icon: Icons.arrow_downward_rounded,
        tone: StatTone.warn,
      ),
      StatCard(
        title: 'Đạt yêu cầu',
        value: '${data.passed}',
        icon: Icons.check_circle_outline,
        tone: StatTone.ok,
      ),
      StatCard(
        title: 'Chưa đạt',
        value: '${data.failed}',
        icon: Icons.cancel_outlined,
        tone: StatTone.bad,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) return StatCardGrid(children: cards);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatCardGrid(breakpoint: 0, children: cards.sublist(0, 3)),
            const SizedBox(height: AppSpacing.md),
            StatCardGrid(breakpoint: 0, children: cards.sublist(3)),
          ],
        );
      },
    );
  }

  /// Màu cột theo mã xếp loại backend trả về (cùng quy ước với biểu đồ phân
  /// bố ở dashboard); mã không nhận ra dùng màu trung tính.
  Color _barColor(AppTokens t, String code) {
    switch (code.trim().toUpperCase()) {
      case 'GIOI':
      case 'GIỎI':
        return t.pri;
      case 'KHA':
      case 'KHÁ':
        return t.brightness == Brightness.dark
            ? t.priLink
            : Color.lerp(t.pri, t.priLine, 0.45)!;
      case 'CHUA_DAT':
      case 'CHƯA ĐẠT':
      case 'KHONG_DAT':
      case 'KHÔNG ĐẠT':
      case 'YEU':
      case 'YẾU':
      case 'KEM':
      case 'KÉM':
        return t.bad;
      default:
        return t.neu;
    }
  }

  Widget _distribution(BuildContext context, List<DistributionItemDto> items) {
    final t = context.tokens;
    return AppHBars(
      labelWidth: 84,
      valueWidth: 64,
      items: [
        for (final item in items)
          AppHBarItem(
            label: classificationBadgeOf(item.classification).label,
            value: item.students.toDouble(),
            valueText: '${item.students} HS',
            color: _barColor(t, item.classification),
          ),
      ],
    );
  }
}
