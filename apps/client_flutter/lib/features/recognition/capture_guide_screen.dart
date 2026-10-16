import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/design_tokens.dart';
import '../../app/theme.dart';

/// Màn "chuẩn bị chụp" luôn tối, đặt trước bước chụp ảnh bảng điểm.
///
/// `image_picker` mở ứng dụng camera của hệ điều hành nên khung 4 góc ở đây chỉ
/// là hình minh họa cách căn tờ giấy, KHÔNG phải lớp phủ trên khung ngắm thật.
/// Màn không tự chọn ảnh và không gọi API: nút chụp và nút thư viện gọi lại
/// hàm chọn ảnh có sẵn của panel nhận dạng. Callback trả `true` khi đã có ảnh
/// (hoặc thông báo lỗi) để panel hiển thị; khi đó màn tự đóng. Trả `false`
/// (người dùng hủy) thì màn ở lại.
class CaptureGuideScreen extends StatefulWidget {
  const CaptureGuideScreen({
    super.key,
    required this.onCapture,
    required this.onPickFromLibrary,
    this.classSubjectLabel,
    this.componentLabel,
    this.enabled = true,
  });

  /// Ví dụ `10A1 · Toán`, lấy từ dữ liệu bảng điểm.
  final String? classSubjectLabel;

  /// Tên cột điểm đang chọn, ví dụ `Giữa kỳ`; `null` khi chưa chọn.
  final String? componentLabel;

  /// `false` khi panel không cho gửi ảnh (bảng đã khóa, chưa có cột điểm...).
  final bool enabled;

  final Future<bool> Function() onCapture;
  final Future<bool> Function() onPickFromLibrary;

  /// Nhãn pill: ghép các phần có giá trị bằng " · ".
  static String? buildLabel(String? classSubject, String? component) {
    final parts = [
      for (final part in [classSubject, component])
        if (part != null && part.trim().isNotEmpty) part.trim(),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  State<CaptureGuideScreen> createState() => _CaptureGuideScreenState();
}

class _CaptureGuideScreenState extends State<CaptureGuideScreen> {
  bool _busy = false;

  Future<void> _run(Future<bool> Function() action) async {
    if (_busy || !widget.enabled) return;
    setState(() => _busy = true);
    var done = false;
    try {
      done = await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (done && mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    // Luôn tối, bất kể chế độ sáng/tối của hệ thống.
    return Theme(
      data: AppTheme.dark(),
      child: Builder(
        builder: (context) {
          final t = context.tokens;
          final active = widget.enabled && !_busy;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Scaffold(
              key: const ValueKey('capture-guide'),
              backgroundColor: t.bg,
              body: SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(context, t),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final viewHeight = math.min(
                            420.0,
                            math.max(220.0, constraints.maxHeight * 0.45),
                          );
                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildFrame(context, t, viewHeight),
                                const SizedBox(height: AppSpacing.md),
                                _buildNote(context, t),
                                const SizedBox(height: AppSpacing.md),
                                _buildTips(context, t),
                                if (!widget.enabled) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  _buildDisabledNotice(context, t),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    _buildBottomBar(context, t, active),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppTokens t) {
    final label = CaptureGuideScreen.buildLabel(
      widget.classSubjectLabel,
      widget.componentLabel,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              key: const ValueKey('capture-guide-close'),
              tooltip: 'Đóng',
              icon: Icon(Icons.close, color: t.ink),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: label == null
                ? const SizedBox.shrink()
                : Center(
                    child: DecoratedBox(
                      key: const ValueKey('capture-guide-pill'),
                      decoration: BoxDecoration(
                        color: t.ink.withAlpha(36),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: t.ink,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
                  ),
          ),
          // Cân đối với nút đóng; prototype có nút flash nhưng image_picker
          // không hỗ trợ nên không làm.
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildFrame(BuildContext context, AppTokens t, double height) {
    return ExcludeSemantics(
      child: SizedBox(
        key: const ValueKey('capture-guide-view'),
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.hover,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 44,
                      vertical: 32,
                    ),
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.026,
                        child: _PaperSketch(tokens: t),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 26,
                    ),
                    child: Stack(
                      children: [for (var i = 0; i < 4; i++) _corner(t, i)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Góc khung vàng: 0 trên-trái, 1 trên-phải, 2 dưới-trái, 3 dưới-phải.
  Widget _corner(AppTokens t, int index) {
    final top = index < 2;
    final left = index.isEven;
    final side = BorderSide(color: t.acc, width: 3);
    const radius = Radius.circular(8);
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: DecoratedBox(
        key: ValueKey('capture-guide-corner-$index'),
        decoration: BoxDecoration(
          border: Border(
            top: top ? side : BorderSide.none,
            bottom: top ? BorderSide.none : side,
            left: left ? side : BorderSide.none,
            right: left ? BorderSide.none : side,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? radius : Radius.zero,
            topRight: top && !left ? radius : Radius.zero,
            bottomLeft: !top && left ? radius : Radius.zero,
            bottomRight: !top && !left ? radius : Radius.zero,
          ),
        ),
        child: const SizedBox(width: 30, height: 30),
      ),
    );
  }

  Widget _buildNote(BuildContext context, AppTokens t) {
    // image_picker mở camera của hệ điều hành: không hứa có khung trên đó.
    final text = kIsWeb
        ? 'Hình minh họa cách căn tờ giấy. Trên trình duyệt, nút chụp mở hộp chọn tệp của trình duyệt.'
        : 'Hình minh họa cách căn tờ giấy. Khi bấm chụp, ứng dụng camera của máy sẽ mở; khung này không hiện trên màn camera đó.';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.info_outline, size: 16, color: t.ink3),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            key: const ValueKey('capture-guide-note'),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: t.ink2),
          ),
        ),
      ],
    );
  }

  Widget _buildTips(BuildContext context, AppTokens t) {
    const tips = [
      'Lấy đủ khung bảng, đặt máy thẳng',
      'Đủ sáng, tránh bóng và ánh phản chiếu',
      'Rõ các cột Họ tên, Điểm số, Điểm chữ',
    ];
    return DecoratedBox(
      key: const ValueKey('capture-guide-tips'),
      decoration: BoxDecoration(
        color: t.okSoft,
        border: Border.all(color: t.okLine),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < tips.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_rounded, size: 16, color: t.ok),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      tips[i],
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: t.ok),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledNotice(BuildContext context, AppTokens t) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.warnSoft,
        border: Border.all(color: t.warnLine),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline_rounded, size: 18, color: t.warn),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Hiện chưa gửi được ảnh cho bảng điểm này. Kiểm tra cột điểm đang mở nhập hoặc trạng thái bảng điểm.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: t.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, AppTokens t, bool active) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: Tooltip(
                  message: 'Chọn từ thư viện',
                  child: Material(
                    color: t.ink.withAlpha(26),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: t.ink.withAlpha(77)),
                    ),
                    child: InkWell(
                      key: const ValueKey('capture-guide-gallery'),
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: active
                          ? () => _run(widget.onPickFromLibrary)
                          : null,
                      child: Semantics(
                        button: true,
                        label: 'Chọn từ thư viện',
                        child: Center(
                          child: Icon(
                            Icons.photo_library_outlined,
                            color: active ? t.ink : t.ink3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            enabled: active,
            label: 'Chụp bảng điểm',
            child: ExcludeSemantics(
              child: InkResponse(
                key: const ValueKey('capture-guide-shutter'),
                onTap: active ? () => _run(widget.onCapture) : null,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? t.ink : t.ink3,
                        width: 4,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? t.ink : t.ink3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Prototype có "Trang 1/2"; mỗi phiếu chỉ một ảnh nên không làm.
          const SizedBox(width: 72, height: 72),
        ],
      ),
    );
  }
}

/// Hình tờ giấy minh họa (không phải dữ liệu thật): chỉ có các thanh xám và
/// tên cột. Cố định cỡ chữ để không tràn trong khung minh họa.
class _PaperSketch extends StatelessWidget {
  const _PaperSketch({required this.tokens});

  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return MediaQuery.withNoTextScaling(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.paper,
          borderRadius: BorderRadius.circular(4),
          boxShadow: t.pop,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const SizedBox(width: 18),
                  Expanded(flex: 3, child: _head('Họ tên')),
                  Expanded(flex: 2, child: _head('Điểm số')),
                  Expanded(flex: 3, child: _head('Điểm chữ')),
                ],
              ),
              for (var i = 0; i < 6; i++)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: t.paperLine)),
                  ),
                  child: Row(
                    children: [
                      _bar(t, 10),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: _bar(t, null)),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: _bar(t, null)),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: _bar(t, null)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _head(String text) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.clip,
    style: TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      color: tokens.pen,
    ),
  );

  Widget _bar(AppTokens t, double? width) => SizedBox(
    width: width,
    height: 5,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: t.pen.withAlpha(64),
        borderRadius: BorderRadius.circular(3),
      ),
    ),
  );
}
