String excelFileName(List<String?> parts) {
  final cleaned = [
    for (final part in parts)
      if (part != null) _clean(part),
  ].where((part) => part.isNotEmpty).toList();
  var base = cleaned.join(' - ');
  if (base.length > 120) base = base.substring(0, 120).trim();
  return '${base.isEmpty ? 'Bảng điểm' : base}.xlsx';
}

String _clean(String value) => value
    .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
