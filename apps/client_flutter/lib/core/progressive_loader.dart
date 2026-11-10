class LoadedChunk<T, C> {
  const LoadedChunk(this.items, this.next);
  final List<T> items;
  final C? next;
}

class ProgressiveLoader<T, C> {
  ProgressiveLoader({required this.onChanged});

  final void Function() onChanged;

  List<T> _items = const [];
  bool _loadingMore = false;
  Object? _error;
  int _token = 0;
  String? _key;

  List<T> get items => _items;

  bool get loadingMore => _loadingMore;

  Object? get error => _error;

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
