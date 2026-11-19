import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import '../../app/widgets/app_badge.dart';

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

class GradebookStatusBadge extends StatelessWidget {
  const GradebookStatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final view = gradebookStatusOf(status);
    return AppBadge(view.label, tone: view.tone);
  }
}

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
