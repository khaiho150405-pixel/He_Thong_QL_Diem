import 'dart:async';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import '../../app/widgets/app_controls.dart';
import 'image_preview.dart';
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
  bool picking = false;
  double? uploadProgress;
  String? imageError;
  bool showAllTickets = false;

  @override
  void initState() {
    super.initState();
    componentId = widget.components.firstOrNull?.id;
    reload();
    WidgetsBinding.instance.addPostFrameCallback((_) => recoverImage());
  }

  @override
  void didUpdateWidget(covariant RecognitionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gradebookId != widget.gradebookId) {
      image = null;
      imageError = null;
      reload();
    }
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

  Future<void> acceptImage(RecognitionImage selected) async {
    recognitionImageMime(selected);
    final codec = await ui.instantiateImageCodec(
      selected.bytes,
      targetWidth: 320,
    );
    try {
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } finally {
      codec.dispose();
    }
    if (mounted) {
      setState(() {
        image = selected;
        imageError = null;
      });
    }
  }

  Future<void> recoverImage() async {
    final picker = ref.read(recognitionImagePickerProvider);
    if (picker is! RecognitionCameraPicker) return;
    try {
      final selected = await (picker as RecognitionCameraPicker).recover();
      if (selected != null && mounted && image == null && !picking) {
        await acceptImage(selected);
        if (mounted) {
          showMessage(
            'Đã khôi phục ảnh chụp. Kiểm tra lại bảng điểm và thành phần trước khi gửi.',
          );
        }
      }
    } catch (_) {
      /* The explicit capture/pick action provides retry and errors. */
    }
  }

  Future<void> pickImage({bool camera = false}) async {
    if (busy || picking || !widget.enabled) return;
    setState(() {
      picking = true;
      imageError = null;
    });
    try {
      final picker = ref.read(recognitionImagePickerProvider);
      final selected = camera && picker is RecognitionCameraPicker
          ? await (picker as RecognitionCameraPicker).capture()
          : await picker.pick();
      if (selected != null && mounted) {
        try {
          await acceptImage(selected);
        } on RecognitionImageException {
          rethrow;
        } catch (_) {
          throw const RecognitionImageException(
            'Không đọc được ảnh. Hãy chọn ảnh PNG/JPEG khác.',
          );
        }
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => imageError = error is RecognitionImageException
              ? error.message
              : 'Không chọn được ảnh. Hãy thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> upload() async {
    if (busy || picking || !widget.enabled) return;
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
    setState(() {
      busy = true;
      uploadProgress = null;
      imageError = null;
    });
    try {
      await ref
          .read(recognitionRepositoryProvider)
          .upload(
            gradebookId: widget.gradebookId,
            componentId: selectedComponent,
            declaredRows: widget.declaredRows,
            image: selected,
            onSendProgress: (sent, total) {
              if (mounted && total > 0) {
                setState(() => uploadProgress = (sent / total).clamp(0, 1));
              }
            },
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
      setState(() => imageError = errorMessage(error));
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
          const Text(
            'Chụp thẳng toàn bộ bảng, đủ sáng, không lóa và rõ hai cột điểm số/điểm chữ. PNG hoặc JPEG, tối đa 10 MB. Thứ tự dòng phải trùng danh sách học sinh.',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 600
                  ? constraints.maxWidth
                  : 320.0;
              final enabled =
                  widget.enabled &&
                  !busy &&
                  !picking &&
                  widget.declaredRows > 0 &&
                  widget.components.isNotEmpty;
              final picker = ref.read(recognitionImagePickerProvider);
              final camera =
                  picker is RecognitionCameraPicker &&
                  (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: DropdownButtonFormField<num>(
                      key: ValueKey('recognition-component-$componentId'),
                      initialValue: componentId,
                      isExpanded: true,
                      itemHeight: null,
                      decoration: const InputDecoration(
                        labelText: 'Thành phần điểm',
                        prefixIcon: Icon(Icons.percent_rounded),
                      ),
                      items: [
                        for (final item in widget.components)
                          DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                      ],
                      onChanged: enabled
                          ? (value) => setState(() => componentId = value)
                          : null,
                    ),
                  ),
                  if (camera)
                    SizedBox(
                      width: width,
                      child: AppActionButton(
                        key: const ValueKey('recognition-camera'),
                        kind: AppActionButtonKind.secondary,
                        onPressed: enabled
                            ? () => pickImage(camera: true)
                            : null,
                        icon: Icons.camera_alt_outlined,
                        label: 'Chụp bảng điểm',
                      ),
                    ),
                  SizedBox(
                    width: width,
                    child: AppActionButton(
                      key: const ValueKey('recognition-pick'),
                      kind: AppActionButtonKind.secondary,
                      onPressed: enabled ? () => pickImage() : null,
                      icon: Icons.photo_library_outlined,
                      label: image == null
                          ? 'Chọn ảnh bảng điểm'
                          : 'Chọn ảnh khác',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: AppActionButton(
                      key: const ValueKey('recognition-upload'),
                      onPressed: enabled && image != null ? upload : null,
                      icon: Icons.cloud_upload_outlined,
                      label: 'Tải ảnh & Nhận dạng',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text('Số dòng khai báo: ${widget.declaredRows}'),
          if (!widget.enabled)
            const Text(
              'Bảng điểm hiện không cho phép gửi ảnh. Kiểm tra trạng thái chốt hoặc tải lại bảng điểm.',
            ),
          if (widget.declaredRows < 1 || widget.components.isEmpty)
            const Text(
              'Cần học sinh đang theo học và thành phần điểm trước khi gửi ảnh.',
            ),
          if (imageError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                imageError!,
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          if (image != null) ...[
            const SizedBox(height: 12),
            Text(image!.name, key: const ValueKey('recognition-filename')),
            Text(
              '${(image!.bytes.length / 1024 / 1024).toStringAsFixed(2)} MB · Kiểm tra độ rõ trước khi gửi',
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => showRecognitionImage(
                context,
                image: Image.memory(image!.bytes, fit: BoxFit.contain),
              ),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Image.memory(
                  image!.bytes,
                  cacheWidth: 640,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Wrap(
              spacing: 12,
              children: [
                TextButton.icon(
                  onPressed: () => showRecognitionImage(
                    context,
                    image: Image.memory(image!.bytes, fit: BoxFit.contain),
                  ),
                  icon: const Icon(Icons.zoom_in),
                  label: const Text('Phóng to ảnh'),
                ),
                TextButton.icon(
                  key: const ValueKey('recognition-clear'),
                  onPressed: busy || picking
                      ? null
                      : () => setState(() {
                          image = null;
                          imageError = null;
                        }),
                  icon: const Icon(Icons.close),
                  label: const Text('Bỏ ảnh đã chọn'),
                ),
              ],
            ),
          ],
          if (busy || picking) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(value: busy ? uploadProgress : null),
            Text(
              picking
                  ? 'Đang đọc ảnh…'
                  : uploadProgress == 1
                  ? 'Ảnh đã gửi, đang chờ xác nhận…'
                  : 'Đang tải ảnh…',
            ),
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
                  for (final item in items.take(
                    showAllTickets ? items.length : 3,
                  ))
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
                    TextButton(
                      onPressed: () =>
                          setState(() => showAllTickets = !showAllTickets),
                      child: Text(
                        showAllTickets ? 'Thu gọn lịch sử' : 'Xem tất cả phiếu',
                      ),
                    ),
                  if (items.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        showAllTickets
                            ? 'Đang hiển thị ${items.length} phiếu.'
                            : 'Đang hiển thị 3 trên ${items.length} phiếu.',
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
  'LOI' => recognitionFailureMessage(item.errorCode),
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
    if (!mounted) return data;
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
    if (row.reviewLevel.value == 'DO') return null;
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
    for (final row in data.rows) {
      final value = values[row.rowId]!.text.trim();
      final reason = reasons[row.rowId]!.text.trim();
      if ((value.isNotEmpty &&
              !RegExp(r'^(10[.]0|[0-9][.][0-9])$').hasMatch(value)) ||
          reason.isEmpty ||
          reason.length > 500) {
        setState(() {
          _reviewLevelFilter = 'ALL';
          confirmed = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kiểm tra điểm và lý do của dòng ${row.order} (${row.studentName}) trước khi duyệt.',
            ),
          ),
        );
        return;
      }
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
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
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

    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        contentPadding: const EdgeInsets.all(16),
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
                  final level = (priority[left.reviewLevel.value] ?? 3)
                      .compareTo(priority[right.reviewLevel.value] ?? 3);
                  return level != 0 ? level : left.order.compareTo(right.order);
                });

              return Form(
                key: formKey,
                child: ListView(
                  cacheExtent: 5000,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
                            'Trạng thái: ${switch (data.status.value) {
                              'DANG_XU_LY' => 'Đang xử lý',
                              'CHO_DOI_CHIEU' => 'Chờ đối chiếu',
                              'DA_DUYET' => 'Đã duyệt',
                              'LOI' => 'Xử lý thất bại',
                              _ => data.status.value,
                            }}',
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
                    if (data.modelVersion?.startsWith('fake') ?? false)
                      const Text(
                        'Kết quả mô phỏng development. Không dùng để đánh giá độ chính xác mô hình thật.',
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
                    TextButton.icon(
                      onPressed: () => showRecognitionImage(
                        context,
                        image: Image.network(
                          data.sourceImageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Center(
                            child: Text(
                              'Không tải được ảnh. Đóng và tải lại phiếu để lấy ảnh mới.',
                            ),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.zoom_in),
                      label: const Text('Phóng to ảnh gốc'),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    if (data.rows.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        key: ValueKey(_reviewLevelFilter),
                        initialValue: _reviewLevelFilter,
                        isExpanded: true,
                        itemHeight: null,
                        decoration: const InputDecoration(
                          labelText: 'Lọc mức độ đối chiếu',
                          prefixIcon: Icon(Icons.filter_alt_outlined),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'ALL',
                            child: Text('Tất cả (${data.rows.length} ô điểm)'),
                          ),
                          for (final level in ['DO', 'VANG', 'XANH'])
                            DropdownMenuItem(
                              value: level,
                              child: Text(
                                '${switch (level) {
                                  'DO' => 'Đỏ · Bắt buộc xem xét',
                                  'VANG' => 'Vàng · Cần đối chiếu',
                                  _ => 'Xanh · Khớp tin cậy',
                                }} (${data.rows.where((r) => r.reviewLevel.value == level).length})',
                              ),
                            ),
                        ],
                        onChanged: busy
                            ? null
                            : (value) => setState(
                                () => _reviewLevelFilter = value ?? 'ALL',
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
                                ? recognitionFailureMessage(data.errorCode)
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
                                        r.reviewLevel.value ==
                                        _reviewLevelFilter,
                                  )
                                  .toList()))
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    '${row.order}. ${row.studentName} · ${row.reviewLevel.value}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
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
      width: (MediaQuery.sizeOf(context).width - 112).clamp(100, 330),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Column(
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
          if (url != null)
            TextButton.icon(
              onPressed: () => showRecognitionImage(
                context,
                image: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Text('Không tải được ảnh. Đóng và tải lại phiếu.'),
                  ),
                ),
              ),
              icon: const Icon(Icons.zoom_in, size: 18),
              label: const Text('Phóng to ô điểm'),
            ),
          const SizedBox(height: 10),
          Column(
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
                'Độ tin cậy: ${confidence == null ? '—' : '${((double.tryParse(confidence) ?? 0) * 100).toStringAsFixed(1)}%'}',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
