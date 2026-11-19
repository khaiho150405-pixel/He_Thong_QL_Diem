library;

const _accented =
    'àáạảãâầấậẩẫăằắặẳẵ'
    'èéẹẻẽêềếệểễ'
    'ìíịỉĩ'
    'òóọỏõôồốộổỗơờớợởỡ'
    'ùúụủũưừứựửữ'
    'ỳýỵỷỹ'
    'đ';
const _plain =
    'aaaaaaaaaaaaaaaaa'
    'eeeeeeeeeee'
    'iiiii'
    'ooooooooooooooooo'
    'uuuuuuuuuuu'
    'yyyyy'
    'd';

final Map<int, String> _foldMap = () {
  final accented = _accented.runes.toList();
  assert(accented.length == _plain.length, 'Bảng đổi dấu không khớp độ dài');
  return {
    for (var i = 0; i < accented.length && i < _plain.length; i++)
      accented[i]: _plain[i],
  };
}();

String foldVietnamese(String text) {
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    buffer.write(_foldMap[rune] ?? String.fromCharCode(rune));
  }
  return buffer.toString();
}

bool matchesSearch(String query, Iterable<String?> fields) {
  final tokens = foldVietnamese(
    query,
  ).split(RegExp(r'\s+')).where((token) => token.isNotEmpty);
  if (tokens.isEmpty) return true;
  final haystack = fields.whereType<String>().map(foldVietnamese).join(' ');
  return tokens.every(haystack.contains);
}
