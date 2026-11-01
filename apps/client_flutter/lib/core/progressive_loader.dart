/// Một trang dữ liệu trả về từ máy chủ: các phần tử và con trỏ trang kế tiếp
/// (`null` khi đã hết).
class LoadedChunk<T, C> {
  const LoadedChunk(this.items, this.next);
  final List<T> items;
  final C? next;
}

/// Tải danh sách lớn theo kiểu "trang đầu trước, phần còn lại dưới nền".
///
/// [start] hoàn tất ngay khi có trang đầu tiên để màn hình hiển thị sớm; các
/// trang sau tiếp tục được nối vào [items] và gọi [onChanged] sau mỗi trang.
/// Gọi [start] lần nữa (hoặc [cancel]) thì phần tải nền cũ tự dừng.
class ProgressiveLoader<T, C> {
  ProgressiveLoader({required this.onChanged});

  /// Gọi mỗi khi [items], [loadingMore] hoặc [error] đổi (sau trang đầu tiên).
  final void Function() onChanged;

  List<T> _items = const [];
  bool _loadingMore = false;
  Object? _error;
  int _token = 0;
  String? _key;

  List<T> get items => _items;

  /// Còn trang chưa tải xong (đang chạy nền).
  bool get loadingMore => _loadingMore;

  /// Lỗi khi tải các trang sau; trang đầu lỗi thì [start] ném lỗi.
  Object? get error => _error;

  /// Khóa của lần tải gần nhất; cùng khóa thì không cần tải lại.
  String? get key => _key;

  void cancel() {
    _token++;
    _loadingMore = false;
  }

  Future<void> start(
    String key,
    Future<LoadedChunk<T, C>> Function(C? cursor) fetch,
  ) async {
    final token = ++_token;
    _key = null;
    _error = null;
    _loadingMore = false;
    _items = const [];
    final first = await fetch(null);
    if (token != _token) return;
    _key = key;
    _items = List<T>.unmodifiable(first.items);
    var cursor = first.next;
    if (cursor == null) return;
    _loadingMore = true;
    _continue(token, cursor, fetch);
  }

  Future<void> _continue(
    int token,
    C first,
    Future<LoadedChunk<T, C>> Function(C? cursor) fetch,
  ) async {
    C? cursor = first;
    final seen = <C>{};
    try {
      while (cursor != null) {
        if (!seen.add(cursor)) break;
        final chunk = await fetch(cursor);
        if (token != _token) return;
        _items = List<T>.unmodifiable([..._items, ...chunk.items]);
        cursor = chunk.next;
        _loadingMore = cursor != null;
        onChanged();
      }
    } catch (error) {
      if (token != _token) return;
      _error = error;
    }
    if (token != _token) return;
    _loadingMore = false;
    onChanged();
  }
}
