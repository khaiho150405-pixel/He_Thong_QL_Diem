import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_dialog.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../app/widgets/app_select_field.dart';
import '../../app/widgets/empty_state.dart';
import '../authentication/session.dart';
import 'semester_deadlines_repository.dart';

class _PromotionRowState {
  _PromotionRowState({
    required this.studentId,
    required this.studentName,
    required this.order,
    required this.action,
    required this.targetClassId,
    required this.alreadyEnrolled,
    required this.processedStatus,
    required this.targetClassName,
  });

  final num studentId;
  final String studentName;
  final num order;
  PromotionItemInputActionEnum action;
  num? targetClassId;
  String? reason;
  final bool alreadyEnrolled;
  final PromotionPreviewItemDtoProcessedStatusEnum? processedStatus;
  final String? targetClassName;

  bool get isProcessed => processedStatus != null;
  bool get isActionable => !isProcessed && !alreadyEnrolled;

  String? get processedLabel {
    if (processedStatus == null) return null;
    return switch (processedStatus!) {
      PromotionPreviewItemDtoProcessedStatusEnum.LEN_LOP =>
        targetClassName != null && targetClassName!.isNotEmpty
            ? 'Đã lên lớp → $targetClassName'
            : 'Đã lên lớp',
      PromotionPreviewItemDtoProcessedStatusEnum.LUU_BAN =>
        targetClassName != null && targetClassName!.isNotEmpty
            ? 'Đã lưu ban → $targetClassName'
            : 'Đã lưu ban',
      PromotionPreviewItemDtoProcessedStatusEnum.TOT_NGHIEP => 'Đã tốt nghiệp',
      PromotionPreviewItemDtoProcessedStatusEnum.NGHI_HOC => 'Đã nghỉ học',
      PromotionPreviewItemDtoProcessedStatusEnum.DA_CHUYEN_LOP => 'Đã chuyển lớp',
    };
  }
}

class PromotionScreen extends ConsumerStatefulWidget {
  const PromotionScreen({super.key, required this.classId});

  final num classId;

  @override
  ConsumerState<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends ConsumerState<PromotionScreen> {
  num? _selectedTargetYearId;
  num? _quickApplyClassId;

  List<YearsDto> _availableYears = [];
  bool _loadingYears = true;
  String? _yearsError;

  PromotionPreviewDto? _preview;
  bool _loadingPreview = false;
  String? _previewError;

  List<_PromotionRowState> _rows = [];
  num? _errorStudentId;
  bool _submitting = false;
  String? _submitError;
  PromotionResultDto? _submitResult;

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  Future<void> _loadYears() async {
    setState(() {
      _loadingYears = true;
      _yearsError = null;
    });

    try {
      final res = await ref.read(apiProvider).getYearsApi().yearsList();
      final items = res.data?.items ?? [];
      if (mounted) {
        setState(() {
          _availableYears = items;
          _loadingYears = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _yearsError = deadlineErrorMessage(e);
          _loadingYears = false;
        });
      }
    }
  }

  Future<void> _loadPreview(num targetYearId) async {
    setState(() {
      _selectedTargetYearId = targetYearId;
      _loadingPreview = true;
      _previewError = null;
      _preview = null;
      _rows = [];
      _errorStudentId = null;
      _submitError = null;
      _submitResult = null;
    });

    try {
      final res = await ref
          .read(apiProvider)
          .getEnrollmentsApi()
          .classPromotionPreview(
            targetYearId: targetYearId,
            id: widget.classId,
          );
      final preview = res.data!;
      final rows = preview.items.map((item) {
        final action = switch (item.suggestedAction) {
          PromotionPreviewItemDtoSuggestedActionEnum.LEN_LOP =>
            PromotionItemInputActionEnum.LEN_LOP,
          PromotionPreviewItemDtoSuggestedActionEnum.TOT_NGHIEP =>
            PromotionItemInputActionEnum.TOT_NGHIEP,
        };

        return _PromotionRowState(
          studentId: item.studentId,
          studentName: item.studentName,
          order: item.order,
          action: action,
          targetClassId: item.suggestedTargetClassId,
          alreadyEnrolled: item.alreadyEnrolledInTargetYear,
          processedStatus: item.processedStatus,
          targetClassName: item.targetClassName,
        );
      }).toList();

      // Mặc định quick apply class là lớp đầu tiên của khối +1 nếu có
      final nextGrade = preview.sourceClass.grade + 1;
      final nextGradeClasses = preview.targetClasses
          .where((c) => c.grade == nextGrade)
          .toList();
      final quickClass = nextGradeClasses.isNotEmpty ? nextGradeClasses.first.id : null;

      if (mounted) {
        setState(() {
          _preview = preview;
          _rows = rows;
          _quickApplyClassId = quickClass;
          _loadingPreview = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _previewError = deadlineErrorMessage(e);
          _loadingPreview = false;
        });
      }
    }
  }

  List<PromotionClassDto> _filteredTargetClasses(
    PromotionItemInputActionEnum action,
  ) {
    if (_preview == null) return [];
    final sourceGrade = _preview!.sourceClass.grade;
    if (action == PromotionItemInputActionEnum.LEN_LOP) {
      return _preview!.targetClasses
          .where((c) => c.grade == sourceGrade + 1)
          .toList();
    }
    if (action == PromotionItemInputActionEnum.LUU_BAN) {
      return _preview!.targetClasses
          .where((c) => c.grade == sourceGrade)
          .toList();
    }
    return [];
  }

  void _onActionChanged(_PromotionRowState row, PromotionItemInputActionEnum newAction) {
    setState(() {
      row.action = newAction;
      final eligibleClasses = _filteredTargetClasses(newAction);
      if (newAction == PromotionItemInputActionEnum.TOT_NGHIEP ||
          newAction == PromotionItemInputActionEnum.NGHI_HOC) {
        row.targetClassId = null;
      } else {
        if (!eligibleClasses.any((c) => c.id == row.targetClassId)) {
          row.targetClassId =
              eligibleClasses.isNotEmpty ? eligibleClasses.first.id : null;
        }
      }
    });
  }

  void _applyQuickPromotion() {
    if (_quickApplyClassId == null) return;
    setState(() {
      for (final r in _rows) {
        if (r.isActionable) {
          r.action = PromotionItemInputActionEnum.LEN_LOP;
          r.targetClassId = _quickApplyClassId;
        }
      }
    });
  }

  bool get _hasMissingTargetClass {
    return _rows.any((r) {
      if (!r.isActionable) return false;
      if (r.action == PromotionItemInputActionEnum.LEN_LOP ||
          r.action == PromotionItemInputActionEnum.LUU_BAN) {
        return r.targetClassId == null;
      }
      return false;
    });
  }

  Future<void> _confirmAndSubmit() async {
    if (_preview == null || _selectedTargetYearId == null) return;

    final activeRows = _rows.where((r) => r.isActionable).toList();
    if (activeRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có học sinh nào cần xử lý.')),
      );
      return;
    }

    final promotedCount = activeRows
        .where((r) => r.action == PromotionItemInputActionEnum.LEN_LOP)
        .length;
    final retainedCount = activeRows
        .where((r) => r.action == PromotionItemInputActionEnum.LUU_BAN)
        .length;
    final graduatedCount = activeRows
        .where((r) => r.action == PromotionItemInputActionEnum.TOT_NGHIEP)
        .length;
    final withdrawnCount = activeRows
        .where((r) => r.action == PromotionItemInputActionEnum.NGHI_HOC)
        .length;

    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) {
        final t = ctx.tokens;
        return AppDialog(
          title: 'Xác nhận lên lớp cuối năm',
          confirmLabel: 'Xác nhận thực hiện',
          cancelLabel: 'Hủy',
          maxWidth: 480,
          onConfirm: () => Navigator.of(ctx).pop(true),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tổng cộng ${activeRows.length} học sinh sẽ được xử lý sang năm học ${_preview!.targetYear.name}:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.ink,
                  ),
                ),
                const SizedBox(height: 12),
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
                      if (promotedCount > 0)
                        _summaryRow(
                          'Lên lớp',
                          '$promotedCount học sinh',
                          t.ok,
                        ),
                      if (retainedCount > 0)
                        _summaryRow(
                          'Lưu ban',
                          '$retainedCount học sinh',
                          t.warn,
                        ),
                      if (graduatedCount > 0)
                        _summaryRow(
                          'Tốt nghiệp',
                          '$graduatedCount học sinh',
                          t.priLink,
                        ),
                      if (withdrawnCount > 0)
                        _summaryRow(
                          'Nghỉ học',
                          '$withdrawnCount học sinh',
                          t.bad,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Lưu ý: Thao tác sẽ cập nhật trạng thái học sinh và ghi danh mới.',
                  style: TextStyle(fontSize: 12, color: t.ink3),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _submitting = true;
      _submitError = null;
      _errorStudentId = null;
    });

    try {
      final idempotencyKey =
          'promotion-${widget.classId}-${DateTime.now().microsecondsSinceEpoch}';
      final input = PromotionInput(
        targetYearId: _selectedTargetYearId!,
        items: activeRows.map((r) {
          return PromotionItemInput(
            studentId: r.studentId,
            action: r.action,
            targetClassId: r.targetClassId,
            reason: r.reason?.trim().isNotEmpty == true ? r.reason!.trim() : null,
          );
        }).toList(),
      );

      final res = await ref
          .read(apiProvider)
          .getEnrollmentsApi()
          .classPromotionPromote(
            xIdempotencyKey: idempotencyKey,
            id: widget.classId,
            promotionInput: input,
          );

      if (mounted) {
        setState(() {
          _submitting = false;
          _submitResult = res.data;
        });
      }
    } catch (e) {
      if (mounted) {
        final details = apiErrorDetails(e);
        num? errId;
        if (details != null && details['studentId'] is num) {
          errId = details['studentId'] as num;
        }

        setState(() {
          _submitting = false;
          _submitError = deadlineErrorMessage(e);
          _errorStudentId = errId;
        });
      }
    }
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    final title = _preview != null
        ? 'Lên lớp cuối năm: ${_preview!.sourceClass.name} (${_preview!.sourceClass.yearName})'
        : 'Lên lớp cuối năm';

    return AppScaffold(
      title: title,
      currentPath: '/admin/classes/${widget.classId}/promotion',
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/catalog/classes');
        }
      },
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildYearSelectorCard(t),
            const SizedBox(height: 16),
            if (_loadingPreview) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (_previewError != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: t.badSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: t.badLine),
                ),
                child: Text(
                  _previewError!,
                  style: TextStyle(color: t.bad, fontWeight: FontWeight.w500),
                ),
              ),
            ] else if (_submitResult != null) ...[
              _buildSuccessCard(t),
            ] else if (_preview != null) ...[
              if (_submitError != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: t.badSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: t.badLine),
                  ),
                  child: Text(
                    _submitError!,
                    style: TextStyle(color: t.bad, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_rows.isNotEmpty && _rows.every((r) => !r.isActionable)) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: t.priSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: t.priLine),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: t.priLink),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tất cả học sinh của lớp đã được xử lý cho năm ${_preview!.targetYear.name}',
                          style: TextStyle(
                            color: t.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildQuickApplyBar(t),
              const SizedBox(height: 16),
              _buildPromotionTable(t, theme),
              const SizedBox(height: 20),
              _buildSubmitBar(t),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildYearSelectorCard(AppTokens t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn năm học đích để lên lớp',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingYears)
            const LinearProgressIndicator()
          else if (_yearsError != null)
            Text(_yearsError!, style: TextStyle(color: t.bad))
          else
            AppSelectField<num>(
              key: const ValueKey('promotion-target-year-select'),
              value: _selectedTargetYearId,
              label: 'Năm học đích *',
              items: _availableYears
                  .map(
                    (y) => DropdownMenuItem<num>(
                      value: y.maNamHoc,
                      child: Text(
                        y.hienHanh ? '${y.ten} (Hiện hành)' : y.ten,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _submitting ? null : (v) => v != null ? _loadPreview(v) : null,
            ),
        ],
      ),
    );
  }

  Widget _buildQuickApplyBar(AppTokens t) {
    final nextGrade = _preview!.sourceClass.grade + 1;
    final nextGradeClasses = _preview!.targetClasses
        .where((c) => c.grade == nextGrade)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.priSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.priLine),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, size: 20, color: t.priLink),
              const SizedBox(width: 6),
              Text(
                'Áp dụng nhanh cho tất cả:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: t.priLink,
                ),
              ),
            ],
          ),
          if (nextGradeClasses.isNotEmpty) ...[
            SizedBox(
              width: 220,
              child: AppSelectField<num>(
                key: const ValueKey('promotion-quick-class-select'),
                value: _quickApplyClassId,
                label: 'Lên lớp →',
                searchable: true,
                hintText: '(Chọn lớp)',
                items: nextGradeClasses
                    .map(
                      (c) => DropdownMenuItem<num>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _quickApplyClassId = v),
              ),
            ),
            FilledButton.tonal(
              key: const ValueKey('promotion-quick-apply-btn'),
              onPressed: _applyQuickPromotion,
              child: const Text('Áp dụng'),
            ),
          ] else ...[
            Text(
              'Không có lớp khối $nextGrade trong năm học đích',
              style: TextStyle(fontSize: 12, color: t.ink3),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPromotionTable(AppTokens t, ThemeData theme) {
    if (_rows.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'Lớp trống',
        message: 'Lớp không có học sinh nào.',
      );
    }

    final isGrade12 = _preview!.sourceClass.grade == 12;

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const totalColumns = 5;
            final hMargin = constraints.maxWidth >= 768 ? AppSpacing.xl : AppSpacing.md;
            const colSpacing = 16.0;
            final availableTotalWidth =
                constraints.maxWidth - (hMargin * 2) - ((totalColumns - 1) * colSpacing);

            const minOrder = 50.0;
            const minName = 160.0;
            const minAction = 140.0;
            const minTarget = 140.0;
            const minReason = 160.0;
            const minRequired = minOrder + minName + minAction + minTarget + minReason;

            final double colOrder;
            final double colName;
            final double colAction;
            final double colTarget;
            final double colReason;

            if (availableTotalWidth > minRequired) {
              final extra = availableTotalWidth - minRequired;
              colOrder = minOrder;
              colName = minName + extra * 0.28;
              colAction = minAction + extra * 0.24;
              colTarget = minTarget + extra * 0.24;
              colReason = minReason + extra * 0.24;
            } else {
              colOrder = minOrder;
              colName = minName;
              colAction = minAction;
              colTarget = minTarget;
              colReason = minReason;
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(t.subtle),
                  columnSpacing: colSpacing,
                  horizontalMargin: hMargin,
                  dataRowMinHeight: 64,
                  dataRowMaxHeight: 76,
                  columns: [
                    DataColumn(
                      label: SizedBox(
                        width: colOrder,
                        child: const Text('STT', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: colName,
                        child: const Text('Họ tên', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: colAction,
                        child: const Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: colTarget,
                        child: const Text('Lớp đích', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: colReason,
                        child: const Text('Lý do (Lưu ban / Nghỉ)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                  rows: [
                    for (final row in _rows)
                      _buildDataRow(
                        row,
                        t,
                        isGrade12,
                        colOrder,
                        colName,
                        colAction,
                        colTarget,
                        colReason,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  DataRow _buildDataRow(
    _PromotionRowState row,
    AppTokens t,
    bool isGrade12,
    double colOrder,
    double colName,
    double colAction,
    double colTarget,
    double colReason,
  ) {
    final isError = _errorStudentId == row.studentId;
    final isDimmed = !row.isActionable;
    final rowColor = isError
        ? t.badSoft
        : (isDimmed
            ? t.subtle.withValues(alpha: 0.5)
            : Colors.transparent);

    final eligibleTargetClasses = _filteredTargetClasses(row.action);

    return DataRow(
      key: ValueKey('promotion-row-${row.studentId}'),
      color: WidgetStateProperty.all(rowColor),
      cells: [
        DataCell(
          SizedBox(
            width: colOrder,
            child: Text(
              '#${row.order}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDimmed ? t.ink3 : t.ink,
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: colName,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.studentName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDimmed ? t.ink3 : t.ink,
                  ),
                ),
                if (row.processedLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: AppBadge(row.processedLabel!, tone: AppBadgeTone.neutral),
                  )
                else if (row.alreadyEnrolled)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: AppBadge('Đã có ghi danh', tone: AppBadgeTone.neutral),
                  )
                else if (isError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Lỗi dòng này',
                      style: TextStyle(
                        color: t.bad,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: colAction,
            child: isDimmed
                ? Text('—', style: TextStyle(color: t.ink3))
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: colAction.clamp(140.0, 240.0),
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: t.line),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PromotionItemInputActionEnum>(
                          key: ValueKey('promotion-action-${row.studentId}'),
                          isExpanded: true,
                          value: row.action,
                          items: [
                            const DropdownMenuItem(
                              value: PromotionItemInputActionEnum.LEN_LOP,
                              child: Text('Lên lớp'),
                            ),
                            const DropdownMenuItem(
                              value: PromotionItemInputActionEnum.LUU_BAN,
                              child: Text('Lưu ban'),
                            ),
                            if (isGrade12)
                              const DropdownMenuItem(
                                value: PromotionItemInputActionEnum.TOT_NGHIEP,
                                child: Text('Tốt nghiệp'),
                              ),
                            const DropdownMenuItem(
                              value: PromotionItemInputActionEnum.NGHI_HOC,
                              child: Text('Nghỉ học'),
                            ),
                          ],
                          onChanged: (v) =>
                              v != null ? _onActionChanged(row, v) : null,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        DataCell(
          SizedBox(
            width: colTarget,
            child: isDimmed
                ? Text('—', style: TextStyle(color: t.ink3))
                : (row.action == PromotionItemInputActionEnum.TOT_NGHIEP ||
                        row.action == PromotionItemInputActionEnum.NGHI_HOC)
                    ? Text('—', style: TextStyle(color: t.ink3))
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: colTarget.clamp(140.0, 240.0),
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: row.targetClassId == null ? t.bad : t.line,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<num>(
                              key: ValueKey(
                                'promotion-target-class-${row.studentId}',
                              ),
                              isExpanded: true,
                              value: eligibleTargetClasses.any(
                                    (c) => c.id == row.targetClassId,
                                  )
                                  ? row.targetClassId
                                  : null,
                              hint: const Text('Chọn lớp...'),
                              items: eligibleTargetClasses
                                  .map(
                                    (c) => DropdownMenuItem<num>(
                                      value: c.id,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => row.targetClassId = v),
                            ),
                          ),
                        ),
                      ),
          ),
        ),
        DataCell(
          SizedBox(
            width: colReason,
            child: isDimmed
                ? Text('—', style: TextStyle(color: t.ink3))
                : (row.action == PromotionItemInputActionEnum.LUU_BAN ||
                        row.action == PromotionItemInputActionEnum.NGHI_HOC)
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: colReason.clamp(160.0, 320.0),
                          child: TextFormField(
                            initialValue: row.reason,
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: 'Lý do (tùy chọn)',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => row.reason = v,
                          ),
                        ),
                      )
                    : Text('—', style: TextStyle(color: t.ink3)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitBar(AppTokens t) {
    final activeCount = _rows.where((r) => r.isActionable).length;
    final canSubmit =
        !_submitting && activeCount > 0 && !_hasMissingTargetClass;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Số học sinh sẽ thực hiện: $activeCount',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: t.ink,
                ),
              ),
              if (_hasMissingTargetClass)
                Text(
                  'Còn học sinh lên lớp/lưu ban chưa chọn lớp đích',
                  style: TextStyle(
                    color: t.bad,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          FilledButton.icon(
            key: const ValueKey('promotion-submit-btn'),
            onPressed: canSubmit ? _confirmAndSubmit : null,
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_outline),
            label: const Text('Thực hiện lên lớp'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(AppTokens t) {
    final res = _submitResult!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.okLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 56, color: t.ok),
          const SizedBox(height: 16),
          Text(
            'Lên lớp cuối năm thành công!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Đã xử lý tổng cộng ${res.processed} học sinh',
            style: TextStyle(fontSize: 14, color: t.ink2),
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.subtle,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: t.line),
            ),
            child: Column(
              children: [
                _summaryRow('Lên lớp', '${res.promoted}', t.ok),
                _summaryRow('Lưu ban', '${res.retained}', t.warn),
                _summaryRow('Tốt nghiệp', '${res.graduated}', t.priLink),
                _summaryRow('Nghỉ học', '${res.withdrawn}', t.bad),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/catalog/classes');
              }
            },
            child: const Text('Quay lại danh sách lớp'),
          ),
        ],
      ),
    );
  }
}
