import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_dialog.dart';
import '../../app/widgets/app_scaffold.dart';
import '../academic_catalog/semester_deadlines_repository.dart'
    show apiErrorCode;
import '../authentication/session.dart';
import 'adjustments_repository.dart';

String formatAdjustmentDateTime(DateTime dt) {
  final d = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

Widget adjustmentStatusBadge(AdjustmentDtoStatusEnum status) {
  return switch (status) {
    AdjustmentDtoStatusEnum.CHO_DUYET =>
      const AppBadge('Chờ duyệt', tone: AppBadgeTone.warn),
    AdjustmentDtoStatusEnum.DA_DUYET =>
      const AppBadge('Đã duyệt', tone: AppBadgeTone.ok),
    AdjustmentDtoStatusEnum.TU_CHOI =>
      const AppBadge('Từ chối', tone: AppBadgeTone.bad),
    AdjustmentDtoStatusEnum.DA_HUY =>
      const AppBadge('Đã hủy', tone: AppBadgeTone.neutral),
  };
}

/// Hộp thoại hiển thị chi tiết phiếu điều chỉnh điểm kèm danh sách dòng.
/// Hỗ trợ Quản trị viên duyệt / từ chối và Giáo viên hủy phiếu.
class AdjustmentDetailDialog extends ConsumerStatefulWidget {
  const AdjustmentDetailDialog({
    super.key,
    required this.adjId,
    this.initialAdjustment,
    this.allowDecide = false,
    this.allowCancel = false,
  });

  final String adjId;
  final AdjustmentDto? initialAdjustment;
  final bool allowDecide;
  final bool allowCancel;

  @override
  ConsumerState<AdjustmentDetailDialog> createState() =>
      _AdjustmentDetailDialogState();
}

class _AdjustmentDetailDialogState
    extends ConsumerState<AdjustmentDetailDialog> {
  late Future<AdjustmentDto> _future;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref.read(adjustmentsRepositoryProvider).getDetail(widget.adjId);
  }

  Future<void> _approve(AdjustmentDto adj) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Xác nhận duyệt phiếu',
        confirmLabel: 'Xác nhận duyệt',
        cancelLabel: 'Hủy',
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
        child: Text(
          'Ghi ${adj.lineCount} ô vào điểm chính thức và đánh dấu cần tính lại tổng kết.',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _acting = true);
    try {
      await ref.read(adjustmentsRepositoryProvider).approve(
            adjId: adj.id,
            expectedVersion: adj.version,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã duyệt phiếu điều chỉnh #${adj.id} thành công.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      final msg = apiErrorCode(e) == 'ADJUSTMENT_STALE'
          ? 'Điểm đã thay đổi sau khi gửi phiếu; yêu cầu giáo viên soạn lại'
          : adjustmentErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _reject(AdjustmentDto adj) async {
    var reason = '';
    String? error;
    final confirmed = await showAppDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AppDialog(
          title: 'Từ chối phiếu điều chỉnh',
          confirmLabel: 'Từ chối phiếu',
          cancelLabel: 'Hủy',
          onConfirm: () {
            final normalized = reason.trim();
            if (normalized.isEmpty) {
              setDialogState(() => error = 'Cần nhập lý do từ chối.');
              return;
            }
            Navigator.pop(ctx, normalized);
          },
          onCancel: () => Navigator.pop(ctx),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Vui lòng nhập lý do từ chối để giáo viên nắm rõ và chỉnh sửa lại:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                maxLength: 500,
                maxLines: 3,
                key: const ValueKey('adjustment-reject-reason-input'),
                onChanged: (val) => reason = val,
                decoration: InputDecoration(
                  labelText: 'Lý do từ chối *',
                  hintText: 'Nhập lý do từ chối phiếu...',
                  errorText: error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == null || confirmed.isEmpty || !mounted) return;

    setState(() => _acting = true);
    try {
      await ref.read(adjustmentsRepositoryProvider).reject(
            adjId: adj.id,
            expectedVersion: adj.version,
            reason: confirmed,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã từ chối phiếu điều chỉnh #${adj.id}.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      final msg = apiErrorCode(e) == 'ADJUSTMENT_STALE'
          ? 'Điểm đã thay đổi sau khi gửi phiếu; yêu cầu giáo viên soạn lại'
          : adjustmentErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _cancel(AdjustmentDto adj) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Hủy phiếu điều chỉnh',
        confirmLabel: 'Xác nhận hủy',
        cancelLabel: 'Đóng',
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
        child: const Text(
          'Bạn có chắc chắn muốn hủy phiếu điều chỉnh này không? Thao tác không thể hoàn tác.',
          style: TextStyle(fontSize: 14),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _acting = true);
    try {
      await ref.read(adjustmentsRepositoryProvider).cancel(
            adjId: adj.id,
            expectedVersion: adj.version,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy phiếu điều chỉnh thành công.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(adjustmentErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppDialog(
      title: 'Chi tiết phiếu điều chỉnh',
      maxWidth: 780,
      cancelLabel: 'Đóng',
      onCancel: () => Navigator.pop(context),
      child: FutureBuilder<AdjustmentDto>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(
                    'Lỗi khi tải thông tin phiếu: ${adjustmentErrorMessage(snapshot.error!)}',
                    style: TextStyle(color: t.bad, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => setState(_load),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final adj = snapshot.data!;
          final isPending = adj.status == AdjustmentDtoStatusEnum.CHO_DUYET;
          final lines = adj.lines ?? const [];

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.subtle,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: t.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Phiếu #${adj.id}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: t.ink,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        adjustmentStatusBadge(adj.status),
                        const Spacer(),
                        Text(
                          '${adj.lineCount} ô điều chỉnh',
                          style: TextStyle(
                            color: t.ink2,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        Text('Lớp: ${adj.className}',
                            style: TextStyle(color: t.ink2, fontSize: 13)),
                        Text('Môn: ${adj.subjectName}',
                            style: TextStyle(color: t.ink2, fontSize: 13)),
                        Text('Học kỳ: ${adj.termName}',
                            style: TextStyle(color: t.ink2, fontSize: 13)),
                        Text('Giáo viên: ${adj.submittedBy.name}',
                            style: TextStyle(color: t.ink2, fontSize: 13)),
                        Text('Gửi lúc: ${formatAdjustmentDateTime(adj.submittedAt)}',
                            style: TextStyle(color: t.ink3, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lý do chung: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: t.ink,
                            fontSize: 13,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            adj.reason,
                            style: TextStyle(color: t.ink, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    if (adj.decidedBy != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Người duyệt: ${adj.decidedBy!.name} • Lúc: ${adj.decidedAt != null ? formatAdjustmentDateTime(adj.decidedAt!) : ''}',
                        style: TextStyle(color: t.ink2, fontSize: 12),
                      ),
                      if (adj.decisionReason != null &&
                          adj.decisionReason!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Lý do quyết định: ${adj.decisionReason}',
                          style: TextStyle(
                            color: adj.status == AdjustmentDtoStatusEnum.TU_CHOI
                                ? t.bad
                                : t.ink,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Danh sách ô điều chỉnh (${lines.length}):',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: t.ink,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: t.line),
                  ),
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 36,
                        dataRowMinHeight: 36,
                        dataRowMaxHeight: 48,
                        columns: const [
                          DataColumn(label: Text('Học sinh')),
                          DataColumn(label: Text('Cột điểm')),
                          DataColumn(label: Text('Cũ')),
                          DataColumn(label: Text('Mới')),
                          DataColumn(label: Text('Ghi chú')),
                        ],
                        rows: lines.map((line) {
                          final oldText = line.oldStatus.value == 'MIEN'
                              ? 'Miễn'
                              : (line.oldValue ?? '—');
                          final newText =
                              line.newExempt ? 'Miễn' : (line.newValue ?? '—');
                          return DataRow(
                            cells: [
                              DataCell(Text(line.studentName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: t.ink,
                                  ))),
                              DataCell(Text(line.componentName,
                                  style: TextStyle(color: t.ink2))),
                              DataCell(Text(oldText,
                                  style: TextStyle(color: t.ink3))),
                              DataCell(Text(newText,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: t.priLink,
                                  ))),
                              DataCell(Text(line.note ?? '—',
                                  style: TextStyle(
                                    color: t.ink2,
                                    fontStyle: line.note == null
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              if (_acting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
              if (isPending && (widget.allowDecide || widget.allowCancel)) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.allowCancel)
                      OutlinedButton.icon(
                        key: const ValueKey('adjustment-cancel-btn'),
                        onPressed: _acting ? null : () => _cancel(adj),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Hủy phiếu'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: t.bad,
                        ),
                      ),
                    if (widget.allowDecide) ...[
                      OutlinedButton.icon(
                        key: const ValueKey('adjustment-reject-btn'),
                        onPressed: _acting ? null : () => _reject(adj),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Từ chối'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: t.bad,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        key: const ValueKey('adjustment-approve-btn'),
                        onPressed: _acting ? null : () => _approve(adj),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Duyệt'),
                        style: FilledButton.styleFrom(
                          backgroundColor: t.ok,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Màn hình Quản trị viên: Duyệt điều chỉnh điểm
class AdjustmentsScreen extends ConsumerStatefulWidget {
  const AdjustmentsScreen({super.key});

  @override
  ConsumerState<AdjustmentsScreen> createState() => _AdjustmentsScreenState();
}

class _AdjustmentsScreenState extends ConsumerState<AdjustmentsScreen> {
  AdjustmentDtoStatusEnum _status = AdjustmentDtoStatusEnum.CHO_DUYET;
  final List<AdjustmentDto> _items = [];
  String? _nextCursor;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPage(refresh: true);
  }

  Future<void> _fetchPage({bool refresh = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      if (refresh) {
        _items.clear();
        _nextCursor = null;
        _error = null;
      }
    });

    try {
      final page = await ref.read(adjustmentsRepositoryProvider).listAdjustments(
            status: _status,
            cursor: _nextCursor,
          );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _nextCursor = page.nextCursor;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = adjustmentErrorMessage(e);
      });
    }
  }

  void _openDetail(AdjustmentDto item) async {
    final updated = await showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdjustmentDetailDialog(
        adjId: item.id,
        initialAdjustment: item,
        allowDecide: true,
      ),
    );
    if (updated == true) {
      _fetchPage(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isQtv = ref.watch(sessionProvider)?.role.value == 'QUAN_TRI_VIEN';

    return AppScaffold(
      title: 'Duyệt điều chỉnh điểm',
      actions: [
        IconButton(
          key: const ValueKey('refresh-adjustments-btn'),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Tải lại',
          onPressed: () => _fetchPage(refresh: true),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Trạng thái: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: t.ink,
                    fontSize: 13,
                  ),
                ),
                ChoiceChip(
                  key: const ValueKey('filter-CHO_DUYET'),
                  label: const Text('Chờ duyệt'),
                  selected: _status == AdjustmentDtoStatusEnum.CHO_DUYET,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _status = AdjustmentDtoStatusEnum.CHO_DUYET);
                      _fetchPage(refresh: true);
                    }
                  },
                ),
                ChoiceChip(
                  key: const ValueKey('filter-DA_DUYET'),
                  label: const Text('Đã duyệt'),
                  selected: _status == AdjustmentDtoStatusEnum.DA_DUYET,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _status = AdjustmentDtoStatusEnum.DA_DUYET);
                      _fetchPage(refresh: true);
                    }
                  },
                ),
                ChoiceChip(
                  key: const ValueKey('filter-TU_CHOI'),
                  label: const Text('Từ chối'),
                  selected: _status == AdjustmentDtoStatusEnum.TU_CHOI,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _status = AdjustmentDtoStatusEnum.TU_CHOI);
                      _fetchPage(refresh: true);
                    }
                  },
                ),
                ChoiceChip(
                  key: const ValueKey('filter-DA_HUY'),
                  label: const Text('Đã hủy'),
                  selected: _status == AdjustmentDtoStatusEnum.DA_HUY,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _status = AdjustmentDtoStatusEnum.DA_HUY);
                      _fetchPage(refresh: true);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.badSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: t.badLine),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: t.bad, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: t.bad, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _fetchPage(refresh: true),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            if (_items.isEmpty && !_loading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 48),
                alignment: Alignment.center,
                child: Text(
                  'Không có phiếu điều chỉnh nào ở trạng thái này.',
                  style: TextStyle(color: t.ink2, fontSize: 14),
                ),
              )
            else
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Lớp')),
                      DataColumn(label: Text('Môn')),
                      DataColumn(label: Text('Học kỳ')),
                      DataColumn(label: Text('Giáo viên')),
                      DataColumn(label: Text('Số ô')),
                      DataColumn(label: Text('Gửi lúc')),
                      DataColumn(label: Text('Trạng thái')),
                      DataColumn(label: Text('Thao tác')),
                    ],
                    rows: _items.map((item) {
                      return DataRow(
                        key: ValueKey('adjustment-row-${item.id}'),
                        cells: [
                          DataCell(Text(item.className,
                              style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(item.subjectName)),
                          DataCell(Text(item.termName)),
                          DataCell(Text(item.submittedBy.name)),
                          DataCell(Text('${item.lineCount}')),
                          DataCell(Text(formatAdjustmentDateTime(item.submittedAt))),
                          DataCell(adjustmentStatusBadge(item.status)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  key: ValueKey('view-adjustment-${item.id}'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => _openDetail(item),
                                  child: Text(
                                    item.status ==
                                                AdjustmentDtoStatusEnum.CHO_DUYET &&
                                            isQtv
                                        ? 'Duyệt / Xem'
                                        : 'Xem',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_nextCursor != null && !_loading) ...[
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  key: const ValueKey('load-more-adjustments-btn'),
                  onPressed: () => _fetchPage(),
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  label: const Text('Tải thêm'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
