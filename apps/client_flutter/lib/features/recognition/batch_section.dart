import 'dart:async';
import 'dart:ui' as ui;

import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_controls.dart';
import '../../app/widgets/app_progress.dart';
import 'batch_repository.dart';
import 'batch_result_screen.dart';
import 'cancel_batch_dialog.dart';
import 'image_picker.dart';

/// Phần "nhận dạng theo mẫu" của panel nhận dạng (ADR-0016 mục 5, giáo viên):
/// 1–4 ảnh trang → xác nhận cột → gửi lô → theo dõi lô. Khi xong mở màn kết quả
/// lô; mỗi phiếu vẫn đối chiếu bằng màn đối chiếu hiện có.
class BatchRecognitionSection extends ConsumerStatefulWidget {
  const BatchRecognitionSection({
    super.key,
    required this.gradebookId,
    required this.templateId,
    required this.templateName,
    required this.enabled,
    required this.onChanged,
  });

  final num gradebookId;
  final num templateId;
  final String templateName;
  final bool enabled;

  /// Gọi khi lô được tạo hoặc đổi trạng thái, để panel tải lại danh sách phiếu.
  final VoidCallback onChanged;

  @override
  ConsumerState<BatchRecognitionSection> createState() =>
      _BatchRecognitionSectionState();
}

class _BatchRecognitionSectionState
    extends ConsumerState<BatchRecognitionSection> {
  static const _pollInterval = Duration(seconds: 3);

  final List<RecognitionImage> pages = [];
  final Set<int> selected = {};
  MappingDto? mapping;
  String? mappingError;
  bool mappingLoading = true;
  int _mappingToken = 0;

  bool picking = false;
  bool busy = false;
  double? uploadProgress;
  CancelToken? _uploadCancelToken;
  String? imageError;
  String? submitError;
  bool tooManyPages = false;

  String? batchId;
  RecognitionBatchDto? batch;
  String? pollError;
  bool cancelling = false;
  Timer? _pollTimer;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _loadMapping();
    final tracked = ref.read(trackedBatchProvider(widget.gradebookId));
    if (tracked != null) {
      batchId = tracked;
      WidgetsBinding.instance.addPostFrameCallback((_) => _poll());
    }
  }

  @override
  void didUpdateWidget(covariant BatchRecognitionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.templateId != widget.templateId ||
        oldWidget.gradebookId != widget.gradebookId) {
      selected.clear();
      _loadMapping();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _uploadCancelToken?.cancel();
    super.dispose();
  }

  RecognitionBatchRepository get _repo =>
      ref.read(recognitionBatchRepositoryProvider);

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  // ---- Ánh xạ cột ---------------------------------------------------------

  /// Lý do cột không chọn được; `null` nếu chọn được.
  static String? unavailableReason(MappingItemDto item) {
    if (item.locked) {
      return 'Cột đã khóa, ngoài thời gian nhập hoặc không nhận ảnh.';
    }
    if (item.pending) {
      return 'Đang có phiếu chờ xử lý hoặc đối chiếu cho cột này.';
    }
    if (item.componentId == null) {
      return 'Môn này không có thành phần điểm tương ứng với cột.';
    }
    return null;
  }

  Future<void> _loadMapping() async {
    final token = ++_mappingToken;
    mappingLoading = true;
    mappingError = null;
    if (mounted) setState(() {});
    try {
      final loaded = await _repo.mapping(
        gradebookId: widget.gradebookId,
        templateId: widget.templateId,
      );
      if (!mounted || token != _mappingToken) return;
      setState(() {
        mapping = loaded;
        mappingLoading = false;
        selected.removeWhere(
          (index) => !loaded.items.any(
            (item) =>
                item.templateColumnIndex.toInt() == index &&
                unavailableReason(item) == null,
          ),
        );
      });
    } catch (error) {
      if (!mounted || token != _mappingToken) return;
      setState(() {
        mapping = null;
        mappingLoading = false;
        mappingError = batchErrorMessage(error);
      });
    }
  }

  // ---- Ảnh các trang ------------------------------------------------------

  Future<void> _ensureDecodable(RecognitionImage image) async {
    recognitionImageMime(image);
    try {
      final codec = await ui.instantiateImageCodec(
        image.bytes,
        targetWidth: 320,
      );
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
    } catch (_) {
      throw const RecognitionImageException(
        'Không đọc được ảnh. Hãy chọn ảnh PNG/JPEG khác.',
      );
    }
  }

  Future<void> _addPage({bool camera = false}) async {
    if (busy || picking || !widget.enabled) return;
    if (pages.length >= kMaxBatchPages) {
      setState(() => tooManyPages = true);
      return;
    }
    setState(() {
      picking = true;
      imageError = null;
      tooManyPages = false;
    });
    try {
      final picker = ref.read(recognitionImagePickerProvider);
      final picked = camera && picker is RecognitionCameraPicker
          ? await (picker as RecognitionCameraPicker).capture()
          : await picker.pick();
      if (picked != null) {
        await _ensureDecodable(picked);
        if (mounted) setState(() => pages.add(picked));
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

  void _movePage(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= pages.length) return;
    setState(() {
      final item = pages.removeAt(index);
      pages.insert(target, item);
    });
  }

  void _removePage(int index) => setState(() {
    pages.removeAt(index);
    tooManyPages = false;
  });

  // ---- Gửi lô -------------------------------------------------------------

  bool get _canSubmit =>
      widget.enabled &&
      !busy &&
      !picking &&
      pages.isNotEmpty &&
      selected.isNotEmpty &&
      mapping != null;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final loaded = mapping!;
    final choices = <BatchComponentChoice>[];
    for (final item in loaded.items) {
      final index = item.templateColumnIndex.toInt();
      final componentId = item.componentId;
      if (!selected.contains(index) ||
          componentId == null ||
          unavailableReason(item) != null) {
        continue;
      }
      choices.add(
        BatchComponentChoice(
          templateColumnIndex: index,
          componentId: componentId,
        ),
      );
    }
    if (choices.isEmpty) return;
    final cancelToken = CancelToken();
    _uploadCancelToken = cancelToken;
    final pageCount = pages.length;
    setState(() {
      busy = true;
      uploadProgress = null;
      submitError = null;
      imageError = null;
    });
    try {
      final receipt = await _repo.submit(
        gradebookId: widget.gradebookId,
        templateId: widget.templateId,
        images: List.of(pages),
        components: choices,
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          if (mounted && total > 0) {
            setState(() => uploadProgress = (sent / total).clamp(0, 1));
          }
        },
      );
      if (!mounted) return;
      _uploadCancelToken = null;
      ref
          .read(batchTicketInfoProvider.notifier)
          .update(
            (map) => {
              ...map,
              for (final ticket in receipt.tickets)
                ticket.ticketId: BatchTicketInfo(
                  batchId: receipt.batchId,
                  pageCount: pageCount,
                  templateId: widget.templateId,
                  templateName: widget.templateName,
                ),
            },
          );
      ref.read(trackedBatchProvider(widget.gradebookId).notifier).state =
          receipt.batchId;
      setState(() {
        busy = false;
        uploadProgress = null;
        pages.clear();
        selected.clear();
        batchId = receipt.batchId;
        batch = null;
        pollError = null;
        _navigating = false;
      });
      _showMessage('Đã tải ảnh. Hệ thống đang nhận dạng.');
      widget.onChanged();
      _loadMapping();
      _schedulePoll();
    } catch (error) {
      if (!mounted) return;
      _uploadCancelToken = null;
      if (error is DioException && CancelToken.isCancel(error)) {
        setState(() {
          busy = false;
          uploadProgress = null;
        });
        _showMessage('Đã hủy tải lên');
        return;
      }
      setState(() {
        busy = false;
        uploadProgress = null;
        submitError = batchErrorMessage(error);
      });
    }
  }

  // ---- Theo dõi lô --------------------------------------------------------

  void _schedulePoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer(_pollInterval, _poll);
  }

  Future<void> _poll() async {
    final id = batchId;
    if (id == null || !mounted) return;
    try {
      final loaded = await _repo.detail(
        gradebookId: widget.gradebookId,
        batchId: id,
      );
      if (!mounted || batchId != id) return;
      setState(() {
        batch = loaded;
        pollError = null;
      });
      if (loaded.status == RecognitionBatchDtoStatusEnum.DANG_XU_LY) {
        _schedulePoll();
        return;
      }
      widget.onChanged();
      _loadMapping();
      if (loaded.status == RecognitionBatchDtoStatusEnum.XONG) {
        _openResult(auto: true);
      } else if (loaded.status == RecognitionBatchDtoStatusEnum.DA_HUY) {
        ref.read(trackedBatchProvider(widget.gradebookId).notifier).state =
            null;
      }
    } catch (error) {
      if (!mounted || batchId != id) return;
      final notFound =
          error is DioException && error.response?.statusCode == 404;
      setState(() => pollError = batchErrorMessage(error));
      if (!notFound) _schedulePoll();
    }
  }

  void _openResult({bool auto = false}) {
    final id = batchId;
    if (id == null || _navigating) return;
    if (auto && !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _navigating = true;
    if (auto) {
      ref.read(trackedBatchProvider(widget.gradebookId).notifier).state = null;
    }
    openBatchResult(
      context,
      gradebookId: widget.gradebookId,
      batchId: id,
    ).whenComplete(() {
      if (!mounted) return;
      _navigating = false;
      widget.onChanged();
      _loadMapping();
    });
  }

  Future<void> _cancelBatch() async {
    final id = batchId;
    if (id == null || cancelling) return;
    final cancelled = await showCancelBatchDialog(
      context: context,
      gradebookId: widget.gradebookId,
      batchId: id,
    );
    if (cancelled != true || !mounted) return;
    _pollTimer?.cancel();
    ref.read(trackedBatchProvider(widget.gradebookId).notifier).state = null;
    _showMessage('Đã hủy lô #$id');
    await _poll();
  }

  void _dismissBatch() {
    _pollTimer?.cancel();
    ref.read(trackedBatchProvider(widget.gradebookId).notifier).state = null;
    setState(() {
      batchId = null;
      batch = null;
      pollError = null;
    });
  }

  // ---- Giao diện ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final enabled = widget.enabled && !busy && !picking;
    final picker = ref.read(recognitionImagePickerProvider);
    final camera =
        picker is RecognitionCameraPicker &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 600;
        return Column(
          key: const ValueKey('batch-section'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ảnh các trang (1–$kMaxBatchPages ảnh)*',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: t.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Thêm theo đúng thứ tự trang của tờ. PNG hoặc JPEG, tối đa 10 MB mỗi ảnh.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < pages.length; i++)
              _pageCard(context, i, enabled),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                if (camera)
                  SizedBox(
                    width: narrow ? constraints.maxWidth : 220,
                    child: AppActionButton(
                      key: const ValueKey('batch-camera'),
                      kind: AppActionButtonKind.secondary,
                      onPressed: enabled ? () => _addPage(camera: true) : null,
                      icon: Icons.camera_alt_outlined,
                      label: 'Chụp trang',
                    ),
                  ),
                SizedBox(
                  width: narrow ? constraints.maxWidth : 220,
                  child: AppActionButton(
                    key: const ValueKey('batch-add-page'),
                    kind: AppActionButtonKind.secondary,
                    onPressed: enabled ? () => _addPage() : null,
                    icon: Icons.add_photo_alternate_outlined,
                    label: pages.isEmpty
                        ? 'Chọn ảnh trang 1'
                        : 'Thêm ảnh trang',
                  ),
                ),
              ],
            ),
            if (tooManyPages)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: _notice(
                  context,
                  key: const ValueKey('batch-too-many'),
                  tone: AppBadgeTone.warn,
                  icon: Icons.layers_outlined,
                  text:
                      'Mỗi lô chỉ có tối đa $kMaxBatchPages trang. Xóa bớt ảnh rồi thêm lại.',
                ),
              ),
            if (imageError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: _notice(
                  context,
                  key: const ValueKey('batch-image-error'),
                  tone: AppBadgeTone.bad,
                  icon: Icons.error_outline_rounded,
                  text: imageError!,
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            _mappingBlock(context),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: narrow ? Alignment.center : Alignment.centerRight,
              child: SizedBox(
                width: narrow ? constraints.maxWidth : 280,
                child: AppActionButton(
                  key: const ValueKey('batch-submit'),
                  onPressed: _canSubmit ? _submit : null,
                  icon: Icons.cloud_upload_outlined,
                  label: 'Tải ảnh & Nhận dạng',
                ),
              ),
            ),
            if (!busy && (pages.isEmpty || selected.isEmpty))
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  pages.isEmpty && selected.isEmpty
                      ? 'Thêm ít nhất 1 ảnh và chọn ít nhất 1 cột để gửi.'
                      : pages.isEmpty
                      ? 'Thêm ít nhất 1 ảnh để gửi.'
                      : 'Chọn ít nhất 1 cột để gửi.',
                  key: const ValueKey('batch-submit-hint'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (submitError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: _notice(
                  context,
                  key: const ValueKey('batch-submit-error'),
                  tone: AppBadgeTone.bad,
                  icon: Icons.error_outline_rounded,
                  text: submitError!,
                ),
              ),
            if (busy || picking) ...[
              const SizedBox(height: AppSpacing.md),
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
                    : 'Đang tải ${pages.length} ảnh…',
                key: const ValueKey('batch-upload-status'),
                style: theme.textTheme.bodyMedium,
              ),
              if (busy) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: narrow ? double.infinity : null,
                  height: 48,
                  child: OutlinedButton.icon(
                    key: const ValueKey('batch-cancel-upload'),
                    onPressed: () =>
                        _uploadCancelToken?.cancel('USER_CANCELLED'),
                    icon: const Icon(Icons.close),
                    label: const Text('Hủy tải lên'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: t.bad,
                      side: BorderSide(color: t.bad),
                    ),
                  ),
                ),
              ],
            ],
            if (batchId != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _batchCard(context),
            ],
          ],
        );
      },
    );
  }

  Widget _notice(
    BuildContext context, {
    Key? key,
    required AppBadgeTone tone,
    required IconData icon,
    required String text,
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
      key: key,
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
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: t.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageCard(BuildContext context, int index, bool enabled) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final page = pages[index];
    return Container(
      key: ValueKey('batch-page-$index'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: t.subtle,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: t.line),
                ),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Image.memory(
                    page.bytes,
                    cacheWidth: 160,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trang ${index + 1}',
                      key: ValueKey('batch-page-label-$index'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: t.ink,
                      ),
                    ),
                    Text(
                      page.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${(page.bytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              children: [
                IconButton(
                  key: ValueKey('batch-page-up-$index'),
                  tooltip: 'Đưa trang ${index + 1} lên trước',
                  onPressed: enabled && index > 0
                      ? () => _movePage(index, -1)
                      : null,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
                IconButton(
                  key: ValueKey('batch-page-down-$index'),
                  tooltip: 'Đưa trang ${index + 1} xuống sau',
                  onPressed: enabled && index < pages.length - 1
                      ? () => _movePage(index, 1)
                      : null,
                  icon: const Icon(Icons.arrow_downward_rounded),
                ),
                IconButton(
                  key: ValueKey('batch-page-remove-$index'),
                  tooltip: 'Xóa trang ${index + 1}',
                  onPressed: enabled ? () => _removePage(index) : null,
                  icon: Icon(Icons.delete_outline_rounded, color: t.bad),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mappingBlock(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final loaded = mapping;
    final selectable = loaded == null
        ? const <MappingItemDto>[]
        : [
            for (final item in loaded.items)
              if (unavailableReason(item) == null) item,
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cột điểm cần nhận dạng*',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: t.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Xác nhận cột trên tờ sẽ vào thành phần điểm nào của môn. Mẫu: ${widget.templateName}.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (mappingLoading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: CircularProgressIndicator(
                key: ValueKey('batch-mapping-loading'),
              ),
            ),
          )
        else if (mappingError != null)
          Row(
            key: const ValueKey('batch-mapping-error'),
            children: [
              Expanded(
                child: Text(
                  mappingError!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: t.bad),
                ),
              ),
              TextButton(
                key: const ValueKey('batch-mapping-retry'),
                onPressed: _loadMapping,
                child: const Text('Thử lại'),
              ),
            ],
          )
        else if (loaded == null || loaded.items.isEmpty)
          Text(
            'Mẫu này không có cột điểm để nhận dạng.',
            key: const ValueKey('batch-mapping-empty'),
            style: theme.textTheme.bodyMedium,
          )
        else ...[
          for (final item in loaded.items) _columnTile(context, item),
          if (selectable.length > 1)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('batch-select-all'),
                onPressed: widget.enabled && !busy
                    ? () => setState(() {
                        final all = selectable.map(
                          (item) => item.templateColumnIndex.toInt(),
                        );
                        if (selected.containsAll(all)) {
                          selected.clear();
                        } else {
                          selected.addAll(all);
                        }
                      })
                    : null,
                icon: const Icon(Icons.done_all_rounded),
                label: Text(
                  selected.length == selectable.length
                      ? 'Bỏ chọn tất cả'
                      : 'Chọn tất cả cột chọn được',
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _columnTile(BuildContext context, MappingItemDto item) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final index = item.templateColumnIndex.toInt();
    final reason = unavailableReason(item);
    final usable = reason == null && widget.enabled && !busy;
    final channels = item.channels == MappingItemDtoChannelsEnum.SO_CHU
        ? 'số + chữ'
        : 'chỉ số';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: reason == null ? t.surface : t.subtle,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: selected.contains(index) ? t.pri : t.line),
        ),
        child: CheckboxListTile(
          key: ValueKey('batch-column-$index'),
          value: selected.contains(index),
          onChanged: usable
              ? (on) => setState(() {
                  if (on == true) {
                    selected.add(index);
                  } else {
                    selected.remove(index);
                  }
                })
              : null,
          controlAffinity: ListTileControlAffinity.leading,
          dense: false,
          title: Text(
            'Cột ${item.key} → ${item.componentName ?? 'chưa có thành phần'} · $channels',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: reason == null ? t.ink : t.ink3,
            ),
          ),
          subtitle: reason == null
              ? null
              : Text(
                  reason,
                  key: ValueKey('batch-column-reason-$index'),
                  style: theme.textTheme.bodySmall,
                ),
        ),
      ),
    );
  }

  Widget _batchCard(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final current = batch;
    final status = current?.status ?? RecognitionBatchDtoStatusEnum.DANG_XU_LY;
    final small = theme.textTheme.bodySmall?.copyWith(fontSize: 12);
    final Widget body;
    switch (status) {
      case RecognitionBatchDtoStatusEnum.DANG_XU_LY:
        body = Wrap(
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
            OutlinedButton.icon(
              key: const ValueKey('batch-cancel'),
              onPressed: _cancelBatch,
              icon: const Icon(Icons.close, size: 14),
              label: const Text('Hủy lô', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: t.bad,
                side: BorderSide(color: t.bad),
                minimumSize: const Size(0, 36),
              ),
            ),
          ],
        );
      case RecognitionBatchDtoStatusEnum.XONG:
        body = Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const AppBadge.ok('Đã nhận dạng xong'),
            FilledButton.icon(
              key: const ValueKey('batch-open-result'),
              onPressed: () => _openResult(),
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: const Text('Mở kết quả theo thành phần'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            ),
            TextButton(
              key: const ValueKey('batch-dismiss'),
              onPressed: _dismissBatch,
              child: const Text('Ẩn'),
            ),
          ],
        );
      case RecognitionBatchDtoStatusEnum.LOI:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppBadge.bad('Lỗi'),
            const SizedBox(height: 4),
            Text(
              batchFailureMessage(current?.errorCode, current?.errorPage),
              key: const ValueKey('batch-error'),
              style: small?.copyWith(color: t.bad),
            ),
            TextButton(
              key: const ValueKey('batch-dismiss'),
              onPressed: _dismissBatch,
              child: const Text('Đóng thông báo'),
            ),
          ],
        );
      case RecognitionBatchDtoStatusEnum.DA_HUY:
        body = Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const AppBadge('Đã hủy'),
            if (current?.cancelReason != null)
              Text('Lý do: ${current!.cancelReason}', style: small),
            TextButton(
              key: const ValueKey('batch-dismiss'),
              onPressed: _dismissBatch,
              child: const Text('Ẩn'),
            ),
          ],
        );
    }
    return Container(
      key: const ValueKey('batch-status-card'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: status == RecognitionBatchDtoStatusEnum.LOI
              ? t.badLine
              : t.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lô nhận dạng #$batchId',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: t.ink,
            ),
          ),
          if (current != null)
            Text(
              '${current.pageCount.toInt()} trang · ${current.tickets.length} cột',
              style: small,
            ),
          const SizedBox(height: AppSpacing.sm),
          body,
          if (pollError != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Chưa cập nhật được trạng thái lô: $pollError',
                key: const ValueKey('batch-poll-error'),
                style: small?.copyWith(color: t.bad),
              ),
            ),
        ],
      ),
    );
  }
}
