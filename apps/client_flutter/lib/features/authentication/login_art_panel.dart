import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';

/// Nửa trái nền navy của màn đăng nhập (chỉ hiện từ 960): thương hiệu, mockup
/// "từ giấy viết tay sang số hóa", tiêu đề và 3 ý tính năng. Toàn bộ là nội dung
/// trang trí, không có chức năng và không ảnh hưởng luồng đăng nhập.
///
/// [horizontalMockup] do màn đăng nhập tính từ chiều rộng nửa trái (nội dung
/// >= 560 thì xếp ngang giấy | vạch quét | thẻ, hẹp hơn thì xếp dọc). Không dùng
/// `LayoutBuilder` ở đây vì panel nằm trong `IntrinsicHeight`.
class LoginArtPanel extends StatelessWidget {
  const LoginArtPanel({super.key, required this.horizontalMockup});

  final bool horizontalMockup;

  /// Nội dung nửa trái rộng tối thiểu bao nhiêu thì xếp ngang.
  static const horizontalMinWidth = 560.0;

  /// Lề ngang của nửa trái (36 mỗi bên).
  static const horizontalPadding = 72.0;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Container(
      color: t.navy,
      padding: const EdgeInsets.all(36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: t.onPri.withAlpha(36),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.school_rounded, size: 22, color: t.onPri),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EduScore',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: t.onPri,
                      ),
                    ),
                    Text(
                      'Trường THPT Bà Điểm · Quản lý điểm',
                      style: TextStyle(fontSize: 13, color: t.onNavy),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.xxl),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: _OcrMockup(horizontal: horizontalMockup),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const Spacer(),
          // Không bọc `ConstrainedBox(maxWidth)` quanh chữ xuống dòng: màn đăng
          // nhập dùng `IntrinsicHeight` mà `ConstrainedBox` không giới hạn bề
          // rộng khi tính chiều cao nội tại, sẽ làm panel bị tràn đáy.
          Text(
            'Nhập điểm nhanh hơn, đối chiếu rõ ràng hơn.',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 34,
              height: 44 / 34,
              color: t.onPri,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _Feature(
            icon: Icons.photo_camera_outlined,
            title: 'Chụp bảng điểm viết tay',
            body:
                'Hệ thống đọc điểm số và điểm chữ, giáo viên chỉ cần xem lại.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Feature(
            icon: Icons.checklist_rounded,
            title: 'Đối chiếu trước khi duyệt',
            body:
                'Ô nào chắc chắn hiện màu Xanh, ô cần xem lại hiện Vàng hoặc Đỏ.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Feature(
            icon: Icons.history_rounded,
            title: 'Lưu lịch sử mọi thay đổi',
            body: 'Biết ai sửa điểm nào, khi nào, từ giá trị nào.',
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: t.onPri.withAlpha(31),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: t.acc),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: t.onPri,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 20 / 13.5,
                  color: t.onNavy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mockup "Từ giấy viết tay sang số hóa"
// ---------------------------------------------------------------------------

/// Dữ liệu minh họa (không phải dữ liệu thật). Điểm số luôn một chữ số thập
/// phân, điểm chữ đọc từng chữ số, không có từ "phẩy".
const _sample = [
  _SampleRow('1', 'Nguyễn Văn An', '8.5', 'tám năm', false),
  _SampleRow('2', 'Trần Thị Bích', '7.0', 'bảy không', true),
  _SampleRow('3', 'Lê Hoàng Cường', '6.5', 'sáu năm', false),
];

class _SampleRow {
  const _SampleRow(this.stt, this.name, this.score, this.words, this.recheck);
  final String stt;
  final String name;
  final String score;
  final String words;

  /// Dòng cần giáo viên xem lại (huy hiệu Vàng) thay vì Khớp (Xanh).
  final bool recheck;
}

/// Mốc thời gian của một chu kỳ (0..1). Vạch quét xiên nhẹ nên dòng ở dưới bị
/// quét sau dòng ở trên; dòng ở thẻ phải hiện đúng lúc vạch quét qua cột điểm.
abstract final class _Timeline {
  static const beamEnd = 0.85;
  static const beamFrom = -0.2;
  static const beamTo = 1.2;
  static const scoreColumn = 0.55;
  static const slope = 0.3; // độ lệch ngang của vạch quét theo chiều cao giấy
  static const rowCenters = [0.42, 0.62, 0.82]; // tâm dòng / chiều cao giấy

  static double beamU(double p) =>
      beamFrom + (beamTo - beamFrom) * (p / beamEnd).clamp(0.0, 1.0).toDouble();

  static double crossing(int row) =>
      beamEnd *
      ((scoreColumn + slope * rowCenters[row]) - beamFrom) /
      (beamTo - beamFrom);

  static double beamOpacity(double p) {
    if (p >= 1) return 0;
    final fadeIn = (p / 0.04).clamp(0.0, 1.0).toDouble();
    final fadeOut = ((beamEnd - p) / 0.07).clamp(0.0, 1.0).toDouble();
    return math.min(fadeIn, fadeOut);
  }

  static double stage(double p, double start, double duration) =>
      ((p - start) / duration).clamp(0.0, 1.0).toDouble();
}

/// Mockup động. Điều khiển hoạt ảnh nằm trọn trong widget này nên form đăng
/// nhập không bị dựng lại. Chạy 2 chu kỳ rồi dừng ở trạng thái hoàn chỉnh;
/// bấm hoặc rê chuột vào thì chạy lại một chu kỳ.
class _OcrMockup extends StatefulWidget {
  const _OcrMockup({required this.horizontal});

  final bool horizontal;

  @override
  State<_OcrMockup> createState() => _OcrMockupState();
}

class _OcrMockupState extends State<_OcrMockup>
    with SingleTickerProviderStateMixin {
  static const _cycle = Duration(milliseconds: 3500);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _cycle,
  );
  int _extraRuns = 1;
  bool _started = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _extraRuns > 0) {
        _extraRuns--;
        _controller.forward(from: 0);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      // Đặt value=1 kích hoạt trạng thái completed: phải bỏ lượt chạy thêm.
      _extraRuns = 0;
      _controller
        ..stop()
        ..value = 1;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replay() {
    if (_reduceMotion) return;
    _extraRuns = 0;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: MouseRegion(
        onEnter: (_) {
          if (!_controller.isAnimating) _replay();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _replay,
          child: AnimatedBuilder(
            animation: _controller,
            // Nội dung giấy không đổi theo thời gian: dựng một lần.
            child: const _PaperSheet(),
            builder: (context, sheet) {
              final horizontal = widget.horizontal;
              final p = _controller.value;
              final paper = _PaperFrame(
                beamU: _Timeline.beamU(p),
                beamOpacity: _Timeline.beamOpacity(p),
                child: sheet!,
              );
              final card = _DigitizedCard(progress: p);
              final connector = _ScanConnector(
                vertical: !horizontal,
                active: p > 0 && p < _Timeline.beamEnd,
              );
              if (horizontal) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 12, child: paper),
                    SizedBox(width: 60, child: connector),
                    Expanded(flex: 10, child: card),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [paper, connector, card],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Khung tờ giấy: nghiêng -1,2 độ, bo góc, đổ bóng, cắt vạch quét theo giấy.
class _PaperFrame extends StatelessWidget {
  const _PaperFrame({
    required this.beamU,
    required this.beamOpacity,
    required this.child,
  });

  final double beamU;
  final double beamOpacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Transform.rotate(
      angle: -1.2 * math.pi / 180,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.paper,
          borderRadius: BorderRadius.circular(10),
          boxShadow: t.pop,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              child,
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _BeamPainter(
                      u: beamU,
                      opacity: beamOpacity,
                      color: t.pri,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nội dung tờ giấy kẻ ô: tiêu đề in, 3 dòng chữ viết tay (nét mực `t.pen`).
class _PaperSheet extends StatelessWidget {
  const _PaperSheet();

  static const _cell = 16.0;
  static const _rowHeight = 2 * _cell;

  // Góc nghiêng nhẹ cố định theo từng dòng (~±0.6° - 0.8°) tạo nét viết tay tự nhiên.
  static const _rowRotations = [-0.012, 0.014, -0.010];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final printed = TextStyle(fontSize: 11.5, color: t.onAcc);
    final hand = TextStyle(
      fontFamily: 'Handwriting',
      fontSize: 18,
      height: 1.1,
      color: t.pen,
    );
    return CustomPaint(
      painter: _GridPainter(color: t.paperLine, cell: _cell),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, _cell, 12, _cell),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _rowHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'DANH SÁCH GHI ĐIỂM',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: printed.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            for (var i = 0; i < _sample.length; i++)
              () {
                final r = _sample[i];
                final rot = _rowRotations[i % _rowRotations.length];
                return SizedBox(
                  height: _rowHeight,
                  child: Row(
                    children: [
                      SizedBox(width: 14, child: Text(r.stt, style: printed)),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        flex: 10,
                        child: Text(
                          r.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: printed,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Transform.rotate(
                        angle: rot,
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 38,
                          child: Text(
                            r.score,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: hand.copyWith(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        flex: 9,
                        child: Transform.rotate(
                          angle: rot,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            r.words,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: hand,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }(),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.color, required this.cell});
  final Color color;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8;
    for (var x = 0.0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.color != color || old.cell != cell;
}

/// Vạch quét xanh xiên nhẹ kèm quầng sáng. [u] là vị trí ngang (theo tỉ lệ
/// chiều rộng giấy) của đầu trên vạch.
class _BeamPainter extends CustomPainter {
  const _BeamPainter({
    required this.u,
    required this.opacity,
    required this.color,
  });

  final double u;
  final double opacity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || size.isEmpty) return;
    canvas.save();
    canvas.translate(u * size.width, 0);
    // Đầu dưới của vạch lệch trái: dòng ở dưới được quét sau dòng ở trên.
    canvas.transform(
      (Matrix4.identity()
            ..setEntry(0, 1, -_Timeline.slope * size.width / size.height))
          .storage,
    );
    const glow = 44.0;
    final glowRect = Rect.fromLTWH(-glow / 2, -4, glow, size.height + 8);
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            color.withAlpha(0),
            color.withAlpha((110 * opacity).round()),
            color.withAlpha(0),
          ],
        ).createShader(glowRect),
    );
    canvas.drawRect(
      Rect.fromLTWH(-1, -4, 2, size.height + 8),
      Paint()..color = color.withAlpha((255 * opacity).round()),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BeamPainter old) =>
      old.u != u || old.opacity != opacity || old.color != color;
}

/// Nhãn "AI OCR" giữa tờ giấy và thẻ kết quả; mũi tên đổi hướng xuống khi hẹp.
class _ScanConnector extends StatelessWidget {
  const _ScanConnector({required this.vertical, required this.active});

  final bool vertical;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final badge = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.onPri.withAlpha(active ? 52 : 31),
        border: Border.all(color: active ? t.acc : t.navyLine),
      ),
      child: Icon(Icons.auto_awesome_rounded, size: 18, color: t.acc),
    );
    final label = Text(
      'AI OCR',
      maxLines: 1,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: t.onPri,
      ),
    );
    final arrow = Icon(
      vertical ? Icons.arrow_downward_rounded : Icons.arrow_forward_rounded,
      size: 18,
      color: t.onNavy,
    );
    if (vertical) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            arrow,
            const SizedBox(width: AppSpacing.sm),
            badge,
            const SizedBox(width: AppSpacing.sm),
            label,
            const SizedBox(width: AppSpacing.sm),
            arrow,
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(height: AppSpacing.xs),
        label,
        const SizedBox(height: AppSpacing.xs),
        arrow,
      ],
    );
  }
}

/// Thẻ giao diện bảng điểm đã số hóa. Mỗi dòng hiện (mờ dần + trượt nhẹ) khi
/// vạch quét qua dòng tương ứng, sau đó huy hiệu bật lên.
class _DigitizedCard extends StatelessWidget {
  const _DigitizedCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: t.line),
        boxShadow: t.pop,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.task_alt_rounded, size: 16, color: t.ok),
                const SizedBox(width: AppSpacing.xs + 2),
                Expanded(
                  child: Text(
                    'Đã số hóa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: t.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            for (var i = 0; i < _sample.length; i++) ...[
              Divider(height: AppSpacing.md, color: t.line),
              _DigitizedRow(
                row: _sample[i],
                reveal: _Timeline.stage(progress, _Timeline.crossing(i), 0.1),
                pop: _Timeline.stage(
                  progress,
                  _Timeline.crossing(i) + 0.08,
                  0.1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DigitizedRow extends StatelessWidget {
  const _DigitizedRow({
    required this.row,
    required this.reveal,
    required this.pop,
  });

  final _SampleRow row;
  final double reveal;
  final double pop;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scale = Curves.easeOutBack.transform(pop);
    return Opacity(
      opacity: Curves.easeOut.transform(reveal),
      child: Transform.translate(
        offset: Offset(14 * (1 - reveal), 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: t.ink2),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          row.score,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: t.ink2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.arrow_right_alt_rounded,
                            size: 18,
                            color: t.ink3,
                          ),
                        ),
                        Text(
                          row.score,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: t.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Opacity(
                  opacity: pop,
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.centerRight,
                    child: row.recheck
                        ? const AppBadge.warn('Kiểm tra lại')
                        : const AppBadge.ok('Khớp'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
