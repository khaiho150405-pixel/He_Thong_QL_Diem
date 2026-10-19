import 'package:api_client_dart/api_client_dart.dart';

typedef Role = TemplateColumnDtoRoleEnum;
typedef Group = TemplateColumnDtoGroupEnum;

/// Số thứ tự tối đa trong một nhóm hệ số (cùng giới hạn với backend).
const int kMaxOrderInGroup = 20;

/// Một cột đang được khai báo trên form. Bất biến; sửa bằng [copyWith].
class ColumnDraft {
  const ColumnDraft({
    required this.index,
    required this.headerText,
    required this.role,
    this.group,
    this.order,
    this.pairedWith,
    this.suggested = false,
  });

  /// Dựng từ kết quả `analyze`: vai trò gợi ý được chọn sẵn và đánh dấu
  /// [suggested]; không đọc được tiêu đề (`suggestedRole == null`) thì "Bỏ qua".
  factory ColumnDraft.fromAnalyzed(AnalyzedColumnDto column) {
    final role = switch (column.suggestedRole) {
      AnalyzedColumnDtoSuggestedRoleEnum.STT => Role.STT,
      AnalyzedColumnDtoSuggestedRoleEnum.HO_TEN => Role.HO_TEN,
      AnalyzedColumnDtoSuggestedRoleEnum.DIEM => Role.DIEM,
      AnalyzedColumnDtoSuggestedRoleEnum.DIEM_CHU => Role.DIEM_CHU,
      _ => Role.BO_QUA,
    };
    final group = role == Role.DIEM
        ? switch (column.suggestedGroup) {
            AnalyzedColumnDtoSuggestedGroupEnum.TX => Group.TX,
            AnalyzedColumnDtoSuggestedGroupEnum.GK => Group.GK,
            AnalyzedColumnDtoSuggestedGroupEnum.CK => Group.CK,
            _ => null,
          }
        : null;
    return ColumnDraft(
      index: column.index.toInt(),
      headerText: column.headerText,
      role: role,
      group: group,
      order: role == Role.DIEM && group != null
          ? (column.suggestedOrder?.toInt() ?? 1)
          : null,
      suggested: column.suggestedRole != null,
    );
  }

  /// Dựng từ mẫu đã lưu (màn sửa / tạo phiên bản).
  factory ColumnDraft.fromTemplate(TemplateColumnDto column) => ColumnDraft(
    index: column.index.toInt(),
    headerText: column.headerText ?? '',
    role: column.role,
    group: column.group,
    order: column.order?.toInt(),
    pairedWith: column.pairedWith?.toInt(),
  );

  final int index;
  final String headerText;
  final Role role;
  final Group? group;
  final int? order;
  final int? pairedWith;

  /// Vai trò đang hiển thị là gợi ý của máy, chưa được người dùng đổi.
  final bool suggested;

  /// Đổi vai trò: bỏ các trường không thuộc vai trò mới (backend từ chối
  /// `EXTRA_FIELDS`); cột điểm mới được gán sẵn nhóm TX và thứ tự còn trống.
  ColumnDraft withRole(Role next, {required Iterable<ColumnDraft> others}) {
    if (next == role) return this;
    return switch (next) {
      Role.DIEM => ColumnDraft(
        index: index,
        headerText: headerText,
        role: next,
        group: Group.TX,
        order: _firstFreeOrder(Group.TX, others),
      ),
      Role.DIEM_CHU => ColumnDraft(
        index: index,
        headerText: headerText,
        role: next,
      ),
      _ => ColumnDraft(index: index, headerText: headerText, role: next),
    };
  }

  ColumnDraft withGroup(Group next, {required Iterable<ColumnDraft> others}) =>
      ColumnDraft(
        index: index,
        headerText: headerText,
        role: role,
        group: next,
        order: _firstFreeOrder(next, others),
      );

  ColumnDraft withOrder(int? next) => ColumnDraft(
    index: index,
    headerText: headerText,
    role: role,
    group: group,
    order: next,
  );

  ColumnDraft withPairedWith(int? next) => ColumnDraft(
    index: index,
    headerText: headerText,
    role: role,
    pairedWith: next,
  );

  static int _firstFreeOrder(Group group, Iterable<ColumnDraft> others) {
    final used = {
      for (final c in others)
        if (c.role == Role.DIEM && c.group == group && c.order != null)
          c.order!,
    };
    for (var n = 1; n <= kMaxOrderInGroup; n++) {
      if (!used.contains(n)) return n;
    }
    return 1;
  }

  TemplateColumnDto toDto() => TemplateColumnDto(
    index: index,
    role: role,
    group: role == Role.DIEM ? group : null,
    order: role == Role.DIEM ? order : null,
    pairedWith: role == Role.DIEM_CHU ? pairedWith : null,
    headerText: headerText.isEmpty ? null : headerText,
  );
}

/// Trường của cột mà lỗi gắn vào (để hiện lỗi sát đúng ô).
enum DraftField { role, group, order, pairedWith }

/// Mã luật, đặt trùng tên với [DefinitionIssue] của backend để dễ đối chiếu.
enum DraftRule { hoTen, stt, noDiem, diemFields, groupOrderDuplicate, pairing }

class DraftIssue {
  const DraftIssue(this.rule, this.message, {this.column, this.field});

  final DraftRule rule;
  final String message;

  /// `index` của cột sai; null với lỗi chung (không gắn cột nào).
  final int? column;
  final DraftField? field;
}

/// Kết quả kiểm hợp lệ của cả danh sách cột.
class DraftValidation {
  const DraftValidation(this.issues);

  final List<DraftIssue> issues;

  bool get isValid => issues.isEmpty;

  List<DraftIssue> get general => [
    for (final issue in issues)
      if (issue.column == null) issue,
  ];

  List<DraftIssue> forColumn(int index) => [
    for (final issue in issues)
      if (issue.column == index) issue,
  ];

  bool has(DraftRule rule) => issues.any((issue) => issue.rule == rule);
}

/// Cùng luật với `validateColumns` của backend (ADR-0016 mục 1). Backend vẫn là
/// nơi kiểm cuối; hàm này chỉ chặn sớm và chỉ đúng cột sai.
DraftValidation validateDrafts(List<ColumnDraft> columns) {
  final issues = <DraftIssue>[];

  final names = [
    for (final c in columns)
      if (c.role == Role.HO_TEN) c,
  ];
  if (names.isEmpty) {
    issues.add(const DraftIssue(DraftRule.hoTen, 'Chọn đúng một cột Họ tên.'));
  } else if (names.length > 1) {
    for (final c in names) {
      issues.add(
        DraftIssue(
          DraftRule.hoTen,
          'Chỉ được một cột Họ tên.',
          column: c.index,
          field: DraftField.role,
        ),
      );
    }
  }

  final stts = [
    for (final c in columns)
      if (c.role == Role.STT) c,
  ];
  if (stts.length > 1) {
    for (final c in stts) {
      issues.add(
        DraftIssue(
          DraftRule.stt,
          'Chỉ được một cột STT.',
          column: c.index,
          field: DraftField.role,
        ),
      );
    }
  }

  final grades = [
    for (final c in columns)
      if (c.role == Role.DIEM) c,
  ];
  if (grades.isEmpty) {
    issues.add(
      const DraftIssue(DraftRule.noDiem, 'Cần ít nhất một cột Điểm số.'),
    );
  }
  final complete = <ColumnDraft>[];
  for (final c in grades) {
    final badGroup = c.group == null;
    final badOrder =
        c.order == null || c.order! < 1 || c.order! > kMaxOrderInGroup;
    if (badGroup) {
      issues.add(
        DraftIssue(
          DraftRule.diemFields,
          'Chọn nhóm hệ số (TX, GK hoặc CK).',
          column: c.index,
          field: DraftField.group,
        ),
      );
    }
    if (badOrder) {
      issues.add(
        DraftIssue(
          DraftRule.diemFields,
          'Chọn thứ tự trong nhóm, từ 1 đến $kMaxOrderInGroup.',
          column: c.index,
          field: DraftField.order,
        ),
      );
    }
    if (!badGroup && !badOrder) complete.add(c);
  }
  final byKey = <String, List<ColumnDraft>>{};
  for (final c in complete) {
    byKey.putIfAbsent('${c.group!.value}:${c.order}', () => []).add(c);
  }
  for (final entry in byKey.entries) {
    if (entry.value.length < 2) continue;
    for (final c in entry.value) {
      issues.add(
        DraftIssue(
          DraftRule.groupOrderDuplicate,
          'Trùng ${c.group!.value} thứ ${c.order} với cột khác.',
          column: c.index,
          field: DraftField.order,
        ),
      );
    }
  }

  final gradeIndexes = {for (final c in grades) c.index};
  final writtenColumns = [
    for (final c in columns)
      if (c.role == Role.DIEM_CHU) c,
  ];
  final targetCount = <int, int>{};
  for (final c in writtenColumns) {
    if (c.pairedWith != null) {
      targetCount[c.pairedWith!] = (targetCount[c.pairedWith!] ?? 0) + 1;
    }
  }
  for (final c in writtenColumns) {
    final target = c.pairedWith;
    if (target == null || !gradeIndexes.contains(target)) {
      issues.add(
        DraftIssue(
          DraftRule.pairing,
          target == null
              ? 'Chọn cột Điểm số mà cột chữ này đi kèm.'
              : 'Cột đi kèm phải là một cột Điểm số.',
          column: c.index,
          field: DraftField.pairedWith,
        ),
      );
    } else if ((targetCount[target] ?? 0) > 1) {
      issues.add(
        DraftIssue(
          DraftRule.pairing,
          'Mỗi cột Điểm số chỉ có một cột chữ đi kèm.',
          column: c.index,
          field: DraftField.pairedWith,
        ),
      );
    }
  }

  return DraftValidation(issues);
}
