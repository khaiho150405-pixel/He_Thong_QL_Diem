/// Ngày giờ theo múi giờ của máy, dạng `dd/MM/yyyy HH:mm` (đồng bộ với ô nhập
/// ngày `AppDateField` và các màn hình khác; không dùng định dạng của
/// `MaterialLocalizations` vì ra "5 thg 11, 2026").
String formatDateTimeVi(DateTime value) {
  final d = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}
