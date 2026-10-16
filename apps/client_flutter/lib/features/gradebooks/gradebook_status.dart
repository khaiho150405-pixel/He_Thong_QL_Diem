import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import '../../app/widgets/app_badge.dart';

/// Nhãn trạng thái bảng điểm thay cho nút "Chốt" (kế hoạch mục 0.1, ADR-0014).
///
/// Chỉ ánh xạ giá trị `status` do backend trả về sang chữ và màu:
/// `DANG_NHAP_LIEU` thành "Đang nhập liệu" (info), `DA_CHOT` thành "Đã khóa"
/// (ok). Không có thao tác nào gắn với nhãn này: giao diện không gọi chốt
/// bảng hay chốt cột.
({AppBadgeTone tone, String label}) gradebookStatusOf(String status) {
  switch (status) {
    case 'DANG_NHAP_LIEU':
      return (tone: AppBadgeTone.info, label: 'Đang nhập liệu');
    case 'DA_CHOT':
      return (tone: AppBadgeTone.ok, label: 'Đã khóa');
    default:
      return (tone: AppBadgeTone.neutral, label: status);
  }
}

/// Huy hiệu trạng thái bảng điểm dùng chung cho danh sách và trang chi tiết.
class GradebookStatusBadge extends StatelessWidget {
  const GradebookStatusBadge(this.status, {super.key});

  /// Giá trị `GradebookDto.status.value`.
  final String status;

  @override
  Widget build(BuildContext context) {
    final view = gradebookStatusOf(status);
    return AppBadge(view.label, tone: view.tone);
  }
}

/// Thời điểm đóng muộn nhất trong các cột nhập điểm, CHỈ KHI mọi cột đều có
/// `closesAt` đọc được; ngược lại trả `null` (không đoán hạn khóa).
///
/// [columns] là mỗi cột nhập được một phần tử [GradeCellDto] đại diện (cùng
/// nguồn với `GradeDeadlinesPanel`). Đây chỉ là cách hiển thị giá trị đã có:
/// ADR-0014 nói muốn tự khóa cả bảng thì phải đặt lịch cho mọi cột, nên thiếu
/// một cột là không hiện hạn. Danh sách rỗng cũng trả `null`.
DateTime? latestColumnClosesAt(List<GradeCellDto> columns) {
  if (columns.isEmpty) return null;
  DateTime? latest;
  for (final column in columns) {
    final raw = column.closesAt;
    final parsed = raw == null ? null : DateTime.tryParse(raw);
    if (parsed == null) return null;
    if (latest == null || parsed.isAfter(latest)) latest = parsed;
  }
  return latest;
}
