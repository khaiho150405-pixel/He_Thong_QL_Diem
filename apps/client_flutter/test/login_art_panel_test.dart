import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/theme_mode.dart';
import 'package:client_flutter/app/widgets/app_badge.dart';
import 'package:client_flutter/features/authentication/login_art_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpLogin(
  WidgetTester tester,
  Size size, {
  ThemeMode mode = ThemeMode.light,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [themeModeProvider.overrideWith((ref) => mode)],
      child: const GradebookApp(initialLocation: '/login'),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

double opacityOf(WidgetTester tester, String text) => tester
    .widget<Opacity>(
      find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first,
    )
    .opacity;

void main() {
  const sizes = <Size>[
    Size(960, 600),
    Size(960, 700),
    Size(1280, 720),
    Size(1280, 800),
    Size(1440, 900),
    Size(1920, 1080),
  ];

  for (final size in sizes) {
    testWidgets('dựng được, không overflow ở ${size.width.toInt()}x'
        '${size.height.toInt()}', (tester) async {
      await pumpLogin(tester, size);

      expect(tester.takeException(), isNull);
      expect(find.byType(LoginArtPanel), findsOneWidget);
      expect(find.text('EduScore'), findsOneWidget);
      expect(find.text('Trường THPT Bà Điểm · Quản lý điểm'), findsOneWidget);
      expect(
        find.text('Nhập điểm nhanh hơn, đối chiếu rõ ràng hơn.'),
        findsOneWidget,
      );
      // Thẻ xem trước cũ dạng Positioned đã được thay bằng mockup trong luồng.
      expect(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_OcrPreviewCard',
        ),
        findsNothing,
      );
      expect(
        find.byType(Positioned),
        findsWidgets,
      ); // nút đổi theme, giữ nguyên
      final panel = tester.getRect(find.byType(LoginArtPanel));
      for (final key in ['Đã số hóa', 'Kiểm tra lại', 'AI OCR']) {
        final r = tester.getRect(find.text(key));
        expect(panel.contains(r.topLeft), isTrue, reason: key);
        expect(panel.contains(r.bottomRight), isTrue, reason: key);
      }
    });
  }

  testWidgets('mockup có 7.0, Khớp, Kiểm tra lại và không có "phẩy"', (
    tester,
  ) async {
    await pumpLogin(tester, const Size(1280, 800));

    expect(find.text('7.0'), findsWidgets);
    expect(find.text('8.5'), findsWidgets);
    expect(find.text('6.5'), findsWidgets);
    expect(find.text('Khớp'), findsWidgets);
    expect(find.text('Kiểm tra lại'), findsOneWidget);
    expect(find.text('Đã số hóa'), findsOneWidget);
    expect(find.text('tám năm'), findsOneWidget);
    expect(find.text('bảy không'), findsOneWidget);
    expect(find.text('sáu năm'), findsOneWidget);
    expect(find.textContaining('phẩy'), findsNothing);
    expect(find.byType(AppBadge), findsNWidgets(3));
  });

  testWidgets('hoạt ảnh tự dừng sau 2 chu kỳ ở trạng thái hoàn chỉnh', (
    tester,
  ) async {
    await pumpLogin(tester, const Size(1280, 800), settle: false);
    // Khung đầu: dòng kết quả chưa hiện.
    expect(opacityOf(tester, 'Kiểm tra lại'), 0);

    await tester.pumpAndSettle(); // không treo => đã dừng
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(opacityOf(tester, 'Kiểm tra lại'), 1);
    expect(opacityOf(tester, 'Khớp'), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bấm vào mockup chạy lại hoạt ảnh một lần rồi dừng', (
    tester,
  ) async {
    await pumpLogin(tester, const Size(1280, 800));
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.tap(find.text('Đã số hóa'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacityOf(tester, 'Kiểm tra lại'), 0);
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pumpAndSettle();
    expect(opacityOf(tester, 'Kiểm tra lại'), 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('giảm chuyển động: hiện thẳng trạng thái hoàn chỉnh', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await pumpLogin(tester, const Size(1280, 800), settle: false);

    expect(opacityOf(tester, 'Kiểm tra lại'), 1);
    expect(opacityOf(tester, 'Khớp'), 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('mockup chỉ là trang trí: không có semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpLogin(tester, const Size(1280, 800));

    expect(find.bySemanticsLabel('Kiểm tra lại'), findsNothing);
    expect(find.bySemanticsLabel('Đã số hóa'), findsNothing);
    handle.dispose();
  });

  for (final size in [const Size(960, 700), const Size(1280, 800)]) {
    testWidgets('chế độ tối ${size.width.toInt()}px', (tester) async {
      await pumpLogin(tester, size, mode: ThemeMode.dark);

      expect(tester.takeException(), isNull);
      final tokens = Theme.of(
        tester.element(find.byType(LoginArtPanel)),
      ).extension<AppTokens>()!;
      expect(tokens.brightness, Brightness.dark);
      expect(find.text('Khớp'), findsWidgets);
      expect(find.text('Kiểm tra lại'), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  }
}
