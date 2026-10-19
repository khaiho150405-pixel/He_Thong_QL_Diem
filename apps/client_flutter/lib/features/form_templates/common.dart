import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import 'column_draft.dart';

String roleLabel(Role role) => switch (role) {
  Role.STT => 'STT',
  Role.HO_TEN => 'Họ tên',
  Role.DIEM => 'Điểm số',
  Role.DIEM_CHU => 'Điểm chữ',
  Role.BO_QUA => 'Bỏ qua',
};

String groupLabel(Group group) => switch (group) {
  Group.TX => 'Thường xuyên (TX)',
  Group.GK => 'Giữa kỳ (GK)',
  Group.CK => 'Cuối kỳ (CK)',
};

/// Nhãn ngắn cho cột điểm, ví dụ `TX1`; null nếu chưa đủ nhóm và thứ tự.
String? gradeKeyOf(ColumnDraft column) =>
    column.group == null || column.order == null
    ? null
    : '${column.group!.value}${column.order}';

AppBadge templateStatusBadge(TemplateSummaryDtoStatusEnum status) =>
    switch (status) {
      TemplateSummaryDtoStatusEnum.NHAP => const AppBadge('Nháp'),
      TemplateSummaryDtoStatusEnum.DANG_DUNG => const AppBadge.ok('Đang dùng'),
      TemplateSummaryDtoStatusEnum.NGUNG => const AppBadge.warn('Ngừng'),
    };

AppBadge templateDetailStatusBadge(TemplateDetailDtoStatusEnum status) =>
    switch (status) {
      TemplateDetailDtoStatusEnum.NHAP => const AppBadge('Nháp'),
      TemplateDetailDtoStatusEnum.DANG_DUNG => const AppBadge.ok('Đang dùng'),
      TemplateDetailDtoStatusEnum.NGUNG => const AppBadge.warn('Ngừng'),
    };

/// Kiểu đọc suy ra từ khai báo cột (ADR-0016): cột điểm có cột chữ đi kèm thì
/// đọc hai kênh; mẫu không có cột chữ nào thì chỉ đọc số. Trộn cả hai thì nói rõ.
String readModeLabel(List<TemplateColumnDto> columns) {
  final grades = [
    for (final c in columns)
      if (c.role == TemplateColumnDtoRoleEnum.DIEM) c.index,
  ];
  final paired = {
    for (final c in columns)
      if (c.role == TemplateColumnDtoRoleEnum.DIEM_CHU && c.pairedWith != null)
        c.pairedWith!,
  };
  final both = grades.where(paired.contains).length;
  if (grades.isEmpty) return '—';
  if (both == grades.length) return 'Số + chữ';
  if (both == 0) return 'Chỉ số';
  return 'Số + chữ ($both/${grades.length} cột)';
}

/// Thẻ nội dung theo token (nền `surface`, viền `line`).
class TemplateCard extends StatelessWidget {
  const TemplateCard({
    super.key,
    required this.child,
    this.borderColor,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor ?? t.line),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Khung thông báo lỗi/ghi chú theo tông token, có icon.
class TemplateNotice extends StatelessWidget {
  const TemplateNotice({
    super.key,
    required this.message,
    this.tone = AppBadgeTone.bad,
    this.icon = Icons.error_outline,
    this.action,
  });

  final String message;
  final AppBadgeTone tone;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: fg),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    action!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lề trang theo bề rộng: 24 trên màn rộng, 16 trên màn hẹp.
EdgeInsets templatePagePadding(BuildContext context) => EdgeInsets.all(
  MediaQuery.sizeOf(context).width >= 600
      ? AppSpacing.page
      : AppSpacing.pageCompact,
);
