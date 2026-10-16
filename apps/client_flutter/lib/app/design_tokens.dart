import 'package:flutter/material.dart';

/// Design tokens lấy từ `docs/design/Hệ thống quản lý điểm.html`
/// (`:root` cho sáng, `prefers-color-scheme: dark` cho tối).
///
/// Component dùng chung đọc token qua `context.tokens` thay vì viết màu cứng,
/// để tự đổi theo chế độ sáng/tối của hệ thống.

/// Tên family khai báo trong `pubspec.yaml` (file nằm ở `assets/fonts/`).
const String kAppFontFamily = 'BeVietnamPro';

/// Font dự phòng cho ký tự mà Be Vietnam Pro không có.
const List<String> kAppFontFallback = ['Roboto', 'Arial', 'Noto Sans'];

/// Khoảng cách theo lưới 4/8 của prototype.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Lề trang: 24 trên màn rộng, 16 trên màn hẹp.
  static const double page = 24;
  static const double pageCompact = 16;

  /// Khoảng cách giữa các ô lưới và giữa các hàng trong prototype.
  static const double gridGap = 16;
  static const double rowGap = 12;

  /// Thẻ: tiêu đề `16 20`, nội dung 20.
  static const EdgeInsets cardHeader = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );
  static const EdgeInsets cardBody = EdgeInsets.all(20);
}

/// Bo góc của prototype.
abstract final class AppRadius {
  /// Chip nhỏ trong bảng, ô điểm.
  static const double xs = 6;

  /// Nút, ô nhập, select.
  static const double sm = 8;

  /// Thẻ.
  static const double md = 12;

  /// Hộp thoại.
  static const double lg = 14;

  /// Khung ứng dụng, trang đăng nhập.
  static const double xl = 16;

  /// Badge, progress, chip lọc.
  static const double pill = 999;
}

/// Bộ màu và đổ bóng của một chế độ (sáng hoặc tối).
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.subtle,
    required this.hover,
    required this.line,
    required this.line2,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.navy,
    required this.navy2,
    required this.onNavy,
    required this.navyLine,
    required this.pri,
    required this.priHover,
    required this.priLink,
    required this.priSoft,
    required this.priLine,
    required this.onPri,
    required this.acc,
    required this.accSoft,
    required this.onAcc,
    required this.ok,
    required this.okSoft,
    required this.okLine,
    required this.warn,
    required this.warnSoft,
    required this.warnLine,
    required this.bad,
    required this.badSoft,
    required this.badLine,
    required this.neu,
    required this.neuSoft,
    required this.paper,
    required this.pen,
    required this.paperLine,
    required this.focus,
    required this.shadow,
    required this.pop,
  });

  final Brightness brightness;

  // Nền và đường kẻ.
  final Color bg;
  final Color surface;
  final Color subtle;
  final Color hover;
  final Color line;
  final Color line2;

  // Chữ.
  final Color ink;
  final Color ink2;
  final Color ink3;

  // Navy (thanh bên, hero).
  final Color navy;
  final Color navy2;
  final Color onNavy;
  final Color navyLine;

  // Primary.
  final Color pri;
  final Color priHover;
  final Color priLink;
  final Color priSoft;
  final Color priLine;
  final Color onPri;

  // Nhấn amber.
  final Color acc;
  final Color accSoft;
  final Color onAcc;

  // Trạng thái: thành công, cảnh báo, lỗi, trung tính.
  final Color ok;
  final Color okSoft;
  final Color okLine;
  final Color warn;
  final Color warnSoft;
  final Color warnLine;
  final Color bad;
  final Color badSoft;
  final Color badLine;
  final Color neu;
  final Color neuSoft;

  // Tờ giấy mô phỏng bảng điểm.
  final Color paper;
  final Color pen;
  final Color paperLine;

  final Color focus;

  /// Đổ bóng thẻ (`--shadow`) và lớp nổi như hộp thoại, toast (`--pop`).
  final List<BoxShadow> shadow;
  final List<BoxShadow> pop;

  static const AppTokens light = AppTokens(
    brightness: Brightness.light,
    bg: Color(0xFFF3F6FB),
    surface: Color(0xFFFFFFFF),
    subtle: Color(0xFFF7F9FC),
    hover: Color(0xFFEEF3FA),
    line: Color(0xFFDDE4EE),
    line2: Color(0xFFC3CDDC),
    ink: Color(0xFF14213D),
    ink2: Color(0xFF44546F),
    ink3: Color(0xFF62728F),
    navy: Color(0xFF0F2B5B),
    navy2: Color(0xFF1A3D7C),
    onNavy: Color(0xFFB6C4DE),
    navyLine: Color(0x1FFFFFFF),
    pri: Color(0xFF1F5FD1),
    priHover: Color(0xFF1A4FB0),
    priLink: Color(0xFF1F5FD1),
    priSoft: Color(0xFFE8F0FD),
    priLine: Color(0xFFB9CEF5),
    onPri: Color(0xFFFFFFFF),
    acc: Color(0xFFF2A900),
    accSoft: Color(0xFFFFF4D6),
    onAcc: Color(0xFF0A1F44),
    ok: Color(0xFF12805C),
    okSoft: Color(0xFFE3F6EE),
    okLine: Color(0xFFA7DEC8),
    warn: Color(0xFF8A5600),
    warnSoft: Color(0xFFFFF3D1),
    warnLine: Color(0xFFF3D58A),
    bad: Color(0xFFC23B3B),
    badSoft: Color(0xFFFDE8E8),
    badLine: Color(0xFFF1B4B4),
    neu: Color(0xFF5B6B86),
    neuSoft: Color(0xFFEAEFF6),
    paper: Color(0xFFFBFAF3),
    pen: Color(0xFF1B2A6B),
    paperLine: Color(0xFFE4DFCB),
    focus: Color(0x471F5FD1),
    shadow: [
      BoxShadow(color: Color(0x0F102A5A), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x0D102A5A), offset: Offset(0, 4), blurRadius: 12),
    ],
    pop: [
      BoxShadow(color: Color(0x29102A5A), offset: Offset(0, 8), blurRadius: 24),
      BoxShadow(color: Color(0x14102A5A), offset: Offset(0, 2), blurRadius: 6),
    ],
  );

  /// Chỉ các biến mà prototype ghi đè ở chế độ tối được đổi; `acc` và `onAcc`
  /// giữ nguyên như trong HTML.
  static const AppTokens dark = AppTokens(
    brightness: Brightness.dark,
    bg: Color(0xFF0B1220),
    surface: Color(0xFF111B2E),
    subtle: Color(0xFF0E1727),
    hover: Color(0xFF18243B),
    line: Color(0xFF233250),
    line2: Color(0xFF344A70),
    ink: Color(0xFFE6ECF8),
    ink2: Color(0xFFAAB8D1),
    ink3: Color(0xFF8D9CB9),
    navy: Color(0xFF0A1A3A),
    navy2: Color(0xFF16295A),
    onNavy: Color(0xFFA9B9D6),
    navyLine: Color(0x1AFFFFFF),
    pri: Color(0xFF2F6FE4),
    priHover: Color(0xFF3F7DF0),
    priLink: Color(0xFF7FA9F7),
    priSoft: Color(0xFF162A52),
    priLine: Color(0xFF2B4A86),
    onPri: Color(0xFFFFFFFF),
    acc: Color(0xFFF2A900),
    accSoft: Color(0xFF33270B),
    onAcc: Color(0xFF0A1F44),
    ok: Color(0xFF4FD1A0),
    okSoft: Color(0xFF0F2D26),
    okLine: Color(0xFF1D5A47),
    warn: Color(0xFFF2B84B),
    warnSoft: Color(0xFF33270B),
    warnLine: Color(0xFF6B5217),
    bad: Color(0xFFFF8E8E),
    badSoft: Color(0xFF3A1717),
    badLine: Color(0xFF7A2E2E),
    neu: Color(0xFFAAB8D1),
    neuSoft: Color(0xFF1B2842),
    paper: Color(0xFFE9E6D6),
    pen: Color(0xFF1B2A6B),
    paperLine: Color(0xFFCFC9AF),
    focus: Color(0x597FA9F7),
    shadow: [
      BoxShadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x40000000), offset: Offset(0, 4), blurRadius: 12),
    ],
    pop: [
      BoxShadow(color: Color(0x80000000), offset: Offset(0, 8), blurRadius: 24),
    ],
  );

  /// Màu chữ cho tiêu đề: navy ở chế độ sáng, `ink` ở chế độ tối.
  Color get heading => brightness == Brightness.light ? navy : ink;

  @override
  AppTokens copyWith({
    Brightness? brightness,
    Color? bg,
    Color? surface,
    Color? subtle,
    Color? hover,
    Color? line,
    Color? line2,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? navy,
    Color? navy2,
    Color? onNavy,
    Color? navyLine,
    Color? pri,
    Color? priHover,
    Color? priLink,
    Color? priSoft,
    Color? priLine,
    Color? onPri,
    Color? acc,
    Color? accSoft,
    Color? onAcc,
    Color? ok,
    Color? okSoft,
    Color? okLine,
    Color? warn,
    Color? warnSoft,
    Color? warnLine,
    Color? bad,
    Color? badSoft,
    Color? badLine,
    Color? neu,
    Color? neuSoft,
    Color? paper,
    Color? pen,
    Color? paperLine,
    Color? focus,
    List<BoxShadow>? shadow,
    List<BoxShadow>? pop,
  }) => AppTokens(
    brightness: brightness ?? this.brightness,
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    subtle: subtle ?? this.subtle,
    hover: hover ?? this.hover,
    line: line ?? this.line,
    line2: line2 ?? this.line2,
    ink: ink ?? this.ink,
    ink2: ink2 ?? this.ink2,
    ink3: ink3 ?? this.ink3,
    navy: navy ?? this.navy,
    navy2: navy2 ?? this.navy2,
    onNavy: onNavy ?? this.onNavy,
    navyLine: navyLine ?? this.navyLine,
    pri: pri ?? this.pri,
    priHover: priHover ?? this.priHover,
    priLink: priLink ?? this.priLink,
    priSoft: priSoft ?? this.priSoft,
    priLine: priLine ?? this.priLine,
    onPri: onPri ?? this.onPri,
    acc: acc ?? this.acc,
    accSoft: accSoft ?? this.accSoft,
    onAcc: onAcc ?? this.onAcc,
    ok: ok ?? this.ok,
    okSoft: okSoft ?? this.okSoft,
    okLine: okLine ?? this.okLine,
    warn: warn ?? this.warn,
    warnSoft: warnSoft ?? this.warnSoft,
    warnLine: warnLine ?? this.warnLine,
    bad: bad ?? this.bad,
    badSoft: badSoft ?? this.badSoft,
    badLine: badLine ?? this.badLine,
    neu: neu ?? this.neu,
    neuSoft: neuSoft ?? this.neuSoft,
    paper: paper ?? this.paper,
    pen: pen ?? this.pen,
    paperLine: paperLine ?? this.paperLine,
    focus: focus ?? this.focus,
    shadow: shadow ?? this.shadow,
    pop: pop ?? this.pop,
  );

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    List<BoxShadow> s(List<BoxShadow> a, List<BoxShadow> b) =>
        BoxShadow.lerpList(a, b, t)!;
    return AppTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      subtle: c(subtle, other.subtle),
      hover: c(hover, other.hover),
      line: c(line, other.line),
      line2: c(line2, other.line2),
      ink: c(ink, other.ink),
      ink2: c(ink2, other.ink2),
      ink3: c(ink3, other.ink3),
      navy: c(navy, other.navy),
      navy2: c(navy2, other.navy2),
      onNavy: c(onNavy, other.onNavy),
      navyLine: c(navyLine, other.navyLine),
      pri: c(pri, other.pri),
      priHover: c(priHover, other.priHover),
      priLink: c(priLink, other.priLink),
      priSoft: c(priSoft, other.priSoft),
      priLine: c(priLine, other.priLine),
      onPri: c(onPri, other.onPri),
      acc: c(acc, other.acc),
      accSoft: c(accSoft, other.accSoft),
      onAcc: c(onAcc, other.onAcc),
      ok: c(ok, other.ok),
      okSoft: c(okSoft, other.okSoft),
      okLine: c(okLine, other.okLine),
      warn: c(warn, other.warn),
      warnSoft: c(warnSoft, other.warnSoft),
      warnLine: c(warnLine, other.warnLine),
      bad: c(bad, other.bad),
      badSoft: c(badSoft, other.badSoft),
      badLine: c(badLine, other.badLine),
      neu: c(neu, other.neu),
      neuSoft: c(neuSoft, other.neuSoft),
      paper: c(paper, other.paper),
      pen: c(pen, other.pen),
      paperLine: c(paperLine, other.paperLine),
      focus: c(focus, other.focus),
      shadow: s(shadow, other.shadow),
      pop: s(pop, other.pop),
    );
  }
}

extension AppTokensContext on BuildContext {
  /// Token của theme hiện tại; nếu theme không gắn token (ví dụ test dùng
  /// `ThemeData()` thuần) thì suy ra từ độ sáng.
  AppTokens get tokens {
    final theme = Theme.of(this);
    return theme.extension<AppTokens>() ??
        (theme.brightness == Brightness.dark
            ? AppTokens.dark
            : AppTokens.light);
  }
}
