import 'package:flutter/widgets.dart';

/// Bật nhãn "Trang n" cho các thẻ dòng của một phiếu thuộc lô nhiều trang
/// (ADR-0016 mục 3). Chỉ là nhãn hiển thị; màn đối chiếu không đổi logic.
///
/// API chưa trả `so_trang` trong dòng đối chiếu. Backend ghi
/// `thu_tu_dong = (trang − 1) × 1000 + vị trí` (xem ghi chú hiện thực P3), nên
/// trang suy ra từ `order`. Phiếu cũ (không thuộc lô) không bao giờ được bọc
/// bởi widget này với `enabled = true`, nên không có nhãn.
class ReviewPageLabels extends InheritedWidget {
  const ReviewPageLabels({
    super.key,
    required this.enabled,
    required super.child,
  });

  final bool enabled;

  /// Số dòng trên một trang tối đa mà backend dành cho mỗi trang.
  static const int rowsPerPage = 1000;

  /// Phiếu có dòng với `order` ≥ 1000 chắc chắn thuộc lô (phiếu cũ đánh số
  /// dòng từ 1 và không bao giờ tới 1000).
  static bool looksBatched(Iterable<num> orders) =>
      orders.any((order) => order >= rowsPerPage);

  static int pageOfOrder(num order) => order ~/ rowsPerPage + 1;

  /// Nhãn "Trang n" của dòng, `null` khi phiếu không thuộc lô.
  static String? labelOf(BuildContext context, num order) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ReviewPageLabels>();
    if (scope == null || !scope.enabled) return null;
    return 'Trang ${pageOfOrder(order)}';
  }

  @override
  bool updateShouldNotify(ReviewPageLabels oldWidget) =>
      oldWidget.enabled != enabled;
}
