import 'dart:async';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../app/widgets/shimmer_loading.dart';
import 'batch_repository.dart';
import 'cancel_batch_dialog.dart';
import 'review_screen.dart';

/// Mở màn kết quả lô: bằng GoRouter khi có, không thì bằng Navigator (test,
/// panel nhúng ngoài ứng dụng).
Future<void> openBatchResult(
  BuildContext context, {
  required num gradebookId,
  required String batchId,
}) async {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    await context.push<void>(
      '/gradebooks/$gradebookId/recognition-batches/$batchId',
    );
    return;
  }
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) =>
          BatchResultScreen(gradebookId: gradebookId, batchId: batchId),
    ),
  );
}

/// Kết quả một lô nhận dạng (ADR-0016 mục 5, giáo viên bước 5): mỗi thành phần
/// là một tab có số Xanh/Vàng/Đỏ; bấm tab mở màn đối chiếu hiện có của đúng
/// phiếu đó. Màn đối chiếu không bị viết lại, duyệt vẫn theo từng phiếu.
class BatchResultScreen extends ConsumerStatefulWidget {
  const BatchResultScreen({
    super.key,
    required this.gradebookId,
    required this.batchId,
  });

  final num gradebookId;
  final String batchId;

  @override
  ConsumerState<BatchResultScreen> createState() => _BatchResultScreenState();
}

class _BatchResultScreenState extends ConsumerState<BatchResultScreen> {
  late Future<RecognitionBatchDto> future;
  Timer? _pollTimer;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<RecognitionBatchDto> _load() async {
    _pollTimer?.cancel();
    final data = await ref
        .read(recognitionBatchRepositoryProvider)
        .detail(gradebookId: widget.gradebookId, batchId: widget.batchId);
    if (mounted && data.status == RecognitionBatchDtoStatusEnum.DANG_XU_LY) {
      _pollTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => future = _load());
      });
    }
    return data;
  }

  void _reload() => setState(() => future = _load());

  Future<void> _openReview(RecognitionBatchTicketDto ticket) async {
    final gradebookId = widget.gradebookId;
    bool? approved;
    // Không truyền phiên bản bảng điểm: sau mỗi phiếu được duyệt phiên bản đổi,
    // để màn đối chiếu tự lấy phiên bản hiện hành.
    if (GoRouter.maybeOf(context) != null) {
      approved = await context.push<bool>(
        '/gradebooks/$gradebookId/recognition/${ticket.ticketId}?batch=1',
      );
    } else {
      approved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ReviewScreen(
            gradebookId: gradebookId,
            ticketId: ticket.ticketId,
            showPageLabels: true,
          ),
        ),
      );
    }
    if (!mounted) return;
    if (approved == true) {
      ref.read(batchApprovalTickProvider(gradebookId).notifier).state++;
    }
    _reload();
  }

  static bool _reviewable(RecognitionBatchTicketDto ticket) =>
      ticket.status == RecognitionBatchTicketDtoStatusEnum.CHO_DOI_CHIEU ||
      ticket.status == RecognitionBatchTicketDtoStatusEnum.DA_DUYET;

  Future<void> _cancelBatch() async {
    final cancelled = await showCancelBatchDialog(
      context: context,
      gradebookId: widget.gradebookId,
      batchId: widget.batchId,
    );
    if (cancelled == true && mounted) {
      ref.read(trackedBatchProvider(widget.gradebookId).notifier).state = null;
      _reload();
    }
  }

  String _templateName(RecognitionBatchDto batch) {
    final info = ref.watch(batchTicketInfoProvider);
    for (final ticket in batch.tickets) {
      final name = info[ticket.ticketId]?.templateName;
      if (name != null) return name;
    }
    final templates = ref.watch(activeTemplatesProvider).valueOrNull;
    for (final template in templates ?? const <TemplateSummaryDto>[]) {
      if (template.id == batch.templateId) return template.name;
    }
    return 'Mẫu #${batch.templateId.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppScaffold(
      key: const ValueKey('batch-result-screen'),
      title: 'Kết quả lô #${widget.batchId}',
      currentPath: '/gradebooks',
      showBackButton: true,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: FutureBuilder<RecognitionBatchDto>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  key: ValueKey('batch-result-loading'),
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: ShimmerLoading(itemCount: 3, itemHeight: 88),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          batchErrorMessage(snapshot.error!),
                          key: const ValueKey('batch-result-error'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: t.ink2),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          key: const ValueKey('batch-result-retry'),
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tải lại lô'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return _content(context, snapshot.data!);
            },
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, RecognitionBatchDto batch) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final tickets = batch.tickets;
    final index = selectedIndex.clamp(
      0,
      tickets.isEmpty ? 0 : tickets.length - 1,
    );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Lô nhận dạng #${batch.batchId}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: t.ink,
              ),
            ),
            _batchBadge(batch.status),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_templateName(batch)} · ${batch.pageCount.toInt()} trang · ${tickets.length} cột',
          key: const ValueKey('batch-result-summary'),
          style: theme.textTheme.bodyMedium?.copyWith(color: t.ink2),
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._statusBlock(context, batch),
        if (tickets.isNotEmpty) ...[
          _BatchTabs(
            tickets: tickets,
            selectedIndex: index,
            onSelected: (i) {
              setState(() => selectedIndex = i);
              if (_reviewable(tickets[i])) _openReview(tickets[i]);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _ticketPanel(context, tickets[index]),
        ],
      ],
    );
  }

  Widget _batchBadge(RecognitionBatchDtoStatusEnum status) => switch (status) {
    RecognitionBatchDtoStatusEnum.DANG_XU_LY => const AppBadge.info(
      'Đang xử lý',
    ),
    RecognitionBatchDtoStatusEnum.XONG => const AppBadge.ok(
      'Đã nhận dạng xong',
    ),
    RecognitionBatchDtoStatusEnum.LOI => const AppBadge.bad('Lỗi'),
    RecognitionBatchDtoStatusEnum.DA_HUY => const AppBadge('Đã hủy'),
  };

  List<Widget> _statusBlock(BuildContext context, RecognitionBatchDto batch) {
    final theme = Theme.of(context);
    final t = context.tokens;
    switch (batch.status) {
      case RecognitionBatchDtoStatusEnum.DANG_XU_LY:
        return [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: t.pri),
              ),
              Text(
                'Đang nhận dạng, tự động cập nhật sau 3 giây.',
                style: theme.textTheme.bodyMedium,
              ),
              OutlinedButton.icon(
                key: const ValueKey('batch-result-cancel'),
                onPressed: _cancelBatch,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Hủy lô'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  foregroundColor: t.bad,
                  side: BorderSide(color: t.bad),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ];
      case RecognitionBatchDtoStatusEnum.LOI:
        return [
          Text(
            batchFailureMessage(batch.errorCode, batch.errorPage),
            key: const ValueKey('batch-result-failure'),
            style: theme.textTheme.bodyMedium?.copyWith(color: t.bad),
          ),
          const SizedBox(height: AppSpacing.lg),
        ];
      case RecognitionBatchDtoStatusEnum.DA_HUY:
        return [
          Text(
            batch.cancelReason == null || batch.cancelReason!.isEmpty
                ? 'Lô đã bị hủy.'
                : 'Lô đã bị hủy. Lý do: ${batch.cancelReason}',
            key: const ValueKey('batch-result-cancelled'),
            style: theme.textTheme.bodyMedium?.copyWith(color: t.ink2),
          ),
          const SizedBox(height: AppSpacing.lg),
        ];
      case RecognitionBatchDtoStatusEnum.XONG:
        return const [];
    }
  }

  Widget _ticketPanel(BuildContext context, RecognitionBatchTicketDto ticket) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final reviewable = _reviewable(ticket);
    return Container(
      key: ValueKey('batch-ticket-panel-${ticket.ticketId}'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Phiếu #${ticket.ticketId} · ${ticket.componentName}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: t.ink,
                ),
              ),
              _ticketBadge(ticket.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Cột mẫu số ${ticket.templateColumnIndex.toInt()}',
            style: theme.textTheme.bodySmall,
          ),
          if (ticket.status == RecognitionBatchTicketDtoStatusEnum.LOI) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              batchFailureMessage(ticket.errorCode, null),
              style: theme.textTheme.bodyMedium?.copyWith(color: t.bad),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              key: ValueKey('batch-open-review-${ticket.ticketId}'),
              onPressed: reviewable ? () => _openReview(ticket) : null,
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: Text(
                ticket.status == RecognitionBatchTicketDtoStatusEnum.DA_DUYET
                    ? 'Xem phiếu đã duyệt'
                    : 'Đối chiếu phiếu này',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketBadge(RecognitionBatchTicketDtoStatusEnum status) =>
      switch (status) {
        RecognitionBatchTicketDtoStatusEnum.DANG_XU_LY => const AppBadge.info(
          'Đang xử lý',
        ),
        RecognitionBatchTicketDtoStatusEnum.CHO_DOI_CHIEU =>
          const AppBadge.warn('Chờ đối chiếu'),
        RecognitionBatchTicketDtoStatusEnum.DA_DUYET => const AppBadge.ok(
          'Đã duyệt',
        ),
        RecognitionBatchTicketDtoStatusEnum.LOI => const AppBadge.bad('Lỗi'),
        RecognitionBatchTicketDtoStatusEnum.DA_HUY => const AppBadge('Đã hủy'),
      };
}

/// Thanh tab theo thành phần: tên thành phần và số Xanh/Vàng/Đỏ của phiếu.
class _BatchTabs extends StatelessWidget {
  const _BatchTabs({
    required this.tickets,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<RecognitionBatchTicketDto> tickets;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 1,
          child: ColoredBox(color: t.line),
        ),
        SingleChildScrollView(
          key: const ValueKey('batch-tabs'),
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < tickets.length; i++)
                _tab(context, i, tickets[i]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tab(BuildContext context, int i, RecognitionBatchTicketDto ticket) {
    final t = context.tokens;
    final selected = i == selectedIndex;
    final cancelled =
        ticket.status == RecognitionBatchTicketDtoStatusEnum.DA_HUY;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: ValueKey('batch-tab-${ticket.ticketId}'),
        onTap: () => onSelected(i),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56, maxWidth: 260),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? t.pri : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.componentName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? t.priLink : (cancelled ? t.ink3 : t.ink2),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  AppBadge.ok(
                    '${ticket.greenRows.toInt()} Xanh',
                    key: ValueKey('batch-tab-green-${ticket.ticketId}'),
                    dot: false,
                  ),
                  AppBadge.warn(
                    '${ticket.yellowRows.toInt()} Vàng',
                    key: ValueKey('batch-tab-yellow-${ticket.ticketId}'),
                    dot: false,
                  ),
                  AppBadge.bad(
                    '${ticket.redRows.toInt()} Đỏ',
                    key: ValueKey('batch-tab-red-${ticket.ticketId}'),
                    dot: false,
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
