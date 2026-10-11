import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import '../../../app/widgets/app_controls.dart';
import 'review_bottom_bar.dart';
import 'review_green_group.dart';
import 'review_header.dart';
import 'review_row_content.dart';

/// Chế độ xem từng dòng (PageView) trên Mobile cho các dòng Đỏ/Vàng/STT-khác.
/// Hết các dòng cần xem → hiển thị trang tổng kết với ô xác nhận và nút Duyệt.
class ReviewMobilePager extends StatefulWidget {
  final List<RecognitionEvidenceRowDto> needReviewRows;
  final List<RecognitionEvidenceRowDto> greenRows;
  final Map<String, TextEditingController> values;
  final Map<String, TextEditingController> reasons;
  final Map<String, bool> leavingEmpty;
  final Map<String, bool> agreedYellow;
  final bool enabled;
  final void Function(String rowId, String text) onGradeChanged;
  final void Function(String rowId, String text)? onReasonChanged;
  final void Function(String rowId) onLeaveEmpty;
  final void Function(String rowId) onCancelLeaveEmpty;
  final void Function(String rowId) onAgreeYellow;
  final VoidCallback onToggleMode;
  final bool confirmed;
  final ValueChanged<bool> onConfirmedChanged;
  final VoidCallback onApprove;
  final int totalRows;
  final bool canApprove;
  final bool allRedHandled;
  final bool hasGradebookVersion;
  final bool busy;
  final VoidCallback? onRefresh;
  final bool readOnly;
  final Map<String, bool> sttConfirmed;
  final void Function(String rowId, bool confirmed)? onSttConfirmedChanged;
  final bool allSttWarningsConfirmed;
  final RecognitionTicketDetailDto? ticket;
  final String? currentFilter;
  final ValueChanged<String>? onFilterChanged;
  final int totalNeedReview;
  final int reviewedCount;

  const ReviewMobilePager({
    super.key,
    required this.needReviewRows,
    required this.greenRows,
    required this.values,
    required this.reasons,
    required this.leavingEmpty,
    required this.agreedYellow,
    required this.enabled,
    required this.onGradeChanged,
    this.onReasonChanged,
    required this.onLeaveEmpty,
    required this.onCancelLeaveEmpty,
    required this.onAgreeYellow,
    required this.onToggleMode,
    required this.confirmed,
    required this.onConfirmedChanged,
    required this.onApprove,
    required this.totalRows,
    required this.canApprove,
    required this.allRedHandled,
    required this.hasGradebookVersion,
    required this.busy,
    this.onRefresh,
    this.readOnly = false,
    this.sttConfirmed = const {},
    this.onSttConfirmedChanged,
    this.allSttWarningsConfirmed = true,
    this.ticket,
    this.currentFilter,
    this.onFilterChanged,
    this.totalNeedReview = 0,
    this.reviewedCount = 0,
  });

  @override
  State<ReviewMobilePager> createState() => _ReviewMobilePagerState();
}

class _ReviewMobilePagerState extends State<ReviewMobilePager> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(ReviewMobilePager oldWidget) {
    super.didUpdateWidget(oldWidget);
    final maxPage = widget.needReviewRows.length;
    if (_currentPage > maxPage) {
      _currentPage = maxPage;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final totalPages = widget.needReviewRows.length + 1;
    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRows = widget.needReviewRows.length;
    final totalPages = totalRows + 1;

    return Column(
      children: [
        // Thanh tóm tắt đầu trang: chip Đỏ/Vàng/Xanh/STT khác + tiến độ (đồng bộ web)
        if (widget.ticket != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: ReviewHeader(
              ticket: widget.ticket!,
              currentFilter: widget.currentFilter ?? 'ALL',
              onFilterChanged: (filter) {
                widget.onFilterChanged?.call(filter);
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(0);
                }
              },
              totalNeedReview: widget.totalNeedReview,
              reviewedCount: widget.reviewedCount,
            ),
          ),

        // Banner chỉ xem nếu phiếu đã duyệt
        if (widget.readOnly && widget.ticket != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: _buildReadOnlyBanner(context, widget.ticket!.status.value),
          ),

        // Thanh chỉ báo dòng đang xem + nút chuyển dạng danh sách
        _buildTopStepper(context, totalRows),

        // Khung trượt PageView từng dòng
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalPages,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              if (index < totalRows) {
                return _buildRowPage(context, index);
              }
              return _buildSummaryPage(context);
            },
          ),
        ),

        // Thanh điều hướng chân trang (trừ khi ở trang tổng kết)
        if (_currentPage < totalRows) _buildPagerNavigation(context),
      ],
    );
  }

  Widget _buildReadOnlyBanner(BuildContext context, String status) {
    final isApproved = status == 'DA_DUYET';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isApproved ? Colors.green.shade200 : Colors.amber.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isApproved
                ? Icons.lock_outline_rounded
                : Icons.info_outline_rounded,
            size: 18,
            color: isApproved ? Colors.green.shade800 : Colors.amber.shade900,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isApproved
                  ? 'Phiếu đã duyệt — chỉ xem'
                  : 'Phiếu trạng thái $status — chỉ xem',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isApproved
                    ? Colors.green.shade900
                    : Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStepper(BuildContext context, int totalRows) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSummary = _currentPage >= totalRows;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withAlpha(80),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(100)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isSummary
                  ? 'Trang tổng kết & Duyệt'
                  : 'Dòng ${_currentPage + 1} / $totalRows cần xem',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSummary ? Colors.green.shade800 : colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: widget.onToggleMode,
            icon: const Icon(Icons.list_alt_rounded, size: 16),
            label: const Text('Danh sách', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(44, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowPage(BuildContext context, int index) {
    final row = widget.needReviewRows[index];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ReviewRowContent(
        row: row,
        valueController: widget.values[row.rowId]!,
        reasonController: widget.reasons[row.rowId]!,
        isLeavingEmpty: widget.leavingEmpty[row.rowId] ?? false,
        isAgreedYellow: widget.agreedYellow[row.rowId] ?? false,
        enabled: widget.enabled,
        onGradeChanged: (v) => widget.onGradeChanged(row.rowId, v),
        onReasonChanged: widget.onReasonChanged != null
            ? (v) => widget.onReasonChanged!(row.rowId, v)
            : null,
        onLeaveEmpty: () => widget.onLeaveEmpty(row.rowId),
        onCancelLeaveEmpty: () => widget.onCancelLeaveEmpty(row.rowId),
        onAgreeYellow: () => widget.onAgreeYellow(row.rowId),
        onRefresh: widget.onRefresh,
        readOnly: widget.readOnly,
        isSttConfirmed: widget.sttConfirmed[row.rowId] ?? false,
        onSttConfirmedChanged: (v) =>
            widget.onSttConfirmedChanged?.call(row.rowId, v),
        layout: ReviewRowLayout.narrow,
        showInlineAgreeButton: false,
      ),
    );
  }

  Widget _buildSummaryPage(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.green.shade50.withAlpha(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.green.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 44,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đã đối chiếu hết các dòng cần xem!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bạn có thể kiểm tra danh sách dòng Xanh bên dưới, xác nhận và duyệt phiếu.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ReviewGreenGroup(
            rows: widget.greenRows,
            values: widget.values,
            enabled: widget.enabled,
            onGradeChanged: widget.onGradeChanged,
            readOnly: widget.readOnly,
          ),
          const SizedBox(height: 16),
          if (!widget.readOnly)
            ReviewBottomBar(
              confirmed: widget.confirmed,
              onConfirmedChanged: widget.onConfirmedChanged,
              onApprove: widget.onApprove,
              totalRows: widget.totalRows,
              canApprove: widget.canApprove,
              allRedHandled: widget.allRedHandled,
              hasGradebookVersion: widget.hasGradebookVersion,
              busy: widget.busy,
              allSttWarningsConfirmed: widget.allSttWarningsConfirmed,
            ),
        ],
      ),
    );
  }

  Widget _buildPagerNavigation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final row = widget.needReviewRows[_currentPage];
    final isYellow = row.reviewLevel.value == 'VANG';
    final isAgreedYellow = widget.agreedYellow[row.rowId] == true;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withAlpha(120)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: AppControlMetrics.height,
                child: OutlinedButton(
                  onPressed: _currentPage > 0 ? _previousPage : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, AppControlMetrics.height),
                  ),
                  child: const Text('‹ Trước', style: TextStyle(fontSize: 14)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: AppControlMetrics.height,
                child: FilledButton.icon(
                  key: isYellow ? ValueKey('review-agree-${row.rowId}') : null,
                  onPressed: () {
                    if (isYellow) {
                      widget.onAgreeYellow(row.rowId);
                    }
                    _nextPage();
                  },
                  icon: Icon(
                    isYellow
                        ? (isAgreedYellow
                              ? Icons.check_circle_rounded
                              : Icons.check_rounded)
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isYellow
                        ? (isAgreedYellow
                              ? 'Đã xem ✓ & tiếp'
                              : '✓ Đồng ý & tiếp')
                        : 'Tiếp ›',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: isYellow
                        ? (isAgreedYellow
                              ? Colors.green.shade700
                              : Colors.amber.shade800)
                        : null,
                    foregroundColor: isYellow ? Colors.white : null,
                    minimumSize: const Size(48, AppControlMetrics.height),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
