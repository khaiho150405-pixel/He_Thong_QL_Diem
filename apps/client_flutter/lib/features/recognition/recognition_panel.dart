import 'dart:async';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import '../../app/widgets/app_controls.dart';
import 'image_preview.dart';
import 'review_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    required this.gradebookVersion,
    required this.enabled,
    required this.onApproved,
  });

  final num gradebookId;
  final List<RecognitionComponentOption> components;
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
  String? _uploadedTicketId;
  bool _navigating = false;

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
      _uploadedTicketId = null;
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
          if (_uploadedTicketId != null) {
            final tracked = items
                .where((it) => it.ticketId == _uploadedTicketId)
                .firstOrNull;
            if (tracked != null) {
              if (tracked.status.value == 'CHO_DOI_CHIEU') {
                final targetId = _uploadedTicketId!;
                _uploadedTicketId = null;
                final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
                if (isCurrent && !_navigating) {
                  _navigating = true;
                  showDetail(targetId).whenComplete(() {
                    if (mounted) _navigating = false;
                  });
                  return;
                }
              } else if (tracked.status.value == 'LOI') {
                _uploadedTicketId = null;
                setState(() {
                  imageError = recognitionFailureMessage(tracked.errorCode);
                });
              }
            }
          }
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
    setState(() {
      busy = true;
      uploadProgress = null;
      imageError = null;
    });
    try {
      final receipt = await ref
          .read(recognitionRepositoryProvider)
          .upload(
            gradebookId: widget.gradebookId,
            componentId: selectedComponent,
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
        _uploadedTicketId = receipt.ticketId;
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
    bool? approved;
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      approved = await context.push<bool>(
        '/gradebooks/${widget.gradebookId}/recognition/$ticketId',
        extra: widget.gradebookVersion,
      );
    } else {
      approved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ReviewScreen(
            gradebookId: widget.gradebookId,
            ticketId: ticketId,
            gradebookVersion: widget.gradebookVersion,
          ),
        ),
      );
    }
    if (!mounted) return;
    if (approved == true) {
      widget.onApproved();
    }
    setState(reload);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enabled =
        widget.enabled && !busy && !picking && widget.components.isNotEmpty;
    final picker = ref.read(recognitionImagePickerProvider);
    final camera =
        picker is RecognitionCameraPicker &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

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
            'Chụp thẳng toàn bộ bảng, đủ sáng, rõ các cột Họ tên, Điểm số, Điểm chữ. PNG hoặc JPEG, tối đa 10 MB. Hệ thống tự xác định học sinh theo họ tên.',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 600
                  ? constraints.maxWidth
                  : 320.0;
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
          if (!widget.enabled)
            const Text(
              'Bảng điểm hiện không cho phép gửi ảnh. Kiểm tra trạng thái chốt hoặc tải lại bảng điểm.',
            ),
          if (widget.components.isEmpty)
            const Text('Cần thành phần điểm trước khi gửi ảnh.'),
          if (imageError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(imageError!, style: TextStyle(color: colorScheme.error)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (camera)
                        TextButton.icon(
                          key: const ValueKey('recognition-retry-camera'),
                          onPressed: enabled
                              ? () => pickImage(camera: true)
                              : null,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Chụp lại'),
                        ),
                      TextButton.icon(
                        key: const ValueKey('recognition-retry-pick'),
                        onPressed: enabled ? () => pickImage() : null,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Chọn ảnh khác'),
                      ),
                    ],
                  ),
                ],
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
    'Chờ đối chiếu · ${item.detectedRows ?? 0} dòng · ${item.greenRows} Xanh · ${item.yellowRows} Vàng · ${item.redRows} Đỏ',
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
