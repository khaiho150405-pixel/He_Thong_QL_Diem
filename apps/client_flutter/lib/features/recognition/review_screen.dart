import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/widgets/app_scaffold.dart';
import '../authentication/session.dart';
import '../gradebooks/repository.dart';
import 'repository.dart';
import 'review/review_bottom_bar.dart';
import 'review/review_green_group.dart';
import 'review/review_header.dart';
import 'review/review_mobile_pager.dart';
import 'review/review_models.dart';
import 'review/review_row_card.dart';
import 'review/review_source_image.dart';

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
  final leavingEmpty = <String, bool>{};
  final agreedYellow = <String, bool>{};
  final sttConfirmed = <String, bool>{};
  final focusNodes = <String, FocusNode>{};

  late Future<RecognitionTicketDetailDto> detail;
  RecognitionTicketDetailDto? loaded;
  num? _gradebookVersion;
  String? _versionError;
  bool confirmed = false;
  bool busy = false;
  String _reviewLevelFilter = 'ALL'; // 'ALL' | 'DO' | 'VANG' | 'XANH'
  bool _mobileShowList = false;

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
        leavingEmpty[row.rowId] = false;
        agreedYellow[row.rowId] = false;
        sttConfirmed[row.rowId] = false;
        focusNodes[row.rowId] = FocusNode();
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
    switch (row.suggestedSource) {
      case RecognitionEvidenceRowDtoSuggestedSourceEnum.SO:
        return row.numericValue;
      case RecognitionEvidenceRowDtoSuggestedSourceEnum.CHU:
        return row.writtenValue;
      case null:
        break;
    }
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
    for (final node in focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  bool _hasSttDiff(RecognitionEvidenceRowDto r) =>
      r.sttOnPaper != null && r.stt != null && r.sttOnPaper!.toInt() != r.stt;

  bool _isSttWarning(RecognitionEvidenceRowDto r) =>
      _hasSttDiff(r) && r.matchLevel?.value != 'XANH';

  bool _isSttInfo(RecognitionEvidenceRowDto r) =>
      _hasSttDiff(r) && r.matchLevel?.value == 'XANH';

  bool _isRowRedHandled(RecognitionEvidenceRowDto row) {
    return isRedRowHandled(
      value: values[row.rowId]?.text,
      reason: reasons[row.rowId]?.text,
      leavingEmpty: leavingEmpty[row.rowId] ?? false,
    );
  }

  bool _isRowYellowHandled(RecognitionEvidenceRowDto row) {
    return isYellowRowHandled(
      value: values[row.rowId]?.text,
      reason: reasons[row.rowId]?.text,
      suggestedValue: _suggested(row),
      agreedYellow: agreedYellow[row.rowId] ?? false,
      leavingEmpty: leavingEmpty[row.rowId] ?? false,
    );
  }

  bool _isRowHandled(RecognitionEvidenceRowDto row) {
    // Nếu là cảnh báo STT, bắt buộc phải tích "Đúng học sinh này"
    if (_isSttWarning(row) && (sttConfirmed[row.rowId] != true)) {
      return false;
    }
    if (row.reviewLevel.value == 'DO') return _isRowRedHandled(row);
    if (row.reviewLevel.value == 'VANG') return _isRowYellowHandled(row);
    if (_isSttInfo(row)) return true;
    return true;
  }

  void _onSttConfirmedChanged(String rowId, bool isConfirmed) {
    setState(() {
      sttConfirmed[rowId] = isConfirmed;
    });
  }

  void _onGradeChanged(String rowId, String text) {
    setState(() {
      if (isValidGrade(text)) {
        reasons[rowId]?.text = 'Đã đối chiếu ảnh nhận dạng';
        leavingEmpty[rowId] = false;
      }
    });
  }

  void _onLeaveEmpty(String rowId) {
    setState(() {
      values[rowId]?.text = '';
      reasons[rowId]?.text = '';
      leavingEmpty[rowId] = true;
    });
  }

  void _onCancelLeaveEmpty(String rowId, RecognitionEvidenceRowDto row) {
    setState(() {
      leavingEmpty[rowId] = false;
      final suggested = _suggested(row);
      if (suggested != null) {
        values[rowId]?.text = suggested;
        reasons[rowId]?.text = 'Đã đối chiếu ảnh nhận dạng';
      }
    });
  }

  void _onAgreeYellow(String rowId) {
    setState(() {
      agreedYellow[rowId] = true;
    });
  }

  void _focusNextNeedReview(
    String currentRowId,
    List<RecognitionEvidenceRowDto> needReviewRows,
  ) {
    final index = needReviewRows.indexWhere((r) => r.rowId == currentRowId);
    if (index >= 0 && index + 1 < needReviewRows.length) {
      final nextId = needReviewRows[index + 1].rowId;
      focusNodes[nextId]?.requestFocus();
    }
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

    final redRows = data.rows.where((r) => r.reviewLevel.value == 'DO');
    if (!redRows.every(_isRowRedHandled)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng xử lý tất cả các dòng Đỏ (nhập điểm hoặc để trống có lý do) trước khi duyệt.',
          ),
        ),
      );
      return;
    }

    final sttWarningRows = data.rows.where(_isSttWarning);
    if (!sttWarningRows.every((r) => sttConfirmed[r.rowId] == true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng xác nhận đúng học sinh cho các dòng có cảnh báo STT trước khi duyệt.',
          ),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isMobile = screenWidth < 600;

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

            // Sắp xếp thứ tự: Đỏ -> Vàng -> Xanh, sau đó theo STT
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

            final needReviewRows = orderedRows
                .where(
                  (r) =>
                      r.reviewLevel.value == 'DO' ||
                      r.reviewLevel.value == 'VANG' ||
                      _hasSttDiff(r),
                )
                .toList();
            final greenRows = orderedRows
                .where((r) => r.reviewLevel.value == 'XANH' && !_hasSttDiff(r))
                .toList();

            final totalNeedReview = needReviewRows.length;
            final reviewedCount = needReviewRows
                .where((r) => _isRowHandled(r))
                .length;
            final allRedHandled = orderedRows
                .where((r) => r.reviewLevel.value == 'DO')
                .every((r) => _isRowRedHandled(r));
            final allSttWarningsConfirmed = orderedRows
                .where(_isSttWarning)
                .every((r) => sttConfirmed[r.rowId] == true);

            // Bộ lọc: danh sách các dòng cần hiển thị
            final filteredNeedReviewRows = needReviewRows.where((r) {
              if (_reviewLevelFilter == 'ALL') return true;
              if (_reviewLevelFilter == 'STT_DIFF') return _hasSttDiff(r);
              return r.reviewLevel.value == _reviewLevelFilter;
            }).toList();

            final showGreenCollapsible =
                (_reviewLevelFilter == 'ALL' || _reviewLevelFilter == 'XANH') &&
                _reviewLevelFilter != 'STT_DIFF';

            return Form(
              key: formKey,
              child: Column(
                children: [
                  // Lỗi version nếu có
                  if (_versionError != null)
                    Container(
                      key: const ValueKey('review-version-error'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      color: colorScheme.errorContainer,
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: colorScheme.onErrorContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$_versionError. Chưa thể duyệt phiếu.',
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            key: const ValueKey('review-retry-version'),
                            onPressed: busy ? null : refreshEvidence,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Tải lại'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(48, 36),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Nội dung chính
                  Expanded(
                    child:
                        isMobile &&
                            !_mobileShowList &&
                            totalNeedReview > 0 &&
                            canApprove
                        ? ReviewMobilePager(
                            needReviewRows: filteredNeedReviewRows,
                            greenRows: greenRows,
                            values: values,
                            reasons: reasons,
                            leavingEmpty: leavingEmpty,
                            agreedYellow: agreedYellow,
                            enabled: canApprove && !busy,
                            onGradeChanged: _onGradeChanged,
                            onReasonChanged: (rowId, text) => setState(() {}),
                            onLeaveEmpty: _onLeaveEmpty,
                            onCancelLeaveEmpty: (rowId) {
                              final row = needReviewRows.firstWhere(
                                (r) => r.rowId == rowId,
                              );
                              _onCancelLeaveEmpty(rowId, row);
                            },
                            onAgreeYellow: _onAgreeYellow,
                            onToggleMode: () =>
                                setState(() => _mobileShowList = true),
                            confirmed: confirmed,
                            onConfirmedChanged: (val) =>
                                setState(() => confirmed = val),
                            onApprove: approve,
                            totalRows: data.rows.length,
                            canApprove: canApprove,
                            allRedHandled: allRedHandled,
                            hasGradebookVersion: _gradebookVersion != null,
                            busy: busy,
                            onRefresh: refreshEvidence,
                            readOnly: !canApprove,
                            sttConfirmed: sttConfirmed,
                            onSttConfirmedChanged: _onSttConfirmedChanged,
                            allSttWarningsConfirmed: allSttWarningsConfirmed,
                            ticket: data,
                            currentFilter: _reviewLevelFilter,
                            onFilterChanged: (filter) =>
                                setState(() => _reviewLevelFilter = filter),
                            totalNeedReview: totalNeedReview,
                            reviewedCount: reviewedCount,
                          )
                        : _buildStandardListLayout(
                            context: context,
                            ticket: data,
                            needReviewRows: filteredNeedReviewRows,
                            allNeedReviewRows: needReviewRows,
                            greenRows: greenRows,
                            totalNeedReview: totalNeedReview,
                            reviewedCount: reviewedCount,
                            canApprove: canApprove,
                            allRedHandled: allRedHandled,
                            isDesktop: isDesktop,
                            isTablet: isTablet,
                            isMobile: isMobile,
                            showGreenCollapsible: showGreenCollapsible,
                          ),
                  ),

                  // Sticky bottom bar khi ở chế độ danh sách
                  if (!isMobile || _mobileShowList || totalNeedReview == 0)
                    ReviewBottomBar(
                      confirmed: confirmed,
                      onConfirmedChanged: (val) =>
                          setState(() => confirmed = val),
                      onApprove: approve,
                      totalRows: data.rows.length,
                      canApprove: canApprove,
                      allRedHandled: allRedHandled,
                      allSttWarningsConfirmed: allSttWarningsConfirmed,
                      hasGradebookVersion: _gradebookVersion != null,
                      busy: busy,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStandardListLayout({
    required BuildContext context,
    required RecognitionTicketDetailDto ticket,
    required List<RecognitionEvidenceRowDto> needReviewRows,
    required List<RecognitionEvidenceRowDto> allNeedReviewRows,
    required List<RecognitionEvidenceRowDto> greenRows,
    required int totalNeedReview,
    required int reviewedCount,
    required bool canApprove,
    required bool allRedHandled,
    required bool isDesktop,
    required bool isTablet,
    required bool isMobile,
    required bool showGreenCollapsible,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột chính (danh sách các dòng)
          Expanded(
            child: ListView(
              cacheExtent: 5000,
              children: [
                // Thanh tóm tắt dính đầu
                ReviewHeader(
                  ticket: ticket,
                  currentFilter: _reviewLevelFilter,
                  onFilterChanged: (filter) =>
                      setState(() => _reviewLevelFilter = filter),
                  totalNeedReview: totalNeedReview,
                  reviewedCount: reviewedCount,
                ),
                const SizedBox(height: 12),

                // Banner trạng thái khi phiếu không ở trạng thái CHO_DOI_CHIEU
                if (!canApprove)
                  _buildStatusBanner(context, ticket.status.value),

                // Nút chuyển lại PageView trên mobile nếu có dòng cần xem
                if (isMobile && totalNeedReview > 0 && canApprove) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _mobileShowList = false),
                      icon: const Icon(Icons.view_carousel_rounded, size: 18),
                      label: const Text('Xem từng dòng (trượt)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Ảnh gốc ở đầu trang khi ở Tablet hoặc Mobile List
                if (!isDesktop) ...[
                  ReviewSourceImage(ticket: ticket, onRefresh: refreshEvidence),
                  const SizedBox(height: 12),
                ],

                // Danh sách dòng Đỏ / Vàng
                for (final row in needReviewRows)
                  ReviewRowCard(
                    row: row,
                    valueController: values[row.rowId]!,
                    reasonController: reasons[row.rowId]!,
                    isLeavingEmpty: leavingEmpty[row.rowId] ?? false,
                    isAgreedYellow: agreedYellow[row.rowId] ?? false,
                    enabled: canApprove && !busy,
                    focusNode: focusNodes[row.rowId],
                    onFocusNext: () =>
                        _focusNextNeedReview(row.rowId, allNeedReviewRows),
                    onGradeChanged: (val) => _onGradeChanged(row.rowId, val),
                    onReasonChanged: (_) => setState(() {}),
                    onLeaveEmpty: () => _onLeaveEmpty(row.rowId),
                    onCancelLeaveEmpty: () =>
                        _onCancelLeaveEmpty(row.rowId, row),
                    onAgreeYellow: () => _onAgreeYellow(row.rowId),
                    onRefresh: refreshEvidence,
                    isDesktop: isDesktop,
                    readOnly: !canApprove,
                    isSttConfirmed: sttConfirmed[row.rowId] ?? false,
                    onSttConfirmedChanged: (val) =>
                        _onSttConfirmedChanged(row.rowId, val),
                  ),

                // Mục thu gọn dòng Xanh
                if (showGreenCollapsible)
                  ReviewGreenGroup(
                    rows: greenRows,
                    values: values,
                    enabled: canApprove && !busy,
                    onGradeChanged: _onGradeChanged,
                    initiallyExpanded:
                        _reviewLevelFilter == 'XANH' || totalNeedReview == 0,
                    readOnly: !canApprove,
                  ),
              ],
            ),
          ),

          // Cột phải dính cho ảnh gốc trên Web (≥1024px)
          if (isDesktop) ...[
            const SizedBox(width: 14),
            ReviewSourceImage(
              ticket: ticket,
              onRefresh: refreshEvidence,
              isColumn: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, String status) {
    final (
      icon,
      bgColor,
      borderColor,
      textColor,
      title,
      subtitle,
    ) = switch (status) {
      'DA_DUYET' => (
        Icons.verified_rounded,
        Colors.green.shade50,
        Colors.green.shade300,
        Colors.green.shade900,
        'Phiếu đã duyệt — chỉ xem',
        'Điểm số đã được ghi chính thức vào hệ thống.',
      ),
      'LOI' => (
        Icons.error_outline_rounded,
        Colors.red.shade50,
        Colors.red.shade300,
        Colors.red.shade900,
        'Phiếu xử lý thất bại — chỉ xem',
        'Đã xảy ra lỗi trong quá trình nhận dạng. Vui lòng kiểm tra lại ảnh.',
      ),
      'DANG_XU_LY' => (
        Icons.pending_outlined,
        Colors.amber.shade50,
        Colors.amber.shade300,
        Colors.amber.shade900,
        'Phiếu đang xử lý — chỉ xem',
        'Hệ thống đang tiến hành nhận dạng ảnh.',
      ),
      _ => (
        Icons.info_outline_rounded,
        Colors.blue.shade50,
        Colors.blue.shade300,
        Colors.blue.shade900,
        'Phiếu ở trạng thái $status — chỉ xem',
        'Chỉ xem, không thể chỉnh sửa giá trị.',
      ),
    };

    return Card(
      key: const ValueKey('review-status-banner'),
      margin: const EdgeInsets.only(bottom: 12),
      color: bgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withAlpha(210),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
