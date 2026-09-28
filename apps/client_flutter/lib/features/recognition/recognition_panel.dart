import 'dart:async';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../authentication/session.dart';
import 'image_picker.dart';
import 'repository.dart';

class RecognitionComponentOption {
  const RecognitionComponentOption(this.id, this.name);
  final num id;
  final String name;
}

class RecognitionPanel extends ConsumerStatefulWidget {
  const RecognitionPanel({
    super.key,
    required this.gradebookId,
    required this.components,
    required this.declaredRows,
    required this.gradebookVersion,
    required this.enabled,
    required this.onApproved,
  });

  final num gradebookId;
  final List<RecognitionComponentOption> components;
  final int declaredRows;
  final num gradebookVersion;
  final bool enabled;
  final VoidCallback onApproved;

  @override
  ConsumerState<RecognitionPanel> createState() => _RecognitionPanelState();
}

class _RecognitionPanelState extends ConsumerState<RecognitionPanel> {
  late Future<List<RecognitionTicketDto>> tickets;
  Timer? pollTimer;
  RecognitionImage? image;
  num? componentId;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    componentId = widget.components.firstOrNull?.id;
    reload();
  }

  @override
  void didUpdateWidget(covariant RecognitionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.components.any((item) => item.id == componentId)) {
      componentId = widget.components.firstOrNull?.id;
    }
  }

  void reload() {
    pollTimer?.cancel();
    tickets = ref.read(recognitionRepositoryProvider).list(widget.gradebookId);
    tickets
        .then((items) {
          if (!mounted) return;
          if (items.any((item) => item.status.value == 'DANG_XU_LY')) {
            pollTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) setState(reload);
            });
          }
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    super.dispose();
  }

  Future<void> pickImage() async {
    try {
      final selected = await ref.read(recognitionImagePickerProvider).pick();
      if (selected != null && mounted) setState(() => image = selected);
    } catch (error) {
      if (mounted) showMessage(errorMessage(error));
    }
  }

  Future<void> upload() async {
    final selected = image;
    final selectedComponent = componentId;
    if (selected == null || selectedComponent == null) {
      showMessage('Chọn thành phần điểm và ảnh bảng điểm trước.');
      return;
    }
    if (widget.declaredRows < 1) {
      showMessage('Bảng điểm chưa có học sinh đang theo học.');
      return;
    }
    setState(() => busy = true);
    try {
      await ref
          .read(recognitionRepositoryProvider)
          .upload(
            gradebookId: widget.gradebookId,
            componentId: selectedComponent,
            declaredRows: widget.declaredRows,
            image: selected,
          );
      if (!mounted) return;
      setState(() {
        busy = false;
        image = null;
        reload();
      });
      showMessage('Đã tải ảnh. Hệ thống đang nhận dạng.');
    } catch (error) {
      if (!mounted) return;
      setState(() => busy = false);
      showMessage(errorMessage(error));
    }
  }

  void showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> showDetail(String ticketId) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (_) => RecognitionDetailDialog(
        gradebookId: widget.gradebookId,
        ticketId: ticketId,
        gradebookVersion: widget.gradebookVersion,
      ),
    );
    if (!mounted) return;
    if (approved == true) {
      showMessage('Đã duyệt phiếu và cập nhật điểm chính thức.');
      widget.onApproved();
    }
    setState(reload);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.document_scanner_rounded,
            color: colorScheme.primary,
            size: 22,
          ),
        ),
        title: Text(
          'Nhận dạng bảng điểm từ ảnh',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: const Text(
          'Máy chỉ đề xuất kết quả; giáo viên đối chiếu trước khi ghi điểm chính thức.',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          const Divider(height: 24),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<num>(
                  key: const ValueKey('recognition-component'),
                  initialValue: componentId,
                  decoration: const InputDecoration(
                    labelText: 'Thành phần điểm',
                    prefixIcon: Icon(Icons.percent_rounded, size: 18),
                  ),
                  items: [
                    for (final item in widget.components)
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                  ],
                  onChanged: widget.enabled && !busy
                      ? (value) => setState(() => componentId = value)
                      : null,
                ),
              ),
              OutlinedButton.icon(
                key: const ValueKey('recognition-pick'),
                onPressed: widget.enabled && !busy ? pickImage : null,
                icon: const Icon(Icons.image_rounded, size: 18),
                label: Text(image?.name ?? 'Chọn ảnh bảng điểm'),
              ),
              Text('Số dòng khai báo: ${widget.declaredRows}'),
              FilledButton.icon(
                key: const ValueKey('recognition-upload'),
                onPressed: widget.enabled && !busy ? upload : null,
                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                label: const Text('Tải ảnh & Nhận dạng'),
              ),
            ],
          ),
          if (busy) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 18),
          FutureBuilder<List<RecognitionTicketDto>>(
            future: tickets,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Row(
                  children: [
                    Expanded(child: Text(errorMessage(snapshot.error!))),
                    TextButton(
                      onPressed: () => setState(reload),
                      child: const Text('Thử lại'),
                    ),
                  ],
                );
              }
              final items = snapshot.data!;
              if (items.isEmpty) {
                return const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Chưa có phiếu nhận dạng nào.'),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lịch sử phiếu nhận dạng gần đây',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final item in items.take(3))
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        title: Text(
                          'Phiếu #${item.ticketId} · ${item.componentName}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(_statusText(item)),
                        leading: item.status.value == 'DANG_XU_LY'
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _statusIcon(item.status.value),
                                color: _statusColor(item.status.value),
                              ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                        ),
                        onTap: () => showDetail(item.ticketId),
                      ),
                    ),
                  if (items.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Đang hiển thị 3 trên ${items.length} phiếu gần nhất.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

String _statusText(RecognitionTicketDto item) => switch (item.status.value) {
  'DANG_XU_LY' => 'Đang xử lý · tự động cập nhật sau 3 giây',
  'CHO_DOI_CHIEU' =>
    'Chờ đối chiếu · đã đọc ${item.detectedRows ?? 0}/${item.declaredRows} dòng',
  'DA_DUYET' => 'Đã duyệt và ghi điểm chính thức',
  'LOI' => 'Lỗi ${item.errorCode ?? 'không xác định'} · hãy tải lại ảnh khác',
  _ => item.status.value,
};

IconData _statusIcon(String status) => switch (status) {
  'CHO_DOI_CHIEU' => Icons.fact_check_rounded,
  'DA_DUYET' => Icons.check_circle_rounded,
  'LOI' => Icons.error_rounded,
  _ => Icons.hourglass_empty_rounded,
};

Color _statusColor(String status) => switch (status) {
  'CHO_DOI_CHIEU' => Colors.orange.shade700,
  'DA_DUYET' => Colors.green.shade700,
  'LOI' => Colors.red.shade700,
  _ => Colors.grey.shade600,
};

class RecognitionDetailDialog extends ConsumerStatefulWidget {
  const RecognitionDetailDialog({
    super.key,
    required this.gradebookId,
    required this.ticketId,
    required this.gradebookVersion,
  });

  final num gradebookId;
  final String ticketId;
  final num gradebookVersion;

  @override
  ConsumerState<RecognitionDetailDialog> createState() =>
      _RecognitionDetailDialogState();
}

class _RecognitionDetailDialogState
    extends ConsumerState<RecognitionDetailDialog> {
  final formKey = GlobalKey<FormState>();
  final values = <String, TextEditingController>{};
  final reasons = <String, TextEditingController>{};
  late Future<RecognitionTicketDetailDto> detail;
  RecognitionTicketDetailDto? loaded;
  bool confirmed = false;
  bool busy = false;
  String _reviewLevelFilter = 'ALL'; // 'ALL' | 'DO' | 'VANG' | 'XANH'

  @override
  void initState() {
    super.initState();
    detail = _loadDetail();
  }

  Future<RecognitionTicketDetailDto> _loadDetail() async {
    final data = await ref
        .read(recognitionRepositoryProvider)
        .detail(gradebookId: widget.gradebookId, ticketId: widget.ticketId);
    loaded = data;
    for (final row in data.rows) {
      if (!values.containsKey(row.rowId)) {
        final suggested = _suggested(row);
        values[row.rowId] = TextEditingController(text: suggested ?? '');
        reasons[row.rowId] = TextEditingController(
          text: suggested == null ? '' : 'Đã đối chiếu ảnh nhận dạng',
        );
      }
    }
    return data;
  }

  void refreshEvidence() {
    if (busy) return;
    final next = _loadDetail();
    setState(() {
      detail = next;
    });
  }

  String? _suggested(RecognitionEvidenceRowDto row) {
    if (row.comparison.value == 'KHOP') return row.numericValue;
    if (row.comparison.value == 'MOT_KENH') {
      return row.numericValue ?? row.writtenValue;
    }
    return null;
  }

  @override
  void dispose() {
    for (final controller in [...values.values, ...reasons.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> approve() async {
    final data = loaded;
    if (data == null ||
        !confirmed ||
        !(formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => busy = true);
    try {
      await ref
          .read(recognitionRepositoryProvider)
          .approve(
            gradebookId: widget.gradebookId,
            ticketId: widget.ticketId,
            expectedTicketVersion: data.version,
            expectedGradebookVersion: widget.gradebookVersion,
            decisions: [
              for (final row in data.rows)
                ReviewDecisionInput(
                  rowId: row.rowId,
                  value: values[row.rowId]!.text.trim().isEmpty
                      ? null
                      : values[row.rowId]!.text.trim(),
                  reason: reasons[row.rowId]!.text.trim(),
                ),
            ],
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
    }
  }

  Widget _reviewLevelBadge(String level) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (level) {
      case 'XANH':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'XANH · Khớp tin cậy';
        icon = Icons.check_circle_rounded;
        break;
      case 'VANG':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade900;
        label = 'VÀNG · Cần đối chiếu';
        icon = Icons.warning_amber_rounded;
        break;
      case 'DO':
      default:
        bg = Colors.red.shade50;
        fg = Colors.red.shade900;
        label = 'ĐỎ · Bắt buộc xem xét';
        icon = Icons.error_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Phiếu nhận dạng #${widget.ticketId}'),
      content: SizedBox(
        width: 780,
        height: 700,
        child: FutureBuilder<RecognitionTicketDetailDto>(
          future: detail,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang tải dữ liệu phiếu và ảnh ô cắt…'),
                  ],
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage(snapshot.error!)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const ValueKey('review-retry-detail'),
                      onPressed: refreshEvidence,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tải lại phiếu'),
                    ),
                  ],
                ),
              );
            }
            final data = snapshot.data!;
            final canApprove = data.status.value == 'CHO_DOI_CHIEU';
            final orderedRows = [...data.rows]
              ..sort((left, right) {
                const priority = {'DO': 0, 'VANG': 1, 'XANH': 2};
                final level = (priority[left.reviewLevel.value] ?? 3).compareTo(
                  priority[right.reviewLevel.value] ?? 3,
                );
                return level != 0 ? level : left.order.compareTo(right.order);
              });

            return Form(
              key: formKey,
              child: ListView(
                cacheExtent: 5000,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Trạng thái: ${data.status.value}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Thành phần: ${data.componentName}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        data.sourceImageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => _expiredImage(
                          key: const ValueKey('review-refresh-source'),
                          label:
                              'Không tải được ảnh gốc. URL có thể đã hết hạn.',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (data.rows.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_alt_rounded,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Lọc mức độ:',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(_reviewLevelFilter),
                              initialValue: _reviewLevelFilter,
                              isDense: true,
                              isExpanded: true,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'ALL',
                                  child: Text(
                                    'Tất cả mức độ (${data.rows.length} ô điểm)',
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'DO',
                                  child: Text(
                                    '🔴 Đỏ · Bắt buộc xem xét (${data.rows.where((r) => r.reviewLevel.value == 'DO').length})',
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'VANG',
                                  child: Text(
                                    '🟡 Vàng · Cần đối chiếu (${data.rows.where((r) => r.reviewLevel.value == 'VANG').length})',
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'XANH',
                                  child: Text(
                                    '🟢 Xanh · Khớp tin cậy (${data.rows.where((r) => r.reviewLevel.value == 'XANH').length})',
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _reviewLevelFilter = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (data.rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          data.status.value == 'LOI'
                              ? 'Nhận dạng thất bại: ${data.errorCode ?? 'không xác định'}.'
                              : 'Kết quả từng dòng chưa sẵn sàng.',
                        ),
                      ),
                    ),
                  for (final row
                      in (_reviewLevelFilter == 'ALL'
                          ? orderedRows
                          : orderedRows
                                .where(
                                  (r) =>
                                      r.reviewLevel.value == _reviewLevelFilter,
                                )
                                .toList()))
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${row.order}. ${row.studentName} · ${row.reviewLevel.value}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                _reviewLevelBadge(row.reviewLevel.value),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              children: [
                                _channel(
                                  'Điểm số',
                                  row.numericCropUrl,
                                  row.numericRaw,
                                  row.numericValue,
                                  row.numericConfidence,
                                  refreshEvidence,
                                ),
                                _channel(
                                  'Điểm chữ',
                                  row.writtenCropUrl,
                                  row.writtenRaw,
                                  row.writtenValue,
                                  row.writtenConfidence,
                                  refreshEvidence,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              key: ValueKey('review-value-${row.rowId}'),
                              controller: values[row.rowId],
                              enabled: canApprove && !busy,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText:
                                    'Điểm cuối (để trống nếu học sinh vắng)',
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return null;
                                return RegExp(
                                      r'^(10[.]0|[0-9][.][0-9])$',
                                    ).hasMatch(text)
                                    ? null
                                    : 'Nhập 0.0–10.0 với một chữ số thập phân.';
                              },
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              key: ValueKey('review-reason-${row.rowId}'),
                              controller: reasons[row.rowId],
                              enabled: canApprove && !busy,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Lý do / ghi chú xác nhận',
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) {
                                  return 'Cần ghi lý do xác nhận.';
                                }
                                if (text.length > 500) {
                                  return 'Tối đa 500 ký tự.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (canApprove) ...[
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      key: const ValueKey('review-confirm-all'),
                      value: confirmed,
                      onChanged: busy
                          ? null
                          : (value) =>
                                setState(() => confirmed = value ?? false),
                      title: const Text(
                        'Tôi đã kiểm tra kỹ ảnh ô cắt và xác nhận các giá trị trên.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      key: const ValueKey('review-approve'),
                      onPressed: confirmed && !busy ? approve : null,
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text('Duyệt và ghi nhận điểm chính thức'),
                    ),
                    if (busy) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  Widget _channel(
    String label,
    String? url,
    String? raw,
    String? value,
    String? confidence,
    VoidCallback onRefresh,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 330,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 110,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: url == null
                ? const Center(
                    child: Text('Không có ảnh', style: TextStyle(fontSize: 11)),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => IconButton(
                        tooltip: 'Ảnh hết hạn. Nhấn để tải lại.',
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ký tự thô: ${raw ?? '—'}',
                  style: const TextStyle(fontSize: 11.5),
                ),
                Text(
                  'Giá trị: ${value ?? '—'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Độ tin cậy: ${confidence ?? '—'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _expiredImage({required Key key, required String label}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          key: key,
          onPressed: refreshEvidence,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Lấy URL ảnh mới'),
        ),
      ],
    ),
  );
}
