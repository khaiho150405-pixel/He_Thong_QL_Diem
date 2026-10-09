import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/widgets/app_scaffold.dart';
import '../authentication/session.dart';
import '../gradebooks/repository.dart';
import 'image_preview.dart';
import 'repository.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({
    super.key,
    required this.gradebookId,
    required this.ticketId,
    this.gradebookVersion,
  });

  final num gradebookId;
  final String ticketId;
  final num? gradebookVersion;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final formKey = GlobalKey<FormState>();
  final values = <String, TextEditingController>{};
  final reasons = <String, TextEditingController>{};
  late Future<RecognitionTicketDetailDto> detail;
  RecognitionTicketDetailDto? loaded;
  num? _gradebookVersion;
  // Có giá trị khi không lấy được version bảng điểm: không duyệt bằng version giả (tránh ghi đè/xung đột âm thầm).
  String? _versionError;
  bool confirmed = false;
  bool busy = false;
  String _reviewLevelFilter = 'ALL'; // 'ALL' | 'DO' | 'VANG' | 'XANH'

  @override
  void initState() {
    super.initState();
    _gradebookVersion = widget.gradebookVersion;
    detail = _loadDetail();
  }

  Future<RecognitionTicketDetailDto> _loadDetail() async {
    if (_gradebookVersion == null) {
      try {
        final cells = await ref
            .read(gradebooksRepositoryProvider)
            .cells(widget.gradebookId);
        _gradebookVersion = cells.book.version;
        _versionError = null;
      } catch (_) {
        // Không dùng giá trị giả: giữ null, hiển thị lỗi + "Tải lại" và vô hiệu nút Duyệt.
        _versionError = 'Không tải được phiên bản bảng điểm';
      }
    }
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
    // Luật hợp nhất hai kênh: máy cho biết kênh nào có giá trị gợi ý.
    switch (row.suggestedSource) {
      case RecognitionEvidenceRowDtoSuggestedSourceEnum.SO:
        return row.numericValue;
      case RecognitionEvidenceRowDtoSuggestedSourceEnum.CHU:
        return row.writtenValue;
      case null:
        break;
    }
    // Phiếu tạo trước luật hợp nhất (không có kênh gợi ý): giữ cách gợi ý cũ.
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
    final version = _gradebookVersion;
    if (data == null ||
        version == null ||
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
            expectedGradebookVersion: version,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã duyệt phiếu và cập nhật điểm chính thức.'),
        ),
      );
      context.pop(true);
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
      child: AppScaffold(
        key: const ValueKey('review-screen'),
        title: 'Đối chiếu nhận dạng #${widget.ticketId}',
        showBackButton: true,
        body: FutureBuilder<RecognitionTicketDetailDto>(
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
                if (level != 0) return level;
                final sttLeft = left.stt;
                final sttRight = right.stt;
                if (sttLeft != null && sttRight != null) {
                  final cmp = sttLeft.compareTo(sttRight);
                  if (cmp != 0) return cmp;
                } else if (sttLeft != null) {
                  return -1;
                } else if (sttRight != null) {
                  return 1;
                }
                return left.order.compareTo(right.order);
              });

            final greenCount = data.greenRows;
            final yellowCount = data.yellowRows;
            final redCount = data.redRows;
            final totalRows = data.detectedRows ?? data.rows.length;

            return Form(
              key: formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                cacheExtent: 5000,
                children: [
                  if (_versionError != null) ...[
                    Card(
                      key: const ValueKey('review-version-error'),
                      color: colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: colorScheme.onErrorContainer,
                            ),
                            Text(
                              '$_versionError. Chưa thể duyệt phiếu.',
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            OutlinedButton.icon(
                              key: const ValueKey('review-retry-version'),
                              onPressed: busy ? null : refreshEvidence,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Tải lại'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
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
                              Text(
                                'Thành phần: ${data.componentName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '$totalRows dòng · ',
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '$greenCount Xanh',
                                        style: TextStyle(
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' · ',
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '$yellowCount Vàng',
                                        style: TextStyle(
                                          color: Colors.orange.shade900,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' · ',
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '$redCount Đỏ',
                                        style: TextStyle(
                                          color: Colors.red.shade900,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          if (data.modelVersion?.startsWith('fake') ?? false)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Kết quả mô phỏng development. Không dùng để đánh giá độ chính xác mô hình thật.',
                                style: TextStyle(
                                  color: colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 220),
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
                          const SizedBox(height: 6),
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          child: Text(
                            'Tất cả ($totalRows dòng)',
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'DO',
                          child: Text(
                            'Đỏ · Bắt buộc xem xét ($redCount)',
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'VANG',
                          child: Text(
                            'Vàng · Cần đối chiếu ($yellowCount)',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'XANH',
                          child: Text(
                            'Xanh · Khớp tin cậy ($greenCount)',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w600,
                            ),
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'STT ${row.stt ?? '—'} · ${row.studentName} · ${row.reviewLevel.value}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                _reviewLevelBadge(row.reviewLevel.value),
                              ],
                            ),
                            if (row.matchNote != null &&
                                row.matchNote!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: row.reviewLevel.value == 'DO'
                                      ? Colors.red.shade50
                                      : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: row.reviewLevel.value == 'DO'
                                        ? Colors.red.shade300
                                        : Colors.amber.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 16,
                                      color: row.reviewLevel.value == 'DO'
                                          ? Colors.red.shade900
                                          : Colors.amber.shade900,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        row.reviewLevel.value == 'DO'
                                            ? 'Nghi lệch học sinh: ${row.matchNote}. Đối chiếu kỹ ảnh họ tên trên giấy với tên hệ thống!'
                                            : 'Ghi chú ghép: ${row.matchNote}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: row.reviewLevel.value == 'DO'
                                              ? Colors.red.shade900
                                              : Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (row.reviewLevel.value == 'VANG' &&
                                row.suggestedSource != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                row.suggestedSource ==
                                        RecognitionEvidenceRowDtoSuggestedSourceEnum
                                            .SO
                                    ? 'Lấy theo điểm số'
                                    : 'Lấy theo điểm chữ',
                                key: ValueKey('review-source-${row.rowId}'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _nameCropBox(row),
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
                                labelText: 'Điểm cuối',
                                helperText:
                                    'Để trống nếu không ghi điểm cho học sinh này (ví dụ vắng); khi đó bắt buộc ghi lý do.',
                                helperMaxLines: 2,
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
                                  return values[row.rowId]!.text.trim().isEmpty
                                      ? 'Cần ghi lý do không ghi điểm cho học sinh này.'
                                      : 'Cần ghi lý do xác nhận.';
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
                      onPressed: confirmed && !busy && _gradebookVersion != null
                          ? approve
                          : null,
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
    );
  }

  Widget _nameCropBox(RecognitionEvidenceRowDto row) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final boxWidth = (screenWidth - 72).clamp(100.0, 300.0);

    return Container(
      width: boxWidth,
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
            width: double.infinity,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: row.nameCropUrl == null
                ? const Center(
                    child: Text(
                      'Không có ảnh họ tên',
                      style: TextStyle(fontSize: 11),
                    ),
                  )
                : InkWell(
                    onTap: () => showRecognitionImage(
                      context,
                      image: Image.network(
                        row.nameCropUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Center(
                          child: Text(
                            'Không tải được ảnh. Đóng và tải lại phiếu.',
                          ),
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        row.nameCropUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => IconButton(
                          tooltip: 'Ảnh hết hạn. Nhấn để tải lại.',
                          onPressed: refreshEvidence,
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                        ),
                      ),
                    ),
                  ),
          ),
          if (row.nameCropUrl != null)
            TextButton.icon(
              onPressed: () => showRecognitionImage(
                context,
                image: Image.network(
                  row.nameCropUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Text('Không tải được ảnh. Đóng và tải lại phiếu.'),
                  ),
                ),
              ),
              icon: const Icon(Icons.zoom_in, size: 18),
              label: const Text('Phóng to họ tên'),
            ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Họ tên trên giấy',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tên đọc được: ${row.nameRead ?? '—'}',
                style: const TextStyle(fontSize: 11.5),
              ),
              if (row.matchConfidence != null)
                Text(
                  'Độ tin cậy: ${((double.tryParse(row.matchConfidence!) ?? 0) * 100).toStringAsFixed(1)}%',
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

  Widget _channel(
    String label,
    String? url,
    String? raw,
    String? value,
    String? confidence,
    VoidCallback onRefresh,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final boxWidth = (screenWidth - 72).clamp(100.0, 300.0);

    return Container(
      width: boxWidth,
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
            width: double.infinity,
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
                : InkWell(
                    onTap: () => showRecognitionImage(
                      context,
                      image: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Center(
                          child: Text(
                            'Không tải được ảnh. Đóng và tải lại phiếu.',
                          ),
                        ),
                      ),
                    ),
                    child: ClipRRect(
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
