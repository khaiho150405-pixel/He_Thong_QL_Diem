/// Bộ tiện ích so sánh và sắp xếp chuỗi, họ tên theo chuẩn bảng chữ cái tiếng Việt.
/// Thứ tự bảng chữ cái: A, Ă, Â, B, C, D, Đ, E, Ê, G, H, I, K, L, M, N, O, Ô, Ơ, P, Q, R, S, T, U, Ư, V, X, Y
/// Thứ tự dấu thanh: Không dấu (ngang) < Huyền < Hỏi < Ngã < Sắc < Nặng.
class VietnameseCollation {
  static const List<String> _charOrder = [
    'a',
    'à',
    'ả',
    'ã',
    'á',
    'ạ',
    'ă',
    'ằ',
    'ẳ',
    'ẵ',
    'ắ',
    'ặ',
    'â',
    'ầ',
    'ẩ',
    'ẫ',
    'ấ',
    'ậ',
    'b',
    'c',
    'd',
    'đ',
    'e',
    'è',
    'ẻ',
    'ẽ',
    'é',
    'ẹ',
    'ê',
    'ề',
    'ể',
    'ễ',
    'ế',
    'ệ',
    'f',
    'g',
    'h',
    'i',
    'ì',
    'ỉ',
    'ĩ',
    'í',
    'ị',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'ò',
    'ỏ',
    'õ',
    'ó',
    'ọ',
    'ô',
    'ồ',
    'ổ',
    'ỗ',
    'ố',
    'ộ',
    'ơ',
    'ờ',
    'ở',
    'ỡ',
    'ớ',
    'ợ',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'ù',
    'ủ',
    'ũ',
    'ú',
    'ụ',
    'ư',
    'ừ',
    'ử',
    'ữ',
    'ứ',
    'ự',
    'v',
    'w',
    'x',
    'y',
    'ỳ',
    'ỷ',
    'ỹ',
    'ý',
    'ỵ',
    'z',
  ];

  static final Map<String, int> _weightMap = () {
    final map = <String, int>{};
    for (var i = 0; i < _charOrder.length; i++) {
      map[_charOrder[i]] = i;
    }
    return map;
  }();

  /// So sánh 2 chuỗi theo chuẩn chữ cái tiếng Việt.
  static int compare(String a, String b) {
    final strA = a.trim().toLowerCase();
    final strB = b.trim().toLowerCase();

    final runesA = strA.runes.toList();
    final runesB = strB.runes.toList();
    final minLen = runesA.length < runesB.length
        ? runesA.length
        : runesB.length;

    for (var i = 0; i < minLen; i++) {
      final charA = String.fromCharCode(runesA[i]);
      final charB = String.fromCharCode(runesB[i]);

      if (charA == charB) continue;

      final weightA = _weightMap[charA];
      final weightB = _weightMap[charB];

      if (weightA != null && weightB != null) {
        return weightA.compareTo(weightB);
      }
      if (weightA != null) return -1;
      if (weightB != null) return 1;

      final codeCmp = charA.compareTo(charB);
      if (codeCmp != 0) return codeCmp;
    }

    return runesA.length.compareTo(runesB.length);
  }

  /// So sánh họ và tên học sinh theo chuẩn giáo dục Việt Nam:
  /// 1. Xét Tên chính trước (từ cuối cùng, ví dụ: "Châu", "An", "Bình", "Đức").
  /// 2. Nếu Tên chính trùng nhau, xét tiếp Họ và Tên đệm (ví dụ: "Lê Bảo Châu" vs "Trần Bảo Châu").
  static int compareStudentNames(String nameA, String nameB) {
    final cleanA = nameA.trim();
    final cleanB = nameB.trim();

    if (cleanA.isEmpty && cleanB.isEmpty) return 0;
    if (cleanA.isEmpty) return 1;
    if (cleanB.isEmpty) return -1;

    final partsA = cleanA.split(RegExp(r'\s+'));
    final partsB = cleanB.split(RegExp(r'\s+'));

    // Tên chính là từ cuối cùng
    final firstNameA = partsA.last;
    final firstNameB = partsB.last;

    final firstNameCmp = compare(firstNameA, firstNameB);
    if (firstNameCmp != 0) return firstNameCmp;

    // Nếu tên chính giống nhau, so sánh toàn bộ Họ và Tên
    return compare(cleanA, cleanB);
  }
}

/// Chỉ mục số thứ tự hiển thị của học sinh.
///
/// Số thứ tự toàn trường và theo lớp đều được tính từ cùng một danh sách đầy
/// đủ, nên tìm kiếm, lọc trạng thái và phân trang không làm thay đổi số đã cấp.
class StudentOrderIndex {
  StudentOrderIndex._(this.school, this.byClass);

  factory StudentOrderIndex.from(List<Map<String, dynamic>> students) {
    final school = <num, int>{};
    final byClass = <num, int>{};
    final schoolSorted = [...students]..sort(_compareStudents);

    for (var index = 0; index < schoolSorted.length; index++) {
      final studentId = schoolSorted[index]['ma_hoc_sinh'] as num?;
      if (studentId != null) school[studentId] = index + 1;
    }

    final classGroups = <num, List<Map<String, dynamic>>>{};
    for (final student in students) {
      final classId = student['ma_lop'] as num?;
      if (classId != null) {
        classGroups.putIfAbsent(classId, () => []).add(student);
      }
    }

    for (final group in classGroups.values) {
      group.sort(_compareStudents);
      for (var index = 0; index < group.length; index++) {
        final studentId = group[index]['ma_hoc_sinh'] as num?;
        if (studentId != null) byClass[studentId] = index + 1;
      }
    }

    return StudentOrderIndex._(school, byClass);
  }

  final Map<num, int> school;
  final Map<num, int> byClass;

  int? orderFor(num? studentId, {required bool classScope}) {
    if (studentId == null) return null;
    return classScope ? byClass[studentId] : school[studentId];
  }

  static int _compareStudents(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) {
    final byName = VietnameseCollation.compareStudentNames(
      (first['ho_ten'] ?? '').toString(),
      (second['ho_ten'] ?? '').toString(),
    );
    if (byName != 0) return byName;

    final firstId = first['ma_hoc_sinh'] as num?;
    final secondId = second['ma_hoc_sinh'] as num?;
    if (firstId == null && secondId == null) return 0;
    if (firstId == null) return 1;
    if (secondId == null) return -1;
    return firstId.compareTo(secondId);
  }
}
