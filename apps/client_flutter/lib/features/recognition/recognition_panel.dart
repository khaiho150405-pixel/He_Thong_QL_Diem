import 'dart:async';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_controls.dart';
import '../../app/widgets/app_progress.dart';
import 'cancel_ticket_dialog.dart';
import 'capture_guide_screen.dart';
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
    this.embedded = false,
    this.classSubjectLabel,
  });

  final num gradebookId;
  final List<RecognitionComponentOption> components;
  final num gradebookVersion;
  final bool enabled;
  final VoidCallback onApproved;
  final bool embedded;

  /// Nhãn "Lớp · Môn" (ví dụ `10A1 · Toán`) cho màn hướng dẫn chụp; chỉ để
  /// hiển thị, `null` thì pill chỉ có tên cột điểm.
  final String? classSubjectLabel;

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
  bool showCancelled = false;
  CancelToken? _uploadCancelToken;
  String? _uploadedTicketId;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    // Bắt buộc chọn cột điểm nếu có nhiều hơn 1 thành phần
    componentId = widget.components.length == 1
        ? widget.components.first.id
        : null;
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
      componentId = widget.components.length == 1
          ? widget.components.first.id
          : null;
    }
  }

  void reload() {
    pollTimer?.cancel();
    tickets = ref
        .read(recognitionRepositoryProvider)
        .list(widget.gradebookId, includeCancelled: showCancelled);
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
    _uploadCancelToken?.cancel();
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

  /// Chọn ảnh từ màn hướng dẫn chụp bằng đúng `pickImage`. Trả `true` khi có
  /// ảnh mới hoặc thông báo lỗi để panel hiển thị (màn hướng dẫn tự đóng);
  /// `false` khi bị chặn hoặc người dùng hủy (màn ở lại).
  Future<bool> _pickFromGuide({required bool camera}) async {
    final before = image;
    await pickImage(camera: camera);
    return mounted && (!identical(image, before) || imageError != null);
  }

  Future<void> _openCaptureGuide(bool enabled) {
    String? componentName;
    for (final item in widget.components) {
      if (item.id == componentId) componentName = item.name;
    }
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CaptureGuideScreen(
          classSubjectLabel: widget.classSubjectLabel,
          componentLabel: componentName,
          enabled: enabled,
          onCapture: () => _pickFromGuide(camera: true),
          onPickFromLibrary: () => _pickFromGuide(camera: false),
        ),
      ),
    );
  }

  Future<void> upload() async {
    if (busy || picking || !widget.enabled) return;
    final selected = image;
    final selectedComponent = componentId;
    if (selected == null || selectedComponent == null) {
      showMessage('Chọn thành phần điểm và ảnh bảng điểm trước.');
      return;
    }
    final cancelToken = CancelToken();
    _uploadCancelToken = cancelToken;
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
            cancelToken: cancelToken,
            onSendProgress: (sent, total) {
              if (mounted && total > 0) {
                setState(() => uploadProgress = (sent / total).clamp(0, 1));
              }
            },
          );
      if (!mounted) return;
      _uploadCancelToken = null;
      setState(() {
        busy = false;
        image = null;
        _uploadedTicketId = receipt.ticketId;
        reload();
      });
      showMessage('Đã tải ảnh. Hệ thống đang nhận dạng.');
    } catch (error) {
      if (!mounted) return;
      _uploadCancelToken = null;
      if (error is DioException && CancelToken.isCancel(error)) {
        setState(() {
          busy = false;
          uploadProgress = null;
        });
        showMessage('Đã hủy tải lên');
        return;
      }
      setState(() => busy = false);
      setState(() => imageError = errorMessage(error));
    }
  }

  void cancelUpload() {
    _uploadCancelToken?.cancel('USER_CANCELLED');
  }

  bool _canCancelTicket(RecognitionTicketDto item) {
    final user = ref.read(sessionProvider);
    if (user?.role.value == 'QUAN_TRI_VIEN') return false;
    return item.status.value == 'DANG_XU_LY' ||
        item.status.value == 'CHO_DOI_CHIEU' ||
        item.status.value == 'LOI';
  }

  Future<void> _handleCancelTicket(RecognitionTicketDto item) async {
    final cancelled = await showCancelTicketDialog(
      context: context,
      ref: ref,
      gradebookId: widget.gradebookId,
      ticketId: item.ticketId,
      expectedVersion: item.version,
    );
    if (cancelled == true && mounted) {
      reload();
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
    final t = context.tokens;
    final enabled =
        widget.enabled && !busy && !picking && widget.components.isNotEmpty;
    final picker = ref.read(recognitionImagePickerProvider);
    final camera =
        picker is RecognitionCameraPicker &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    final controls = _buildUploadControls(context, enabled, camera);
    final ticketSection = _buildTicketSection(context);

    if (widget.embedded) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: t.line),
          boxShadow: t.shadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _headerIcon(t),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nhận dạng bảng điểm từ ảnh',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Máy chỉ đề xuất kết quả; giáo viên đối chiếu trước khi ghi điểm chính thức.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildStepper(),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 960) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: controls),
                        const SizedBox(width: AppSpacing.xxl),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTipsCard(context),
                              const SizedBox(height: 18),
                              ticketSection,
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTipsCard(context),
                      const SizedBox(height: AppSpacing.lg),
                      controls,
                      const SizedBox(height: 18),
                      ticketSection,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: _headerIcon(t),
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
          _buildStepper(),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Chụp thẳng toàn bộ bảng, đủ sáng, rõ các cột Họ tên, Điểm số, Điểm chữ. PNG hoặc JPEG, tối đa 10 MB. Hệ thống tự xác định học sinh theo họ tên.',
          ),
          const SizedBox(height: AppSpacing.lg),
          controls,
          const SizedBox(height: 18),
          ticketSection,
        ],
      ),
    );
  }

  Widget _headerIcon(AppTokens t) => DecoratedBox(
    decoration: BoxDecoration(
      color: t.priSoft,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Icon(Icons.document_scanner_rounded, color: t.priLink, size: 22),
    ),
  );

  /// Chỉ báo 4 bước, suy ra từ trạng thái đã có: đang tải ảnh lên, hoặc phiếu
  /// mới nhất trong danh sách. Không thêm trạng thái nghiệp vụ nào.
  Widget _buildStepper() {
    return FutureBuilder<List<RecognitionTicketDto>>(
      future: tickets,
      builder: (context, snapshot) {
        var current = 2;
        final items = snapshot.data;
        if (!busy && items != null && items.isNotEmpty) {
          final latest = items.reduce(
            (a, b) => b.createdAt.isAfter(a.createdAt) ? b : a,
          );
          current = switch (latest.status.value) {
            'DANG_XU_LY' => 3,
            'CHO_DOI_CHIEU' => 4,
            _ => 2,
          };
        }
        return _OcrStepper(current: current);
      },
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.subtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist_rounded, size: 18, color: t.priLink),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Quy chuẩn chụp bảng điểm',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildChecklistItem(
              context,
              Icons.crop_free_rounded,
              'Chụp thẳng toàn bộ bảng, đủ sáng, không bị bóng mờ',
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildChecklistItem(
              context,
              Icons.table_rows_rounded,
              'Bao gồm rõ các cột Họ tên, Điểm số, Điểm chữ (PNG/JPEG ≤ 10 MB)',
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildChecklistItem(
              context,
              Icons.auto_awesome_rounded,
              'Hệ thống tự động so khớp học sinh và đề xuất điểm',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: context.tokens.priLink),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: context.tokens.ink2,
            ),
          ),
        ),
      ],
    );
  }

  /// Khung thông báo nhỏ theo tông màu (nền nhạt, viền, biểu tượng).
  Widget _notice(
    BuildContext context, {
    required AppBadgeTone tone,
    required IconData icon,
    required Widget child,
  }) {
    final t = context.tokens;
    final (bg, fg, line) = switch (tone) {
      AppBadgeTone.ok => (t.okSoft, t.ok, t.okLine),
      AppBadgeTone.warn => (t.warnSoft, t.warn, t.warnLine),
      AppBadgeTone.bad => (t.badSoft, t.bad, t.badLine),
      AppBadgeTone.info => (t.priSoft, t.priLink, t.priLine),
      AppBadgeTone.neutral => (t.neuSoft, t.neu, t.line),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 18, color: fg),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadControls(BuildContext context, bool enabled, bool camera) {
    final theme = Theme.of(context);
    final t = context.tokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Chọn thành phần điểm (chip).
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Thành phần điểm (bắt buộc)*',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: t.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Chọn cột điểm (đang mở nhập)',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final item in widget.components)
                  _ComponentChip(
                    key: ValueKey('recognition-component-${item.id}'),
                    label: item.name,
                    selected: componentId == item.id,
                    onTap: enabled
                        ? () => setState(() => componentId = item.id)
                        : null,
                  ),
              ],
            ),
            if (componentId == null && widget.components.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Bắt buộc chọn cột điểm trước khi nhận dạng',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: t.priLink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            // Vùng chọn ảnh (dropzone nét đứt).
            CustomPaint(
              foregroundPainter: _DashedRRectPainter(
                color: enabled ? t.line2 : t.line,
                radius: AppRadius.md,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.subtle,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: narrow ? AppSpacing.md : AppSpacing.xl,
                    vertical: AppSpacing.xxl,
                  ),
                  child: LayoutBuilder(
                    builder: (context, inner) {
                      final buttonWidth = narrow ? inner.maxWidth : 220.0;
                      return Column(
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 36,
                            color: t.priLink,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Chọn hoặc chụp ảnh bảng điểm',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'PNG hoặc JPEG, tối đa 10 MB. Hệ thống tự xác định học sinh theo họ tên.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.md,
                            children: [
                              if (camera)
                                SizedBox(
                                  width: buttonWidth,
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
                              if (camera &&
                                  MediaQuery.sizeOf(context).width < 600)
                                SizedBox(
                                  width: buttonWidth,
                                  height: 48,
                                  child: TextButton.icon(
                                    key: const ValueKey(
                                      'recognition-capture-guide',
                                    ),
                                    onPressed: () => _openCaptureGuide(enabled),
                                    icon: const Icon(
                                      Icons.center_focus_strong_outlined,
                                    ),
                                    label: const Text('Hướng dẫn chụp'),
                                  ),
                                ),
                              SizedBox(
                                width: buttonWidth,
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
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: narrow ? Alignment.center : Alignment.centerRight,
              child: SizedBox(
                width: narrow ? constraints.maxWidth : 280,
                child: AppActionButton(
                  key: const ValueKey('recognition-upload'),
                  onPressed: enabled && image != null && componentId != null
                      ? upload
                      : null,
                  icon: Icons.cloud_upload_outlined,
                  label: 'Tải ảnh & Nhận dạng',
                ),
              ),
            ),
            if (image != null && componentId == null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: _notice(
                  context,
                  tone: AppBadgeTone.info,
                  icon: Icons.info_outline,
                  child: Text(
                    'Vui lòng chọn cột thành phần điểm (đang mở nhập) ở trên để kích hoạt nhận dạng.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: t.ink,
                    ),
                  ),
                ),
              ),
            if (!widget.enabled)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: _notice(
                  context,
                  tone: AppBadgeTone.warn,
                  icon: Icons.lock_outline_rounded,
                  child: Text(
                    'Bảng điểm hiện không cho phép gửi ảnh. Kiểm tra trạng thái chốt hoặc tải lại bảng điểm.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: t.ink),
                  ),
                ),
              ),
            if (widget.components.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: _notice(
                  context,
                  tone: AppBadgeTone.warn,
                  icon: Icons.event_busy_outlined,
                  child: Text(
                    'Không có cột điểm nào đang mở nhập để nhận dạng. Vui lòng kiểm tra thời hạn mở nhập cột điểm.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: t.ink),
                  ),
                ),
              ),
            if (imageError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: _notice(
                  context,
                  tone: AppBadgeTone.bad,
                  icon: Icons.error_outline_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        imageError!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: t.bad,
                        ),
                      ),
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
              ),
            if (image != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildPreview(context),
            ],
            if (busy || picking) ...[
              const SizedBox(height: 14),
              if (busy && uploadProgress != null)
                AppProgress(value: uploadProgress!, minWidth: 0)
              else
                LinearProgressIndicator(
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  color: t.pri,
                  backgroundColor: t.hover,
                ),
              const SizedBox(height: 6),
              Text(
                picking
                    ? 'Đang đọc ảnh…'
                    : uploadProgress == 1
                    ? 'Ảnh đã gửi, đang chờ xác nhận…'
                    : 'Đang tải ảnh…',
                style: theme.textTheme.bodyMedium,
              ),
              if (busy) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: narrow ? Alignment.center : Alignment.centerLeft,
                  child: SizedBox(
                    width: narrow ? double.infinity : null,
                    height: 48,
                    child: OutlinedButton.icon(
                      key: const ValueKey('recognition-cancel-upload'),
                      onPressed: cancelUpload,
                      icon: const Icon(Icons.close),
                      label: const Text('Hủy tải lên'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: t.bad,
                        side: BorderSide(color: t.bad),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _buildPreview(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final selected = image!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: t.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  selected.name,
                  key: const ValueKey('recognition-filename'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: t.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Ảnh chỉ vào được đây sau khi qua kiểm tra nội dung PNG/JPEG,
                // dung lượng, kích thước và giải mã; chưa có kiểm tra độ rõ.
                const AppBadge.ok('Định dạng hợp lệ'),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${(selected.bytes.length / 1024 / 1024).toStringAsFixed(2)} MB · Kiểm tra độ rõ trước khi gửi',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              onTap: () => showRecognitionImage(
                context,
                image: Image.memory(selected.bytes, fit: BoxFit.contain),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.subtle,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: t.line),
                ),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.memory(
                    selected.bytes,
                    cacheWidth: 640,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 12,
              children: [
                TextButton.icon(
                  onPressed: () => showRecognitionImage(
                    context,
                    image: Image.memory(selected.bytes, fit: BoxFit.contain),
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
        ),
      ),
    );
  }

  Widget _buildTicketSection(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    return FutureBuilder<List<RecognitionTicketDto>>(
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
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final heading = Text(
              'Lịch sử phiếu nhận dạng gần đây',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: t.ink2,
              ),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMobile) ...[
                  heading,
                  SwitchListTile(
                    key: const ValueKey('recognition-show-cancelled-switch'),
                    value: showCancelled,
                    onChanged: (val) {
                      setState(() {
                        showCancelled = val;
                        reload();
                      });
                    },
                    title: Text(
                      'Hiện phiếu đã hủy',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: t.ink,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ] else
                  Row(
                    children: [
                      Flexible(child: heading),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hiện phiếu đã hủy',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: t.ink2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            key: const ValueKey(
                              'recognition-show-cancelled-switch',
                            ),
                            value: showCancelled,
                            onChanged: (val) {
                              setState(() {
                                showCancelled = val;
                                reload();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Chưa có phiếu nhận dạng nào.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  )
                else ...[
                  for (final item in items.take(
                    showAllTickets ? items.length : 3,
                  ))
                    _buildTicketCard(context, item),
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
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTicketCard(BuildContext context, RecognitionTicketDto item) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final status = item.status.value;
    return Container(
      key: ValueKey('recognition-ticket-card-${item.ticketId}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: status == 'DA_HUY' ? t.subtle : t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: status == 'CHO_DOI_CHIEU' ? t.warnLine : t.line,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => showDetail(item.ticketId),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 4, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phiếu #${item.ticketId} · ${item.componentName}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: status == 'DA_HUY' ? t.ink2 : t.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Gửi lúc ${_formatDateTime(item.createdAt)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: PopupMenuButton<String>(
                        key: ValueKey('ticket-menu-${item.ticketId}'),
                        icon: const Icon(Icons.more_vert_rounded),
                        tooltip: 'Thao tác phiếu #${item.ticketId}',
                        onSelected: (action) {
                          if (action == 'view') {
                            showDetail(item.ticketId);
                          } else if (action == 'cancel') {
                            _handleCancelTicket(item);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Xem phiếu'),
                              ],
                            ),
                          ),
                          if (_canCancelTicket(item))
                            PopupMenuItem(
                              value: 'cancel',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.cancel_outlined,
                                    size: 18,
                                    color: t.bad,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Hủy phiếu',
                                    style: TextStyle(
                                      color: t.bad,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildTicketStatus(context, item),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    final y = local.year;
    return '$h:$m $d/$mo/$y';
  }

  /// Nhãn trạng thái (AppBadge) và thông tin kèm theo của một phiếu. Phiếu
  /// không có dữ liệu tiến độ nên không vẽ thanh phần trăm.
  Widget _buildTicketStatus(BuildContext context, RecognitionTicketDto item) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final small = theme.textTheme.bodySmall?.copyWith(fontSize: 12);
    final status = item.status.value;

    if (status == 'DA_HUY') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const AppBadge('Đã hủy'),
              if (item.cancelledAt != null)
                Text(
                  _formatDateTime(item.cancelledAt!),
                  style: small?.copyWith(fontSize: 11),
                ),
            ],
          ),
          if (item.cancelReason != null && item.cancelReason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Lý do: ${item.cancelReason}', style: small),
          ],
        ],
      );
    }
    if (status == 'DANG_XU_LY') {
      return Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const AppBadge.info('Đang xử lý'),
          SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: t.pri),
          ),
          Text('Tự động cập nhật sau 3 giây', style: small),
          if (_canCancelTicket(item))
            OutlinedButton.icon(
              key: ValueKey('ticket-cancel-quick-${item.ticketId}'),
              onPressed: () => _handleCancelTicket(item),
              icon: const Icon(Icons.close, size: 14),
              label: const Text('Hủy', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                foregroundColor: t.bad,
                side: BorderSide(color: t.bad),
                minimumSize: const Size(0, 32),
              ),
            ),
        ],
      );
    }
    if (status == 'CHO_DOI_CHIEU') {
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const AppBadge.warn('Chờ đối chiếu'),
          Text('${item.detectedRows ?? 0} dòng', style: small),
          AppBadge.ok('${item.greenRows} Xanh', dot: false),
          AppBadge.warn('${item.yellowRows} Vàng', dot: false),
          AppBadge.bad('${item.redRows} Đỏ', dot: false),
        ],
      );
    }
    if (status == 'DA_DUYET') {
      return Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const AppBadge.ok('Đã duyệt'),
          Text('Đã duyệt và ghi điểm chính thức', style: small),
        ],
      );
    }
    if (status == 'LOI') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBadge.bad('Lỗi'),
          const SizedBox(height: 4),
          Text(
            recognitionFailureMessage(item.errorCode),
            style: small?.copyWith(color: t.bad),
          ),
        ],
      );
    }
    return Align(alignment: Alignment.centerLeft, child: AppBadge(status));
  }
}

/// Chip chọn thành phần điểm (`.chip` của prototype): pill, cao tối thiểu 44,
/// mục đang chọn nền `priSoft` viền `pri`.
class _ComponentChip extends StatelessWidget {
  const _ComponentChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onTap != null;
    final fg = selected ? t.priLink : (enabled ? t.ink2 : t.ink3);
    const shape = StadiumBorder();
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: Material(
        color: selected ? t.priSoft : t.surface,
        shape: shape.copyWith(
          side: BorderSide(color: selected ? t.pri : t.line2),
        ),
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    Icon(Icons.check_rounded, size: 16, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontSize: 13.5,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Đường viền nét đứt bo góc của vùng chọn ảnh (`.drop` của prototype).
class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  static const double strokeWidth = 2;
  static const double dash = 7;
  static const double gap = 5;

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ).deflate(strokeWidth / 2);
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dash > metric.length
            ? metric.length
            : distance + dash;
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}

/// Chỉ báo 4 bước (`.steps`). Chỉ trình bày: `current` (1 đến 4) do màn cha
/// suy ra từ trạng thái đã có; bước trước `current` hiện dấu tích.
class _OcrStepper extends StatelessWidget {
  const _OcrStepper({required this.current});

  final int current;

  static const labels = [
    'Chọn bảng điểm',
    'Tải ảnh lên',
    'Hệ thống nhận dạng',
    'Đối chiếu & duyệt',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 680) {
          return Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < labels.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (i > 0) _line(context, i + 1 <= current, width: 40),
                    _item(context, i),
                  ],
                ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: i == 0
                              ? const SizedBox.shrink()
                              : _line(context, i + 1 <= current),
                        ),
                        _circle(context, i),
                        Expanded(
                          child: i == labels.length - 1
                              ? const SizedBox.shrink()
                              : _line(context, i + 2 <= current),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: _labelStyle(context, i, 11),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  TextStyle? _labelStyle(BuildContext context, int i, double size) {
    final t = context.tokens;
    final reached = i + 1 <= current;
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: size,
      color: reached ? t.ink : t.ink3,
      fontWeight: i + 1 == current ? FontWeight.w700 : FontWeight.w500,
    );
  }

  Widget _line(BuildContext context, bool reached, {double? width}) {
    final t = context.tokens;
    return SizedBox(
      width: width,
      height: 1,
      child: ColoredBox(color: reached ? t.pri : t.line2),
    );
  }

  Widget _circle(BuildContext context, int i) {
    final t = context.tokens;
    final reached = i + 1 <= current;
    final done = i + 1 < current;
    return Semantics(
      label: 'Bước ${i + 1}: ${labels[i]}',
      selected: reached,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: reached ? t.pri : t.surface,
          shape: BoxShape.circle,
          border: Border.all(color: reached ? t.pri : t.line2),
        ),
        child: SizedBox.square(
          dimension: 28,
          child: Center(
            child: done
                ? Icon(Icons.check_rounded, size: 16, color: t.onPri)
                : Text(
                    '${i + 1}',
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: reached ? t.onPri : t.ink3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int i) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _circle(context, i),
        const SizedBox(width: AppSpacing.sm),
        Text(labels[i], style: _labelStyle(context, i, 13.5)),
      ],
    );
  }
}
