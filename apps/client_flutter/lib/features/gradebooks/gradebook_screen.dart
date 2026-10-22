import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_dialog.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../app/widgets/app_select_field.dart';
import '../authentication/session.dart';
import '../final_results/final_results_panel.dart';
import '../final_results/repository.dart';
import '../final_results/student_results_screen.dart'
    show classificationBadgeOf;
import '../recognition/recognition_panel.dart';
import '../reports/reports_panel.dart';
import '../academic_catalog/semester_deadlines_repository.dart'
    show apiErrorCode, deadlineErrorMessage;
import 'adjustments_repository.dart';
import 'adjustments_screen.dart'
    show
        AdjustmentDetailDialog,
        adjustmentStatusBadge,
        formatAdjustmentDateTime;
import 'excel_import_dialog.dart';
import 'grade_deadlines_panel.dart';
import 'gradebook_status.dart';
import 'repository.dart';

class GradebookScreen extends ConsumerStatefulWidget {
  const GradebookScreen({super.key, required this.bookId});

  final num bookId;

  @override
  ConsumerState<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends ConsumerState<GradebookScreen> {
  late Future<CellsResponseDto> data;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    data = ref.read(gradebooksRepositoryProvider).cells(widget.bookId);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CellsResponseDto>(
    future: data,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return AppScaffold(
          title: 'Bảng điểm #${widget.bookId}',
          currentPath: '/gradebooks',
          showBackButton: true,
          onBack: () => context.go('/gradebooks'),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return AppScaffold(
          title: 'Bảng điểm #${widget.bookId}',
          currentPath: '/gradebooks',
          showBackButton: true,
          onBack: () => context.go('/gradebooks'),
          body: _GradebookLoadError(
            error: snapshot.error!,
            retry: () => setState(reload),
          ),
        );
      }
      final value = snapshot.data!;
      return GradebookEditor(
        key: ValueKey('${value.book.id}-${value.book.version}'),
        data: value,
        onReload: () => setState(reload),
      );
    },
  );
}

class GradebookEditor extends ConsumerStatefulWidget {
  const GradebookEditor({
    super.key,
    required this.data,
    required this.onReload,
  });

  final CellsResponseDto data;
  final VoidCallback onReload;

  @override
  ConsumerState<GradebookEditor> createState() => _GradebookEditorState();
}

class _GradebookEditorState extends ConsumerState<GradebookEditor> {
  final formKey = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  final horizontalGridController = ScrollController();
  final verticalGridController = ScrollController();
  bool busy = false;
  bool conflict = false;
  num? _selectedComponentId;
  late Future<List<FinalResultDto>> finalResults;
  List<MissingStudentDto>? _missingStudents;
  bool adjustmentMode = false;
  final _adjustmentDraft = <String, _AdjustmentDraftCell>{};
  AdjustmentDto? _pendingAdjustment;
  AdjustmentDto? _latestRejectedAdjustment;
  List<AdjustmentDto>? _adjustmentsHistory;

  bool get teacher => ref.read(sessionProvider)?.role.value == 'GIAO_VIEN';
  bool get admin => ref.read(sessionProvider)?.role.value == 'QUAN_TRI_VIEN';
  bool get hasLockedColumn =>
      widget.data.items.any((c) => c.columnLocked == true);
  bool get canRequestAdjustment =>
      teacher &&
      hasLockedColumn &&
      widget.data.book.pendingAdjustmentId == null;
  int get adjustmentChangedCount =>
      _adjustmentDraft.values.where((d) => d.isChanged).length;
  String resultScore(String? value) => value == null
      ? '—'
      : widget.data.items.firstOrNull?.passFail == true
      ? (value == '10.0' ? 'Đạt' : 'Không đạt')
      : value;
  String classificationLabel(String value) => value == 'CHUA_CONG_BO'
      ? 'Chưa công bố'
      : value == 'DAT'
      ? 'Đạt'
      : value == 'CHUA_DAT'
      ? 'Không đạt'
      : value;
  bool get locked => widget.data.book.status.value == 'DA_CHOT';
  bool get editable => teacher && !locked && !conflict;

  @override
  void initState() {
    super.initState();
    for (final cell in widget.data.items) {
      controllers[cell.id] = TextEditingController(text: cell.value ?? '');
    }
    finalResults = locked
        ? ref
            .read(finalResultsRepositoryProvider)
            .list(widget.data.book.id)
            .then((r) => r.items)
        : Future.value(const []);
    if (admin) {
      _loadMissingStudents();
    }
    if (widget.data.book.pendingAdjustmentId != null) {
      _loadPendingAdjustment(widget.data.book.pendingAdjustmentId!);
    }
    _loadAdjustmentsHistory();
  }

  Future<void> _loadPendingAdjustment(String adjId) async {
    try {
      final adj =
          await ref.read(adjustmentsRepositoryProvider).getDetail(adjId);
      if (mounted) setState(() => _pendingAdjustment = adj);
    } catch (_) {}
  }

  Future<void> _loadAdjustmentsHistory() async {
    try {
      final items = await ref
          .read(adjustmentsRepositoryProvider)
          .listForBook(widget.data.book.id);
      if (!mounted) return;
      setState(() {
        _adjustmentsHistory = items;
        if (items.isNotEmpty &&
            items.first.status == AdjustmentDtoStatusEnum.TU_CHOI &&
            widget.data.book.pendingAdjustmentId == null) {
          _latestRejectedAdjustment = items.first;
        } else {
          _latestRejectedAdjustment = null;
        }
      });
    } catch (_) {}
  }

  Future<void> _loadMissingStudents() async {
    try {
      final items = await ref
          .read(gradebooksRepositoryProvider)
          .missingStudents(widget.data.book.id);
      if (mounted) setState(() => _missingStudents = items);
    } catch (_) {}
  }

  Future<String?> askLateStudentReason(String studentName) async {
    var reason = '';
    String? error;
    final value = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AppDialog(
          title: 'Xử lý học sinh vào muộn',
          confirmLabel: 'Xác nhận',
          onCancel: () => Navigator.pop(ctx),
          onConfirm: () {
            final normalized = reason.trim();
            if (normalized.isEmpty) {
              setDialogState(() => error = 'Cần nhập lý do.');
              return;
            }
            if (normalized.length > 500) {
              setDialogState(() => error = 'Lý do tối đa 500 ký tự.');
              return;
            }
            Navigator.pop(ctx, normalized);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Học sinh: $studentName'),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('late-student-reason-field'),
                autofocus: true,
                maxLength: 500,
                maxLines: 3,
                onChanged: (value) => reason = value,
                decoration: InputDecoration(
                  labelText: 'Lý do bổ sung vào bảng điểm',
                  hintText: 'Nhập lý do (1–500 ký tự)',
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return value;
  }

  Future<void> handleLateStudent(MissingStudentDto student) async {
    final reason = await askLateStudentReason(student.studentName);
    if (reason == null || !mounted) return;
    await mutate(() async {
      await ref.read(gradebooksRepositoryProvider).addLateStudent(
            bookId: widget.data.book.id,
            studentId: student.studentId,
            reason: reason,
          );
      await _loadMissingStudents();
    }, success: 'Đã xử lý học sinh ${student.studentName}');
  }

  Future<String?> askExemptionReason({required bool exempt}) async {
    var reason = '';
    String? error;
    final value = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AppDialog(
          title: exempt ? 'Đánh dấu miễn' : 'Bỏ miễn',
          confirmLabel: 'Xác nhận',
          onCancel: () => Navigator.pop(ctx),
          onConfirm: () {
            final normalized = reason.trim();
            if (normalized.isEmpty) {
              setDialogState(() => error = 'Cần nhập lý do.');
              return;
            }
            if (normalized.length > 500) {
              setDialogState(() => error = 'Lý do tối đa 500 ký tự.');
              return;
            }
            Navigator.pop(ctx, normalized);
          },
          child: TextField(
            key: const ValueKey('exemption-reason-field'),
            autofocus: true,
            maxLength: 500,
            maxLines: 3,
            onChanged: (value) => reason = value,
            decoration: InputDecoration(
              labelText: 'Lý do ${exempt ? "miễn" : "bỏ miễn"}',
              hintText: 'Nhập lý do (1–500 ký tự)',
              errorText: error,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ),
    );
    return value;
  }

  Future<void> setExemption(GradeCellDto cell, {required bool exempt}) async {
    final reason = await askExemptionReason(exempt: exempt);
    if (reason == null || !mounted) return;
    await mutate(() async {
      await ref.read(gradebooksRepositoryProvider).setExemptions(
            bookId: widget.data.book.id,
            expectedVersion: widget.data.book.version,
            changes: [
              ExemptionChangeInput(
                cellId: cell.id,
                exempt: exempt,
                reason: reason,
              ),
            ],
          );
    }, success: exempt ? 'Đã đánh dấu miễn' : 'Đã bỏ miễn');
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    horizontalGridController.dispose();
    verticalGridController.dispose();
    super.dispose();
  }

  String? validateGrade(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return null;
    if (!RegExp(r'^(?:[0-9]\.[0-9]|10\.0)$').hasMatch(value)) {
      return 'Dùng 0.0–10.0';
    }
    return null;
  }

  List<GradeCellDto> changedCells() => widget.data.items.where((cell) {
    if (cell.openForInput == false || cell.columnLocked == true) return false;
    if (cell.status.value == 'MIEN' || cell.active == false) return false;
    final text = controllers[cell.id]?.text.trim() ?? '';
    return (text.isEmpty ? null : text) != cell.value;
  }).toList();

  Future<String?> askReason(int count) async {
    var reason = '';
    String? error;
    final value = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AppDialog(
          title: 'Lưu $count ô điểm',
          confirmLabel: 'Xác nhận lưu',
          onCancel: () => Navigator.pop(ctx),
          onConfirm: () {
            final normalized = reason.trim();
            if (normalized.isEmpty) {
              setDialogState(() => error = 'Cần nhập lý do.');
              return;
            }
            Navigator.pop(ctx, normalized);
          },
          child: TextField(
            autofocus: true,
            maxLength: 500,
            maxLines: 3,
            onChanged: (value) => reason = value,
            decoration: InputDecoration(
              labelText: 'Lý do thay đổi',
              hintText: 'Ví dụ: Nhập điểm kiểm tra giữa kỳ',
              errorText: error,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ),
    );
    return value;
  }

  Future<void> save() async {
    setState(() => conflict = false);
    if (!(formKey.currentState?.validate() ?? false)) return;
    final changed = changedCells();
    if (changed.isEmpty) {
      showMessage('Chưa có ô điểm nào thay đổi.');
      return;
    }
    if (changed.length > 100) {
      showMessage('Mỗi lần chỉ lưu tối đa 100 ô điểm.');
      return;
    }
    final reason = await askReason(changed.length);
    if (reason == null || !mounted) return;
    await mutate(() async {
      await ref
          .read(gradebooksRepositoryProvider)
          .update(
            bookId: widget.data.book.id,
            expectedVersion: widget.data.book.version,
            changes: changed
                .map(
                  (cell) => GradeChangeInput(
                    cellId: cell.id,
                    value: controllers[cell.id]!.text.trim().isEmpty
                        ? null
                        : controllers[cell.id]!.text.trim(),
                    reason: reason,
                  ),
                )
                .toList(),
          );
    }, success: 'Đã lưu ${changed.length} ô điểm.');
  }

  Future<void> syncRoster() async {
    await mutate(() async {
      await ref
          .read(gradebooksRepositoryProvider)
          .syncRoster(
            bookId: widget.data.book.id,
            expectedVersion: widget.data.book.version,
          );
    }, success: 'Đã đồng bộ sĩ số.');
  }

  Future<void> openExcelImport(
    Map<num, List<GradeCellDto>> students,
    List<GradeCellDto> components,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => ExcelImportDialog(
        bookId: widget.data.book.id,
        students: students,
        components: components,
        onApply: (updatedValues, reason) async {
          for (final entry in updatedValues.entries) {
            if (controllers.containsKey(entry.key)) {
              controllers[entry.key]!.text = entry.value;
            }
          }
          final changed = changedCells();
          if (changed.isEmpty) {
            showMessage(
              'Các điểm trong file trùng khớp với điểm hiện tại trên hệ thống.',
            );
            return;
          }
          await mutate(
            () async {
              await ref
                  .read(gradebooksRepositoryProvider)
                  .update(
                    bookId: widget.data.book.id,
                    expectedVersion: widget.data.book.version,
                    changes: changed
                        .map(
                          (cell) => GradeChangeInput(
                            cellId: cell.id,
                            value: controllers[cell.id]!.text.trim().isEmpty
                                ? null
                                : controllers[cell.id]!.text.trim(),
                            reason: reason,
                          ),
                        )
                        .toList(),
                  );
            },
            success:
                'Đã nạp thành công ${changed.length} con điểm từ file Excel.',
          );
        },
      ),
    );
  }

  /// Xác định lỗi 409 có phải là xung đột phiên bản bảng điểm (cần hiện banner vàng và khóa lưới) hay không.
  /// Chỉ bật xung đột khi 409 KHÔNG có code nghiệp vụ, hoặc code là VERSION_OR_STATE_CONFLICT / CONFLICT (lệch phiên bản).
  bool isGradebookConflict(Object error) {
    if (error is! DioException || error.response?.statusCode != 409) {
      return false;
    }
    final code = apiErrorCode(error);
    if (code == null || code.isEmpty) {
      return true;
    }
    return code == 'VERSION_OR_STATE_CONFLICT' ||
        code == 'VERSION_CONFLICT' ||
        code == 'CONFLICT' ||
        code == 'GRADEBOOK_VERSION_OR_STATE_CONFLICT';
  }

  Future<void> mutate(
    Future<void> Function() action, {
    required String success,
  }) async {
    setState(() {
      busy = true;
      conflict = false;
    });
    try {
      await action();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      showMessage(success);
      widget.onReload();
    } catch (error) {
      if (!mounted) return;
      final isConflict = isGradebookConflict(error);
      setState(() {
        busy = false;
        conflict = isConflict;
      });
      showMessage(deadlineErrorMessage(error));
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> showAllHistory() async {
    await showDialog<void>(
      context: context,
      builder: (_) => GradebookHistoryDialog(bookId: widget.data.book.id),
    );
  }

  Future<void> showFinalResults() async {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: FinalResultsPanel(
            gradebookId: widget.data.book.id,
            gradebookVersion: widget.data.book.version,
            resultsOutdated: widget.data.book.resultsOutdated,
            showResults: true,
          ),
        ),
      ),
    );
    if (mounted && locked) {
      setState(() {
        finalResults = ref
            .read(finalResultsRepositoryProvider)
            .list(widget.data.book.id)
            .then((r) => r.items);
      });
    }
  }

  void showIdentifiers() {
    showDialog<void>(
      context: context,
      builder: (context) => AppDialog(
        title: 'Mã tham chiếu bảng điểm',
        showFooter: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mã bảng điểm: ${widget.data.book.id}\n'
              'Mã lớp: ${widget.data.book.classId}\n'
              'Mã môn: ${widget.data.book.subjectId}\n'
              'Mã học kỳ: ${widget.data.book.termId}',
            ),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dải trạng thái dưới thanh tab: nhãn "Đang nhập liệu" / "Đã khóa" và, chỉ
  /// khi mọi cột đều có lịch đóng, "Khóa lúc" kèm giờ muộn nhất (kế hoạch 0.1).
  /// Không có nút chốt: điểm tự khóa theo hạn nhà trường đặt (ADR-0014).
  Widget _buildStatusStrip(List<GradeCellDto> orderedComponents) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final closesAt = latestColumnClosesAt(orderedComponents);
    return DecoratedBox(
      key: const ValueKey('gradebook-status-strip'),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            GradebookStatusBadge(widget.data.book.status.value),
            if (closesAt != null)
              Row(
                key: const ValueKey('gradebook-close-time'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_clock_outlined, size: 16, color: t.ink3),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Khóa lúc ${deadlineLabel(context, closesAt.toIso8601String())}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: t.ink2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingStudentsBanner() {
    final t = context.tokens;
    final count = _missingStudents!.length;
    return Container(
      key: const ValueKey('missing-students-banner'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.warnSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.warn),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: t.warn),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Có $count học sinh vào lớp sau khi cột đã chốt',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: t.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _missingStudents!.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: t.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.studentName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      key: ValueKey('process-late-${s.studentId}'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 32),
                      ),
                      onPressed: () => handleLateStudent(s),
                      child: const Text('Xử lý'),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget? _buildStickyBottomBar() {
    final theme = Theme.of(context);
    final t = context.tokens;

    if (adjustmentMode) {
      final n = adjustmentChangedCount;
      return DecoratedBox(
        key: const ValueKey('adjustment-mode-bottom-bar'),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border(top: BorderSide(color: t.line)),
          boxShadow: t.pop,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  color: n > 0 ? t.priLink : t.ink3,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã đổi $n ô',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: n > 0 ? t.ink : t.ink3,
                    ),
                  ),
                ),
                OutlinedButton(
                  key: const ValueKey('cancel-adjustment-mode-btn'),
                  onPressed: busy ? null : _cancelAdjustmentMode,
                  child: const Text('Hủy soạn'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: const ValueKey('submit-adjustment-btn'),
                  onPressed: busy || n == 0 ? null : _submitAdjustmentRequest,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Gửi yêu cầu'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!editable) return null;
    final changed = changedCells();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.line)),
        boxShadow: t.pop,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: changed.isNotEmpty ? t.priLink : t.ink3,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  changed.isNotEmpty
                      ? 'Đã sửa ${changed.length} ô điểm'
                      : 'Chưa có thay đổi',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: changed.isNotEmpty ? t.ink : t.ink3,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: busy ? null : save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawStudents = <num, List<GradeCellDto>>{};
    for (final cell in widget.data.items) {
      rawStudents.putIfAbsent(cell.studentId, () => []).add(cell);
    }
    final sortedStudentRows = rawStudents.values.toList()
      ..sort((a, b) {
        final sttA = a.isNotEmpty ? a.first.stt : null;
        final sttB = b.isNotEmpty ? b.first.stt : null;
        if (sttA != null && sttB != null) {
          final cmp = sttA.compareTo(sttB);
          if (cmp != 0) return cmp;
        } else if (sttA != null && sttB == null) {
          return -1;
        } else if (sttA == null && sttB != null) {
          return 1;
        }
        final idA = a.isNotEmpty ? a.first.studentId : 0;
        final idB = b.isNotEmpty ? b.first.studentId : 0;
        return idA.compareTo(idB);
      });
    final students = {
      for (final row in sortedStudentRows) row.first.studentId: row,
    };
    final components = <num, GradeCellDto>{};
    for (final cell in widget.data.items) {
      components.putIfAbsent(cell.componentId, () => cell);
    }
    final orderedComponents = components.values.toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return FutureBuilder<List<FinalResultDto>>(
      future: finalResults,
      builder: (context, resultsSnapshot) {
        final results = {
          for (final result in resultsSnapshot.data ?? const <FinalResultDto>[])
            result.studentId: result,
        };

        return DefaultTabController(
          length: 3,
          child: AppScaffold(
            title:
                '${widget.data.book.className} · ${widget.data.book.subjectName}',
            currentPath: '/gradebooks',
            showBackButton: true,
            onBack: () => context.go('/gradebooks'),
            titleWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.data.book.className} · ${widget.data.book.subjectName}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.tokens.heading,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.data.book.termName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.tokens.ink2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      ' · ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.tokens.ink2,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'Phiên bản ${widget.data.book.version}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.tokens.ink2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Tải lại',
                onPressed: widget.onReload,
                icon: const Icon(Icons.refresh),
              ),
              PopupMenuButton<String>(
                tooltip: 'Thao tác khác',
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (action) {
                  switch (action) {
                    case 'history':
                      showAllHistory();
                      break;
                    case 'request_adjustment':
                      _startAdjustmentMode();
                      break;
                    case 'sync_roster':
                      syncRoster();
                      break;
                    case 'import_excel':
                      openExcelImport(students, orderedComponents);
                      break;
                    case 'identifiers':
                      showIdentifiers();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(Icons.history_outlined, size: 20),
                        SizedBox(width: 10),
                        Expanded(child: Text('Lịch sử cập nhật')),
                      ],
                    ),
                  ),
                  if (canRequestAdjustment && !adjustmentMode)
                    const PopupMenuItem(
                      value: 'request_adjustment',
                      child: Row(
                        children: [
                          Icon(Icons.edit_calendar_outlined, size: 20),
                          SizedBox(width: 10),
                          Expanded(child: Text('Yêu cầu điều chỉnh')),
                        ],
                      ),
                    ),
                  if (editable)
                    PopupMenuItem(
                      value: 'sync_roster',
                      enabled: !busy,
                      child: const Row(
                        children: [
                          Icon(Icons.group_add_outlined, size: 20),
                          SizedBox(width: 10),
                          Expanded(child: Text('Đồng bộ sĩ số')),
                        ],
                      ),
                    ),
                  if (editable)
                    PopupMenuItem(
                      value: 'import_excel',
                      enabled: !busy,
                      child: const Row(
                        children: [
                          Icon(Icons.table_chart_outlined, size: 20),
                          SizedBox(width: 10),
                          Expanded(child: Text('Nhập từ Excel')),
                        ],
                      ),
                    ),
                  if (admin)
                    const PopupMenuItem(
                      value: 'identifiers',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 10),
                          Expanded(child: Text('Mã tham chiếu')),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.edit_note_rounded), text: 'Nhập điểm'),
                Tab(
                  icon: Icon(Icons.camera_alt_outlined),
                  text: 'Quét ảnh OCR',
                ),
                Tab(
                  icon: Icon(Icons.analytics_outlined),
                  text: 'Báo cáo & Tiện ích',
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusStrip(orderedComponents),
                if (admin &&
                    _missingStudents != null &&
                    _missingStudents!.isNotEmpty)
                  _buildMissingStudentsBanner(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTabGradeEntry(
                        students,
                        sortedStudentRows,
                        orderedComponents,
                        results,
                      ),
                      _buildTabOcr(orderedComponents),
                      _buildTabReports(students, orderedComponents),
                    ],
                  ),
                ),
              ],
            ),
            bottomBar: _buildStickyBottomBar(),
          ),
        );
      },
    );
  }

  Widget _buildTabGradeEntry(
    Map<num, List<GradeCellDto>> students,
    List<List<GradeCellDto>> sortedStudentRows,
    List<GradeCellDto> orderedComponents,
    Map<num, FinalResultDto> results,
  ) {
    if (widget.data.items.isEmpty) {
      return const Center(child: Text('Bảng điểm chưa có ô dữ liệu.'));
    }

    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (conflict)
          MaterialBanner(
            backgroundColor: t.warnSoft,
            dividerColor: t.warnLine,
            contentTextStyle: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: t.warn),
            content: const Text(
              'Bảng điểm đã thay đổi ở nơi khác. Tải lại để đối chiếu trước khi nhập lại.',
            ),
            actions: [
              TextButton(
                onPressed: widget.onReload,
                child: const Text('Tải lại'),
              ),
            ],
          ),
        if (widget.data.book.resultsOutdated == true)
          Container(
            key: const ValueKey('gradebook-results-outdated-banner'),
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: t.warnSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: t.warnLine),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 20, color: t.warn),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Điểm đã được điều chỉnh — cần Tính kết quả lại',
                    style: TextStyle(
                      color: t.warn,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: showFinalResults,
                  icon: const Icon(Icons.calculate_outlined, size: 16),
                  label: const Text('Tính kết quả'),
                ),
              ],
            ),
          ),
        if (adjustmentMode)
          Container(
            key: const ValueKey('adjustment-mode-banner'),
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: t.priSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: t.priLine),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_calendar_rounded, size: 20, color: t.priLink),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đang soạn phiếu điều chỉnh — chỉ các cột đã chốt, chưa ghi vào điểm chính thức',
                    style: TextStyle(
                      color: t.priLink,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _cancelAdjustmentMode,
                  child: const Text('Hủy soạn'),
                ),
              ],
            ),
          ),
        if (widget.data.book.pendingAdjustmentId != null) ...[
          Container(
            key: const ValueKey('adjustment-pending-banner'),
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: t.warnSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: t.warnLine),
            ),
            child: Row(
              children: [
                Icon(Icons.hourglass_top_rounded, size: 20, color: t.warn),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Phiếu điều chỉnh #${widget.data.book.pendingAdjustmentId} đang chờ duyệt'
                    '${_pendingAdjustment != null ? " (${_pendingAdjustment!.lineCount} ô)" : ""}',
                    style: TextStyle(
                      color: t.warn,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                OutlinedButton(
                  key: const ValueKey('view-pending-adjustment-btn'),
                  onPressed: _openPendingDetail,
                  child: const Text('Xem'),
                ),
                if (admin) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const ValueKey('open-to-approve-adjustment-btn'),
                    onPressed: _openPendingDetail,
                    style: FilledButton.styleFrom(
                      backgroundColor: t.ok,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Mở để duyệt'),
                  ),
                ],
                if (teacher &&
                    _pendingAdjustment != null &&
                    _pendingAdjustment!.submittedBy.id ==
                        ref.read(sessionProvider)?.id) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    key: const ValueKey('cancel-pending-adjustment-btn'),
                    onPressed: () =>
                        _cancelPendingAdjustment(_pendingAdjustment!),
                    style: OutlinedButton.styleFrom(foregroundColor: t.bad),
                    child: const Text('Hủy phiếu'),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (_latestRejectedAdjustment != null && !adjustmentMode)
          Container(
            key: const ValueKey('adjustment-rejected-banner'),
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    'Phiếu gần nhất bị từ chối: ${_latestRejectedAdjustment!.decisionReason ?? _latestRejectedAdjustment!.reason}',
                    style: TextStyle(
                      color: t.bad,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                FilledButton.tonal(
                  key: const ValueKey('recompose-rejected-adjustment-btn'),
                  onPressed: () =>
                      _recomposeFromRejected(_latestRejectedAdjustment!),
                  child: const Text('Soạn lại từ phiếu này'),
                ),
              ],
            ),
          ),
        if (locked) _buildReadOnlyNotice(),
        DecoratedBox(
          decoration: BoxDecoration(
            color: t.surface,
            border: Border(bottom: BorderSide(color: t.line)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    selected: _selectedComponentId == null,
                    avatar: Icon(
                      Icons.grid_view_rounded,
                      size: 16,
                      color: _selectedComponentId == null ? t.priLink : t.ink2,
                    ),
                    label: Text(
                      'Tất cả cột',
                      style: TextStyle(
                        color: _selectedComponentId == null ? t.priLink : t.ink,
                        fontWeight: _selectedComponentId == null
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    backgroundColor: t.surface,
                    selectedColor: t.priSoft,
                    checkmarkColor: t.priLink,
                    side: BorderSide(
                      color: _selectedComponentId == null ? t.priLine : t.line,
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedComponentId = null),
                  ),
                  for (final comp in orderedComponents) ...[
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _selectedComponentId == comp.componentId,
                      avatar: comp.openForInput == false
                          ? Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: t.warn,
                            )
                          : null,
                      label: Text(
                        comp.componentName,
                        style: TextStyle(
                          color: _selectedComponentId == comp.componentId
                              ? t.priLink
                              : t.ink,
                          fontWeight: _selectedComponentId == comp.componentId
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      backgroundColor: t.surface,
                      selectedColor: t.priSoft,
                      checkmarkColor: t.priLink,
                      side: BorderSide(
                        color: _selectedComponentId == comp.componentId
                            ? t.priLine
                            : t.line,
                      ),
                      onSelected: (_) => setState(
                        () => _selectedComponentId = comp.componentId,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        _buildLegend(),
        if (busy) const LinearProgressIndicator(),
        Expanded(
          child: Form(
            key: formKey,
            child: _selectedComponentId != null
                ? _singleColumnView(sortedStudentRows, orderedComponents)
                : LayoutBuilder(
                    builder: (context, box) => box.maxWidth >= 800
                        ? _wideGrid(students, orderedComponents, results)
                        : _mobileGrid(students, results),
                  ),
          ),
        ),
      ],
    );
  }

  /// Thông báo chỉ-đọc khi bảng đã khóa (`.alert.ok` của `gv-grid`). Chữ theo
  /// ADR-0014: điểm tự khóa theo hạn nhà trường đặt, không hướng dẫn "chốt".
  Widget _buildReadOnlyNotice() {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DecoratedBox(
        key: const ValueKey('gradebook-readonly-notice'),
        decoration: BoxDecoration(
          color: t.okSoft,
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
          border: Border.all(color: t.okLine),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, size: 18, color: t.ok),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Bảng điểm đã khóa. ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: t.ok,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Chỉ xem, không sửa được. Điểm tự khóa khi đến hạn nhập do nhà trường đặt.',
                        style: TextStyle(color: t.ok),
                      ),
                    ],
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (canRequestAdjustment && !adjustmentMode) ...[
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  key: const ValueKey('request-adjustment-btn'),
                  onPressed: _startAdjustmentMode,
                  icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                  label: const Text('Yêu cầu điều chỉnh'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Chú giải màu ô điểm (`.legend` của prototype); chỉ giải thích kiểu hiển thị
  /// của ô đã sửa, nhập từ ảnh và điểm không hợp lệ.
  Widget _buildLegend() {
    final t = context.tokens;
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: t.ink2);
    Widget item(Widget swatch, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
    Widget box(Color fill, Color border) => DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: border),
      ),
      child: const SizedBox(width: 14, height: 14),
    );
    return Padding(
      key: const ValueKey('gradebook-legend'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          item(box(t.accSoft, t.warnLine), 'Ô đã sửa'),
          item(
            DecoratedBox(
              decoration: BoxDecoration(color: t.ok, shape: BoxShape.circle),
              child: const SizedBox(width: 8, height: 8),
            ),
            'Nhập từ ảnh',
          ),
          item(box(t.badSoft, t.bad), 'Điểm không hợp lệ'),
        ],
      ),
    );
  }

  Widget _singleColumnView(
    List<List<GradeCellDto>> sortedStudentRows,
    List<GradeCellDto> orderedComponents,
  ) {
    final t = context.tokens;
    final selectedComp = orderedComponents.firstWhere(
      (c) => c.componentId == _selectedComponentId,
    );
    final isLocked =
        selectedComp.openForInput == false || selectedComp.columnLocked == true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: t.subtle,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: t.line),
          ),
          child: Row(
            children: [
              Icon(
                isLocked
                    ? Icons.lock_outline_rounded
                    : Icons.info_outline_rounded,
                size: 18,
                color: isLocked ? t.warn : t.priLink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cột: ${selectedComp.componentName} · Hệ số ${selectedComp.coefficient} · '
                  '${selectedComp.required_ ? 'Bắt buộc' : 'Không bắt buộc'}'
                  '${isLocked ? ' · (Đang khóa)' : ''}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        for (final studentRow in sortedStudentRows) ...[
          Builder(
            builder: (context) {
              final student = studentRow.first;
              final cell = studentRow.cast<GradeCellDto?>().firstWhere(
                (c) => c?.componentId == _selectedComponentId,
                orElse: () => null,
              );
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _sttAvatar(student.stt, radius: 16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.studentName,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (!student.active)
                              Text(
                                'Đã chuyển/nghỉ',
                                style: TextStyle(color: t.bad, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (cell != null)
                        _gradeField(cell, width: 150)
                      else
                        const Text('—'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  /// Vòng tròn STT của hàng học sinh (thẻ mobile và chế độ một cột).
  Widget _sttAvatar(num? stt, {required double radius}) {
    final t = context.tokens;
    return CircleAvatar(
      radius: radius,
      backgroundColor: t.priSoft,
      child: Text(
        stt != null ? '$stt' : '—',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: t.priLink,
        ),
      ),
    );
  }

  /// Nhãn nhỏ "● AI" cho ô nhập từ ảnh nhận dạng.
  Widget _aiTag() {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.okSoft,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: t.okLine),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          '● AI',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: t.ok,
          ),
        ),
      ),
    );
  }

  Widget _buildTabOcr(List<GradeCellDto> orderedComponents) {
    if (!teacher) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: context.tokens.ink3,
              ),
              const SizedBox(height: 12),
              Text(
                'Chức năng nhận dạng OCR chỉ dành cho giáo viên phụ trách.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: RecognitionPanel(
        gradebookId: widget.data.book.id,
        components: [
          for (final item in orderedComponents.where(
            (c) =>
                c.columnLocked != true &&
                c.passFail != true &&
                c.openForInput != false,
          ))
            RecognitionComponentOption(item.componentId, item.componentName),
        ],
        gradebookVersion: widget.data.book.version,
        enabled: !locked && !busy && !conflict,
        onApproved: widget.onReload,
        embedded: true,
        classSubjectLabel:
            '${widget.data.book.className} · ${widget.data.book.subjectName}',
      ),
    );
  }

  /// Thẻ hành động trong tab "Báo cáo & Tiện ích": ô biểu tượng, tiêu đề, mô tả
  /// và một nút bên phải.
  Widget _actionCard({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget action,
  }) {
    final theme = Theme.of(context);
    final t = context.tokens;
    return Card(
      child: Padding(
        padding: AppSpacing.cardBody,
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(AppRadius.sm + 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: iconColor),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: t.ink2),
                  ),
                ],
              ),
            ),
            action,
          ],
        ),
      ),
    );
  }

  Widget _buildTabReports(
    Map<num, List<GradeCellDto>> students,
    List<GradeCellDto> orderedComponents,
  ) {
    final t = context.tokens;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReportsPanel(gradebookId: widget.data.book.id, compact: false),
          const SizedBox(height: 16),
          _buildAdjustmentsHistorySection(),
          const SizedBox(height: 16),
          if (editable) ...[
            _actionCard(
              icon: Icons.file_upload_outlined,
              iconBackground: t.priSoft,
              iconColor: t.priLink,
              title: 'Nhập điểm từ Excel',
              subtitle: 'Nạp điểm học sinh tự động từ bảng tính Excel',
              action: FilledButton.tonalIcon(
                onPressed: busy
                    ? null
                    : () => openExcelImport(students, orderedComponents),
                icon: const Icon(Icons.table_chart_outlined, size: 18),
                label: const Text('Nhập Excel'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (locked && teacher) ...[
            _actionCard(
              icon: Icons.functions_rounded,
              iconBackground: t.okSoft,
              iconColor: t.ok,
              title: 'Tổng kết môn học',
              subtitle:
                  'Tính ĐTB và xếp loại cho toàn bộ học sinh trong bảng điểm',
              action: FilledButton.icon(
                onPressed: showFinalResults,
                icon: const Icon(Icons.calculate_outlined, size: 18),
                label: const Text('Tính tổng kết'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          GradeDeadlinesPanel(
            bookId: widget.data.book.id,
            components: orderedComponents,
            isAdmin: !teacher,
            locked: locked,
            onReload: widget.onReload,
          ),
        ],
      ),
    );
  }

  Widget _wideGrid(
    Map<num, List<GradeCellDto>> students,
    List<GradeCellDto> components,
    Map<num, FinalResultDto> results,
  ) {
    final t = context.tokens;
    return LayoutBuilder(
      builder: (context, box) {
        final sizes = _GridColumnSizes.fit(
          available: box.maxWidth - 32,
          components: components.length,
          withResults: locked,
        );
        return _wideGridTable(students, components, results, sizes, t);
      },
    );
  }

  Widget _wideGridTable(
    Map<num, List<GradeCellDto>> students,
    List<GradeCellDto> components,
    Map<num, FinalResultDto> results,
    _GridColumnSizes sizes,
    AppTokens t,
  ) {
    return Scrollbar(
      controller: horizontalGridController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: horizontalGridController,
        scrollDirection: Axis.horizontal,
        child: Scrollbar(
          controller: verticalGridController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: verticalGridController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            child: DataTable(
              headingRowHeight: 64,
              horizontalMargin: _GridColumnSizes.horizontalMargin,
              columnSpacing: _GridColumnSizes.columnSpacing,
              columns: [
                const DataColumn(label: Text('STT')),
                const DataColumn(label: Text('Học sinh')),
                for (final component in components)
                  DataColumn(
                    label: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: sizes.component),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${component.componentName}\nHệ số ${component.coefficient}',
                              ),
                              const SizedBox(height: 2),
                              Text(
                                component.required_
                                    ? 'Bắt buộc'
                                    : 'Không bắt buộc',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: component.required_
                                          ? t.priLink
                                          : t.ink3,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          if (component.openForInput == false) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message:
                                  'Cột đang khóa hoặc ngoài lịch nhập nhà trường đặt',
                              child: Icon(
                                Icons.lock_outline_rounded,
                                size: 14,
                                color: t.warn,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                if (locked) ...[
                  DataColumn(
                    label: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: sizes.total),
                      child: const Text('Điểm tổng kết'),
                    ),
                  ),
                  DataColumn(
                    label: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: sizes.classification,
                      ),
                      child: const Text('Xếp loại'),
                    ),
                  ),
                ],
              ],
              rows: [
                for (final entry in students.values.toList().asMap().entries)
                  DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: _GridColumnSizes.stt,
                          child: Text(
                            entry.value.first.stt != null
                                ? '${entry.value.first.stt}'
                                : '—',
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: sizes.student,
                          child: Text(
                            entry.value.first.active
                                ? entry.value.first.studentName
                                : '${entry.value.first.studentName}\nĐã chuyển/nghỉ',
                          ),
                        ),
                      ),
                      for (final component in components)
                        DataCell(
                          Builder(
                            builder: (context) {
                              final cell = entry.value
                                  .cast<GradeCellDto?>()
                                  .firstWhere(
                                    (c) =>
                                        c?.componentId == component.componentId,
                                    orElse: () => null,
                                  );
                              return SizedBox(
                                width: sizes.component,
                                child: cell != null
                                    ? Align(
                                        alignment: Alignment.centerLeft,
                                        child: _gradeField(
                                          cell,
                                          width: sizes.field,
                                        ),
                                      )
                                    : const Text('—'),
                              );
                            },
                          ),
                        ),
                      if (locked) ...[
                        DataCell(
                          SizedBox(
                            width: sizes.total,
                            child: Text(
                              resultScore(
                                results[entry.value.first.studentId]
                                    ?.finalScore,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: sizes.classification,
                            child: results[entry.value.first.studentId] == null
                                ? const Text('—')
                                : Align(
                                    alignment: Alignment.centerLeft,
                                    child: _classificationBadge(
                                      results[entry.value.first.studentId]!
                                          .classification,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Nhãn xếp loại: chữ giữ nguyên như bản cũ ([classificationLabel]), màu theo
  /// ánh xạ MÃ của [classificationBadgeOf] (không so ngưỡng ở client).
  Widget _classificationBadge(String code) => AppBadge(
    classificationLabel(code),
    tone: classificationBadgeOf(code).tone,
    dot: false,
  );

  Widget _mobileGrid(
    Map<num, List<GradeCellDto>> students,
    Map<num, FinalResultDto> results,
  ) {
    final t = context.tokens;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        for (final entry in students.values.toList().asMap().entries)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _sttAvatar(entry.value.first.stt, radius: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.value.first.studentName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (!entry.value.first.active)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Đã chuyển/nghỉ',
                        style: TextStyle(color: t.bad, fontSize: 12),
                      ),
                    ),
                  if (locked) ...[
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.subtle,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: t.line),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          'Điểm tổng kết: '
                          '${resultScore(results[entry.value.first.studentId]?.finalScore)} · '
                          'Xếp loại: ${classificationLabel(results[entry.value.first.studentId]?.classification ?? 'CHUA_CONG_BO')}',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  for (final cell in entry.value) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${cell.componentName} · Hệ số ${cell.coefficient} · '
                            '${cell.required_ ? 'Bắt buộc' : 'Không bắt buộc'}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (cell.source_.value == 'NHAN_DIEN') _aiTag(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _gradeField(cell, width: double.infinity),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Kiểu ô điểm theo `.gc` của prototype, dựng ngay tại chỗ cũ bằng token để
  /// giữ `TextFormField` / `DropdownButtonFormField` và `ValueKey` mà test ghim.
  /// Thứ tự màu: không hợp lệ (viền `bad`), đã sửa chưa lưu (nền `accSoft`),
  /// bình thường. [invalid] và [changed] lấy từ logic sẵn có (`validateGrade`,
  /// so sánh với giá trị đã lưu như `changedCells`), widget không tự kiểm tra.
  InputDecoration _gradeDecoration({
    required bool enabled,
    required bool invalid,
    required bool changed,
    String? labelText,
    String? hintText,
    String? helperText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final t = context.tokens;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: color, width: width),
        );
    final Color fill;
    final Color edge;
    if (invalid) {
      fill = t.badSoft;
      edge = t.bad;
    } else if (changed) {
      fill = t.accSoft;
      edge = t.warnLine;
    } else if (!enabled) {
      fill = t.subtle;
      edge = t.line;
    } else {
      fill = t.surface;
      edge = t.line2;
    }
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: true,
      filled: true,
      fillColor: fill,
      border: border(edge),
      enabledBorder: border(edge),
      disabledBorder: border(edge),
      focusedBorder: border(invalid ? t.bad : t.pri, 1.5),
      errorBorder: border(t.bad),
      focusedErrorBorder: border(t.bad, 1.5),
    );
  }

  Widget _gradeField(GradeCellDto cell, {double width = 170}) {
    if (adjustmentMode && cell.columnLocked == true && teacher) {
      return _buildAdjustmentCell(cell, width: width);
    }

    final t = context.tokens;
    final isLocked = cell.columnLocked == true || cell.openForInput == false;
    final isPending = cell.status.value == 'CHO_DOI_CHIEU';
    final isAi = cell.source_.value == 'NHAN_DIEN';
    final isExempt = cell.status.value == 'MIEN';

    if (isExempt) {
      final tooltipMsg = (cell.exemptionReason != null &&
              cell.exemptionReason!.isNotEmpty)
          ? cell.exemptionReason!
          : 'Miễn';
      final canUnexempt = editable && cell.active && !isLocked;

      return SizedBox(
        width: width,
        child: Tooltip(
          message: tooltipMsg,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: t.subtle,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: t.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Miễn',
                    key: ValueKey('grade-exempt-${cell.id}'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: t.ink2,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (canUnexempt)
                  PopupMenuButton<String>(
                    key: ValueKey('cell-exempt-menu-${cell.id}'),
                    icon: Icon(Icons.more_vert, size: 16, color: t.ink3),
                    padding: EdgeInsets.zero,
                    tooltip: 'Thao tác ô miễn',
                    onSelected: (val) {
                      if (val == 'unexempt') setExemption(cell, exempt: false);
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(
                        value: 'unexempt',
                        child: Text('Bỏ miễn'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final isEnabled = editable && cell.active && !isLocked && !isPending;
    final currentText = controllers[cell.id]!.text.trim();
    final isChanged =
        isEnabled && (currentText.isEmpty ? null : currentText) != cell.value;
    final isInvalid = isEnabled && validateGrade(currentText) != null;
    final isEmptyCell =
        (cell.value == null || cell.value!.isEmpty) && currentText.isEmpty;
    final canMarkExempt =
        editable && cell.active && !isLocked && !isPending && isEmptyCell;

    final menuButton = PopupMenuButton<String>(
      key: ValueKey('cell-menu-${cell.id}'),
      icon: Icon(Icons.more_vert, size: 16, color: t.ink3),
      padding: EdgeInsets.zero,
      tooltip: 'Thao tác ô điểm',
      onSelected: (val) {
        if (val == 'exempt') setExemption(cell, exempt: true);
      },
      itemBuilder: (ctx) => const [
        PopupMenuItem(
          value: 'exempt',
          child: Text('Đánh dấu miễn'),
        ),
      ],
    );

    return SizedBox(
      width: width,
      child: GestureDetector(
        onSecondaryTap:
            canMarkExempt ? () => setExemption(cell, exempt: true) : null,
        onLongPress:
            canMarkExempt ? () => setExemption(cell, exempt: true) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAi && width < 200)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _aiTag(),
              ),
            Expanded(
              child: cell.passFail == true
                  ? Row(
                      children: [
                        Expanded(
                          child: AppSelectField<String>(
                            key: ValueKey('grade-pf-${cell.id}'),
                            value: controllers[cell.id]!.text.isEmpty
                                ? 'EMPTY'
                                : controllers[cell.id]!.text,
                            label: 'Đánh giá',
                            dense: true,
                            searchable: false,
                            prefixIcon: isLocked
                                ? Tooltip(
                                    message:
                                        'Cột đang khóa hoặc ngoài lịch nhập',
                                    child: Icon(
                                      Icons.lock_outline_rounded,
                                      size: 14,
                                      color: t.warn,
                                    ),
                                  )
                                : null,
                            items: const [
                              DropdownMenuItem(
                                value: 'EMPTY',
                                child: Text('Chưa đánh giá'),
                              ),
                              DropdownMenuItem(
                                value: '10.0',
                                child: Text('Đạt'),
                              ),
                              DropdownMenuItem(
                                value: '0.0',
                                child: Text('Không đạt'),
                              ),
                            ],
                            onChanged: isEnabled
                                ? (v) => setState(() {
                                    controllers[cell.id]!.text = v == 'EMPTY'
                                        ? ''
                                        : v ?? '';
                                  })
                                : null,
                          ),
                        ),
                        if (canMarkExempt) menuButton,
                      ],
                    )
                  : TextFormField(
                      key: ValueKey('grade-${cell.id}'),
                      controller: controllers[cell.id],
                      enabled: isEnabled,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        setState(() {});
                      },
                      decoration: _gradeDecoration(
                        enabled: isEnabled,
                        invalid: isInvalid,
                        changed: isChanged,
                        hintText: '—',
                        prefixIcon: isLocked
                            ? Tooltip(
                                message:
                                    'Cột đang khóa hoặc ngoài lịch nhập nhà trường đặt',
                                child: Icon(
                                  Icons.lock_rounded,
                                  size: 14,
                                  color: t.warn,
                                ),
                              )
                            : null,
                        suffixIcon: canMarkExempt ? menuButton : null,
                        helperText: cell.columnLocked == true
                            ? 'Cột đã chốt'
                            : cell.openForInput == false
                            ? 'Ngoài lịch nhập'
                            : isPending
                            ? 'Chờ đối chiếu'
                            : cell.value == null
                            ? 'Chưa có điểm'
                            : null,
                      ),
                      validator: validateGrade,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  _AdjustmentDraftCell _getOrCreateDraft(GradeCellDto cell) {
    return _adjustmentDraft.putIfAbsent(cell.id, () {
      final isExempt = cell.status.value == 'MIEN';
      return _AdjustmentDraftCell(
        originalValue: cell.value,
        originalExempt: isExempt,
        newValue: cell.value,
        newExempt: isExempt,
      );
    });
  }

  List<({GradeCellDto cell, _AdjustmentDraftCell draft})> _getChangedDrafts() {
    final list = <({GradeCellDto cell, _AdjustmentDraftCell draft})>[];
    for (final item in widget.data.items) {
      final draft = _adjustmentDraft[item.id];
      if (draft != null && draft.isChanged) {
        list.add((cell: item, draft: draft));
      }
    }
    return list;
  }

  void _startAdjustmentMode() {
    setState(() {
      adjustmentMode = true;
      _adjustmentDraft.clear();
      for (final cell in widget.data.items) {
        if (cell.columnLocked == true) {
          final isExempt = cell.status.value == 'MIEN';
          _adjustmentDraft[cell.id] = _AdjustmentDraftCell(
            originalValue: cell.value,
            originalExempt: isExempt,
            newValue: cell.value,
            newExempt: isExempt,
          );
        }
      }
    });
  }

  void _cancelAdjustmentMode() {
    setState(() {
      adjustmentMode = false;
      _adjustmentDraft.clear();
      for (final cell in widget.data.items) {
        controllers[cell.id]?.text = cell.value ?? '';
      }
    });
  }

  Future<void> _recomposeFromRejected(AdjustmentDto rejectedAdj) async {
    setState(() => busy = true);
    try {
      final detail = await ref
          .read(adjustmentsRepositoryProvider)
          .getDetail(rejectedAdj.id);
      if (!mounted) return;
      setState(() {
        busy = false;
        adjustmentMode = true;
        _adjustmentDraft.clear();
        for (final cell in widget.data.items) {
          if (cell.columnLocked == true) {
            final isExempt = cell.status.value == 'MIEN';
            _adjustmentDraft[cell.id] = _AdjustmentDraftCell(
              originalValue: cell.value,
              originalExempt: isExempt,
              newValue: cell.value,
              newExempt: isExempt,
            );
          }
        }
        for (final line in detail.lines ?? const <AdjustmentLineDto>[]) {
          final cell =
              widget.data.items.where((c) => c.id == line.cellId).firstOrNull;
          if (cell != null) {
            final draft = _getOrCreateDraft(cell);
            draft.newExempt = line.newExempt;
            draft.newValue = line.newValue;
            draft.note = line.note;
            if (!line.newExempt && line.newValue != null) {
              controllers[cell.id]?.text = line.newValue!;
            }
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => busy = false);
      showMessage(adjustmentErrorMessage(e));
    }
  }

  void _revertCellDraft(GradeCellDto cell) {
    setState(() {
      _adjustmentDraft.remove(cell.id);
      controllers[cell.id]?.text = cell.value ?? '';
    });
  }

  Future<void> _showCellNoteDialog(GradeCellDto cell) async {
    final draft = _getOrCreateDraft(cell);
    var note = draft.note ?? '';
    final result = await showAppDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AppDialog(
          title: 'Ghi chú ô điểm',
          confirmLabel: 'Lưu ghi chú',
          cancelLabel: 'Đóng',
          onConfirm: () => Navigator.pop(ctx, note.trim()),
          onCancel: () => Navigator.pop(ctx),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Học sinh: ${cell.studentName} • Cột: ${cell.componentName}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                maxLength: 200,
                maxLines: 3,
                controller: TextEditingController(text: note),
                onChanged: (val) => note = val,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú điều chỉnh (≤ 200 ký tự)',
                  hintText: 'Nhập lý do hoặc chi tiết cho ô điểm này...',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) {
      setState(() {
        draft.note = result.isEmpty ? null : result;
      });
    }
  }

  Future<void> _showUnexemptDialog(GradeCellDto cell) async {
    final draft = _getOrCreateDraft(cell);
    var enteredValue = '';
    String? error;
    final isPassFail = cell.passFail == true;
    if (isPassFail) {
      enteredValue = '10.0';
    }

    final result = await showAppDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AppDialog(
          title: 'Bỏ miễn và nhập điểm',
          confirmLabel: 'Xác nhận',
          cancelLabel: 'Hủy',
          onConfirm: () {
            if (isPassFail) {
              if (enteredValue.isEmpty) {
                setDialogState(() => error = 'Vui lòng chọn Đạt hoặc Không đạt');
                return;
              }
              Navigator.pop(ctx, enteredValue);
            } else {
              final val = enteredValue.trim();
              if (val.isEmpty) {
                setDialogState(() => error = 'Bắt buộc nhập điểm');
                return;
              }
              final gradeErr = validateGrade(val);
              if (gradeErr != null) {
                setDialogState(() => error = gradeErr);
                return;
              }
              Navigator.pop(ctx, val);
            }
          },
          onCancel: () => Navigator.pop(ctx),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Học sinh: ${cell.studentName} • Cột: ${cell.componentName}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (isPassFail)
                DropdownButtonFormField<String>(
                  initialValue: enteredValue,
                  decoration: const InputDecoration(labelText: 'Đánh giá *'),
                  items: const [
                    DropdownMenuItem(value: '10.0', child: Text('Đạt')),
                    DropdownMenuItem(value: '0.0', child: Text('Không đạt')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => enteredValue = v ?? '10.0'),
                )
              else
                TextField(
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Điểm mới (0.0 – 10.0) *',
                    hintText: 'Ví dụ: 8.5',
                    errorText: error,
                  ),
                  onChanged: (v) => enteredValue = v,
                ),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        draft.newExempt = false;
        draft.newValue = result;
        controllers[cell.id]!.text = result;
      });
    }
  }

  Future<void> _submitAdjustmentRequest() async {
    final changedDrafts = _getChangedDrafts();
    if (changedDrafts.isEmpty) {
      showMessage('Chưa có ô nào thay đổi.');
      return;
    }
    if (changedDrafts.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Phiếu chỉ cho phép tối đa 100 ô (hiện tại có ${changedDrafts.length} ô). Vui lòng hoàn tác bớt ô trước khi gửi.',
          ),
        ),
      );
      return;
    }

    for (final item in changedDrafts) {
      if (!item.draft.newExempt) {
        final val = item.draft.newValue;
        if (val == null || val.isEmpty) {
          showMessage('Không được để trống ô điểm điều chỉnh.');
          return;
        }
        if (item.cell.passFail != true && validateGrade(val) != null) {
          showMessage('Điểm ô ${item.cell.studentName} không hợp lệ.');
          return;
        }
      }
    }

    final submitData = await showAppDialog<
        ({String reason, List<AdjustmentChangeInput> changes})>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AdjustmentSubmitDialog(
        changedDrafts: changedDrafts,
      ),
    );

    if (submitData == null || !mounted) return;

    setState(() => busy = true);
    try {
      await ref.read(adjustmentsRepositoryProvider).submitAdjustment(
            bookId: widget.data.book.id,
            expectedVersion: widget.data.book.version,
            reason: submitData.reason,
            changes: submitData.changes,
          );
      if (!mounted) return;
      setState(() {
        busy = false;
        adjustmentMode = false;
        _adjustmentDraft.clear();
      });
      showMessage('Đã gửi yêu cầu điều chỉnh điểm thành công.');
      widget.onReload();
    } catch (e) {
      if (!mounted) return;
      setState(() => busy = false);
      showMessage(adjustmentErrorMessage(e));
    }
  }

  Future<void> _cancelPendingAdjustment(AdjustmentDto adj) async {
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

    setState(() => busy = true);
    try {
      await ref.read(adjustmentsRepositoryProvider).cancel(
            adjId: adj.id,
            expectedVersion: adj.version,
          );
      if (!mounted) return;
      setState(() => busy = false);
      showMessage('Đã hủy phiếu điều chỉnh thành công.');
      widget.onReload();
    } catch (e) {
      if (!mounted) return;
      setState(() => busy = false);
      showMessage(adjustmentErrorMessage(e));
    }
  }

  void _openPendingDetail() async {
    final adjId = widget.data.book.pendingAdjustmentId;
    if (adjId == null) return;
    final user = ref.read(sessionProvider);
    final isSubmitter = _pendingAdjustment?.submittedBy.id == user?.id;

    final updated = await showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdjustmentDetailDialog(
        adjId: adjId,
        initialAdjustment: _pendingAdjustment,
        allowDecide: admin,
        allowCancel: isSubmitter && teacher,
      ),
    );
    if (updated == true) {
      widget.onReload();
    }
  }

  Widget _buildAdjustmentCell(GradeCellDto cell, {double width = 170}) {
    final t = context.tokens;
    final draft = _getOrCreateDraft(cell);
    final isExempt = draft.newExempt;
    final isChanged = draft.isChanged;
    final note = draft.note;

    final oldDisplay = cell.status.value == 'MIEN'
        ? 'Miễn'
        : (cell.passFail == true
            ? (cell.value == '10.0'
                ? 'Đạt'
                : (cell.value == '0.0' ? 'Không đạt' : '—'))
            : (cell.value ?? '—'));

    final newDisplay = draft.newExempt
        ? 'Miễn'
        : (cell.passFail == true
            ? (draft.newValue == '10.0'
                ? 'Đạt'
                : (draft.newValue == '0.0' ? 'Không đạt' : '—'))
            : (draft.newValue ?? '—'));

    final menuButton = PopupMenuButton<String>(
      key: ValueKey('adjustment-cell-menu-${cell.id}'),
      icon: Icon(Icons.more_vert, size: 16, color: isChanged ? t.priLink : t.ink3),
      padding: EdgeInsets.zero,
      tooltip: 'Thao tác ô điều chỉnh',
      onSelected: (val) {
        switch (val) {
          case 'exempt':
            setState(() {
              draft.newExempt = true;
              draft.newValue = null;
            });
            break;
          case 'unexempt':
            _showUnexemptDialog(cell);
            break;
          case 'note':
            _showCellNoteDialog(cell);
            break;
          case 'revert':
            _revertCellDraft(cell);
            break;
        }
      },
      itemBuilder: (ctx) => [
        if (!isExempt)
          const PopupMenuItem(
            value: 'exempt',
            child: Text('Đặt Miễn'),
          ),
        if (isExempt)
          const PopupMenuItem(
            value: 'unexempt',
            child: Text('Bỏ Miễn'),
          ),
        const PopupMenuItem(
          value: 'note',
          child: Text('Ghi chú…'),
        ),
        if (isChanged)
          const PopupMenuItem(
            value: 'revert',
            child: Text('Hoàn tác ô này'),
          ),
      ],
    );

    if (isExempt) {
      return SizedBox(
        width: width,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isChanged ? t.accSoft : t.subtle,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: isChanged ? t.warnLine : t.line),
          ),
          child: Row(
            children: [
              if (note != null && note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Tooltip(
                    message: note,
                    child: Icon(Icons.sticky_note_2_outlined,
                        size: 14, color: t.priLink),
                  ),
                ),
              Expanded(
                child: Text(
                  isChanged ? '$oldDisplay → Miễn' : 'Miễn',
                  key: ValueKey('grade-exempt-${cell.id}'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isChanged ? t.priLink : t.ink2,
                    fontSize: 13,
                  ),
                ),
              ),
              menuButton,
            ],
          ),
        ),
      );
    }

    if (cell.passFail == true) {
      return SizedBox(
        width: width,
        child: Container(
          decoration: isChanged
              ? BoxDecoration(
                  color: t.accSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: t.warnLine),
                )
              : null,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isChanged)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Text(
                          '$oldDisplay → $newDisplay',
                          style: TextStyle(
                            color: t.priLink,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    AppSelectField<String>(
                      key: ValueKey('grade-pf-${cell.id}'),
                      value: draft.newValue ?? '10.0',
                      label: 'Đánh giá',
                      dense: true,
                      searchable: false,
                      items: const [
                        DropdownMenuItem(value: '10.0', child: Text('Đạt')),
                        DropdownMenuItem(value: '0.0', child: Text('Không đạt')),
                      ],
                      onChanged: (v) {
                        if (v != null && v != 'EMPTY') {
                          setState(() {
                            draft.newExempt = false;
                            draft.newValue = v;
                            controllers[cell.id]!.text = v;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (note != null && note.isNotEmpty)
                Tooltip(
                  message: note,
                  child: Icon(Icons.sticky_note_2_outlined,
                      size: 14, color: t.priLink),
                ),
              menuButton,
            ],
          ),
        ),
      );
    }

    final currentText = controllers[cell.id]!.text.trim();
    final invalidGrade = currentText.isEmpty || validateGrade(currentText) != null;
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              key: ValueKey('grade-${cell.id}'),
              controller: controllers[cell.id],
              enabled: true,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              onChanged: (val) {
                final v = val.trim();
                draft.newExempt = false;
                draft.newValue = v.isEmpty ? null : v;
                setState(() {});
              },
              decoration: _gradeDecoration(
                enabled: true,
                invalid: invalidGrade,
                changed: isChanged,
                hintText: '0.0–10.0',
                helperText: isChanged
                    ? '$oldDisplay → ${currentText.isEmpty ? "—" : currentText}'
                    : (currentText.isEmpty ? 'Không được để trống' : null),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (note != null && note.isNotEmpty)
                      Tooltip(
                        message: note,
                        child: Icon(Icons.sticky_note_2_outlined,
                            size: 14, color: t.priLink),
                      ),
                    menuButton,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentsHistorySection() {
    final t = context.tokens;
    final theme = Theme.of(context);
    final items = _adjustmentsHistory ?? const [];

    return Card(
      key: const ValueKey('gradebook-adjustments-history-card'),
      child: Padding(
        padding: AppSpacing.cardBody,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.priSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.history_edu_outlined, color: t.priLink),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lịch sử điều chỉnh',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Các phiếu đề xuất điều chỉnh điểm sau khi chốt',
                        style:
                            theme.textTheme.bodySmall?.copyWith(color: t.ink2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Chưa có phiếu điều chỉnh nào cho bảng điểm này.',
                    style: TextStyle(color: t.ink2, fontSize: 13),
                  ),
                ),
              )
            else
              for (final adj in items) ...[
                InkWell(
                  key: ValueKey('adjustment-history-item-${adj.id}'),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  onTap: () {
                    final user = ref.read(sessionProvider);
                    final isSubmitter = adj.submittedBy.id == user?.id;
                    showAppDialog<bool>(
                      context: context,
                      builder: (ctx) => AdjustmentDetailDialog(
                        adjId: adj.id,
                        initialAdjustment: adj,
                        allowDecide: admin,
                        allowCancel: isSubmitter && teacher,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: t.line),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Phiếu #${adj.id}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: t.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  adjustmentStatusBadge(adj.status),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Người gửi: ${adj.submittedBy.name} • ${formatAdjustmentDateTime(adj.submittedAt)} • ${adj.lineCount} ô',
                                style:
                                    TextStyle(color: t.ink2, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 20, color: t.ink3),
                      ],
                    ),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _AdjustmentDraftCell {
  _AdjustmentDraftCell({
    required this.originalValue,
    required this.originalExempt,
    this.newValue,
    this.newExempt = false,
  });

  final String? originalValue;
  final bool originalExempt;
  String? newValue;
  bool newExempt;
  String? note;

  bool get isChanged {
    if (newExempt != originalExempt) return true;
    if (!newExempt) {
      return newValue != originalValue;
    }
    return false;
  }
}

class _AdjustmentSubmitDialog extends StatefulWidget {
  const _AdjustmentSubmitDialog({
    required this.changedDrafts,
  });

  final List<({GradeCellDto cell, _AdjustmentDraftCell draft})> changedDrafts;

  @override
  State<_AdjustmentSubmitDialog> createState() =>
      _AdjustmentSubmitDialogState();
}

class _AdjustmentSubmitDialogState extends State<_AdjustmentSubmitDialog> {
  final _reasonController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppDialog(
      title: 'Gửi yêu cầu điều chỉnh điểm',
      maxWidth: 720,
      confirmLabel: 'Gửi yêu cầu',
      cancelLabel: 'Hủy',
      onConfirm: () {
        final reason = _reasonController.text.trim();
        if (reason.isEmpty) {
          setState(() => _error = 'Cần nhập lý do điều chỉnh.');
          return;
        }
        final changes = widget.changedDrafts.map((item) {
          return AdjustmentChangeInput(
            cellId: item.cell.id,
            value: item.draft.newExempt ? null : item.draft.newValue,
            exempt: item.draft.newExempt,
            note: item.draft.note,
          );
        }).toList();

        Navigator.pop(
          context,
          (reason: reason, changes: changes),
        );
      },
      onCancel: () => Navigator.pop(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _reasonController,
            key: const ValueKey('adjustment-reason-input'),
            autofocus: true,
            maxLength: 500,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Lý do điều chỉnh (bắt buộc) *',
              hintText: 'Nhập lý do gửi phiếu điều chỉnh điểm...',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tóm tắt các ô thay đổi (${widget.changedDrafts.length} ô):',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: t.ink,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 260),
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
                      DataColumn(label: Text('Cột')),
                      DataColumn(label: Text('Cũ → Mới')),
                      DataColumn(label: Text('Ghi chú')),
                    ],
                    rows: widget.changedDrafts.map((item) {
                      final cell = item.cell;
                      final draft = item.draft;
                      final oldStr = cell.status.value == 'MIEN'
                          ? 'Miễn'
                          : (cell.passFail == true
                              ? (cell.value == '10.0'
                                  ? 'Đạt'
                                  : (cell.value == '0.0' ? 'Không đạt' : '—'))
                              : (cell.value ?? '—'));
                      final newStr = draft.newExempt
                          ? 'Miễn'
                          : (cell.passFail == true
                              ? (draft.newValue == '10.0'
                                  ? 'Đạt'
                                  : 'Không đạt')
                              : (draft.newValue ?? '—'));
                      return DataRow(
                        cells: [
                          DataCell(Text(cell.studentName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: t.ink,
                              ))),
                          DataCell(Text(cell.componentName)),
                          DataCell(Text(
                            '$oldStr → $newStr',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: t.priLink,
                            ),
                          )),
                          DataCell(Text(draft.note ?? '—',
                              style: TextStyle(
                                color: t.ink2,
                                fontStyle: draft.note == null
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
        ],
      ),
    );
  }
}

class GradebookHistoryDialog extends ConsumerWidget {
  const GradebookHistoryDialog({super.key, required this.bookId});

  final num bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppDialog(
    title: 'Lịch sử cập nhật điểm',
    maxWidth: 680,
    showFooter: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 420,
          child: FutureBuilder<List<GradebookHistoryEntryDto>>(
            future: ref
                .read(gradebooksRepositoryProvider)
                .historyAll(bookId: bookId),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text(errorMessage(snapshot.error!)));
              }
              final items = snapshot.data!;
              if (items.isEmpty) {
                return const Center(
                  child: Text('Bảng điểm chưa có lịch sử thay đổi.'),
                );
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final timestamp = DateTime.tryParse(
                    item.timestamp,
                  )?.toLocal();
                  return ListTile(
                    title: Text('${item.studentName} · ${item.componentName}'),
                    subtitle: Text(
                      '${item.oldValue ?? 'NULL'} → ${item.newValue ?? 'NULL'}'
                      '\n${item.reason}\nNgười sửa #${item.editor}'
                      '${timestamp == null ? '' : ' · $timestamp'}',
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ),
      ],
    ),
  );
}

class _GradebookLoadError extends StatelessWidget {
  const _GradebookLoadError({required this.error, required this.retry});

  final Object error;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(errorMessage(error)),
        const SizedBox(height: 12),
        FilledButton(onPressed: retry, child: const Text('Thử lại')),
      ],
    ),
  );
}

/// Độ rộng các cột của lưới nhập điểm màn rộng. Phần dư của khung (sau khi trừ
/// lề) được chia cho cột "Học sinh" (gấp đôi) và các cột điểm/tổng kết; cột STT
/// giữ hẹp. Khi nhiều cột không còn phần dư, giữ độ rộng gốc và cuộn ngang.
class _GridColumnSizes {
  const _GridColumnSizes({
    required this.student,
    required this.component,
    required this.total,
    required this.classification,
  });

  static const horizontalMargin = 16.0;
  static const columnSpacing = 20.0;
  static const stt = 40.0;
  static const _baseStudent = 190.0;
  static const _baseComponent = 170.0;
  static const _baseTotal = 110.0;
  static const _baseClassification = 100.0;
  static const _maxField = 190.0;

  final double student;
  final double component;
  final double total;
  final double classification;

  /// Ô nhập giữ vừa phải (dưới 200) để nhãn "● AI" vẫn hiện cạnh ô.
  double get field => component < _maxField ? component : _maxField;

  factory _GridColumnSizes.fit({
    required double available,
    required int components,
    required bool withResults,
  }) {
    final columns = 2 + components + (withResults ? 2 : 0);
    final natural =
        horizontalMargin * 2 +
        columnSpacing * (columns - 1) +
        stt +
        _baseStudent +
        _baseComponent * components +
        (withResults ? _baseTotal + _baseClassification : 0);
    // Trừ 1 px dự phòng sai số làm tròn để không sinh thanh cuộn ngang thừa.
    final extra = available - natural - 1;
    final weights = 2 + components + (withResults ? 2 : 0);
    final unit = extra > 0 ? extra / weights : 0.0;
    return _GridColumnSizes(
      student: _baseStudent + 2 * unit,
      component: _baseComponent + unit,
      total: _baseTotal + unit,
      classification: _baseClassification + unit,
    );
  }
}
