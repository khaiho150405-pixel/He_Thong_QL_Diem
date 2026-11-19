String schoolYearName([DateTime? now]) {
  final today = now ?? DateTime.now();
  final start = today.month >= 8 ? today.year : today.year - 1;
  return '$start-${start + 1}';
}
