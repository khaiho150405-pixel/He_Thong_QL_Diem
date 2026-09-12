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
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      initiallyExpanded: false,
      leading: const Icon(Icons.document_scanner_outlined),
      title: const Text('Nhận dạng bảng điểm từ ảnh'),
      subtitle: const Text(
        'Máy chỉ đề xuất; giáo viên chưa chốt điểm ở bước này.',
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<num>(
                key: const ValueKey('recognition-component'),
                initialValue: componentId,
                decoration: const InputDecoration(
                  labelText: 'Thành phần điểm',
                  border: OutlineInputBorder(),
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
              icon: const Icon(Icons.image_outlined),
              label: Text(image?.name ?? 'Chọn ảnh PNG/JPEG'),
            ),
            Text('Số dòng khai báo: ${widget.declaredRows}'),
            FilledButton.icon(
              key: const ValueKey('recognition-upload'),
              onPressed: widget.enabled && !busy ? upload : null,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Tải ảnh và nhận dạng'),
            ),
          ],
        ),
        if (busy) const LinearProgressIndicator(),
        const SizedBox(height: 12),
        FutureBuilder<List<RecognitionTicketDto>>(
          future: tickets,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(12),
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
                child: Text('Chưa có phiếu nhận dạng.'),
              );
            }
            return Column(
              children: [
                for (final item in items.take(3))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Phiếu #${item.ticketId} · ${item.componentName}',
                    ),
                    subtitle: Text(_statusText(item)),
                    leading: item.status.value == 'DANG_XU_LY'
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_statusIcon(item.status.value)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showDetail(item.ticketId),
                  ),
                if (items.length > 3)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Đang hiển thị 3/${items.length} phiếu gần nhất.',
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

String _statusText(RecognitionTicketDto item) => switch (item.status.value) {
  'DANG_XU_LY' => 'Đang xử lý · tự cập nhật sau 3 giây',
  'CHO_DOI_CHIEU' =>
    'Chờ đối chiếu · ${item.detectedRows ?? 0}/${item.declaredRows} dòng',
  'DA_DUYET' => 'Đã duyệt',
  'LOI' => 'Lỗi ${item.errorCode ?? 'không xác định'} · hãy tải ảnh khác',
  _ => item.status.value,
};

IconData _statusIcon(String status) => switch (status) {
  'CHO_DOI_CHIEU' => Icons.fact_check_outlined,
  'DA_DUYET' => Icons.check_circle_outline,
  'LOI' => Icons.error_outline,
  _ => Icons.hourglass_empty,
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

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Phiếu nhận dạng #${widget.ticketId}'),
    content: SizedBox(
      width: 760,
      height: 620,
      child: FutureBuilder<RecognitionTicketDetailDto>(
        future: detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage(snapshot.error!)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('review-retry-detail'),
                    onPressed: refreshEvidence,
                    icon: const Icon(Icons.refresh),
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
              children: [
                Text(
                  'Trạng thái: ${data.status.value} · ${data.componentName}',
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: Image.network(
                    data.sourceImageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => _expiredImage(
                      key: const ValueKey('review-refresh-source'),
                      label: 'Không tải được ảnh gốc. URL có thể đã hết hạn.',
                    ),
                  ),
                ),
                const Divider(),
                if (data.rows.isEmpty)
                  Text(
                    data.status.value == 'LOI'
                        ? 'Nhận dạng thất bại: ${data.errorCode ?? 'không xác định'}.'
                        : 'Kết quả từng dòng chưa sẵn sàng.',
                  ),
                for (final row in orderedRows)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${row.order}. ${row.studentName} · ${row.reviewLevel.value}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
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
                          const SizedBox(height: 12),
                          TextFormField(
                            key: ValueKey('review-value-${row.rowId}'),
                            controller: values[row.rowId],
                            enabled: canApprove && !busy,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText:
                                  'Điểm cuối (để trống nếu chưa có điểm)',
                              border: OutlineInputBorder(),
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
                              labelText: 'Lý do/xác nhận',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return 'Cần ghi lý do xác nhận.';
                              }
                              if (text.length > 500) return 'Tối đa 500 ký tự.';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                if (canApprove) ...[
                  CheckboxListTile(
                    key: const ValueKey('review-confirm-all'),
                    value: confirmed,
                    onChanged: busy
                        ? null
                        : (value) => setState(() => confirmed = value ?? false),
                    title: const Text(
                      'Tôi đã xem ảnh và xác nhận tất cả các dòng.',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  FilledButton.icon(
                    key: const ValueKey('review-approve'),
                    onPressed: confirmed && !busy ? approve : null,
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Duyệt và ghi điểm chính thức'),
                  ),
                  if (busy) const LinearProgressIndicator(),
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

  Widget _channel(
    String label,
    String? url,
    String? raw,
    String? value,
    String? confidence,
    VoidCallback onRefresh,
  ) => SizedBox(
    width: 320,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          height: 80,
          child: url == null
              ? const ColoredBox(color: Colors.transparent)
              : Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => IconButton(
                    tooltip: 'Ảnh hết hạn hoặc không tải được. Lấy URL mới.',
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label\nRaw: ${raw ?? '—'}\nGiá trị: ${value ?? '—'}\n'
            'Tin cậy: ${confidence ?? '—'}',
          ),
        ),
      ],
    ),
  );

  Widget _expiredImage({required Key key, required String label}) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: key,
        onPressed: refreshEvidence,
        icon: const Icon(Icons.refresh),
        label: const Text('Lấy URL ảnh mới'),
      ),
    ],
  );
}
