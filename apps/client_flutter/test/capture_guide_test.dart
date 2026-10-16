import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/recognition/capture_guide_screen.dart';
import 'package:client_flutter/features/recognition/image_picker.dart';
import 'package:client_flutter/features/recognition/recognition_panel.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'phase3_recognition_test.dart'
    show FakeRecognitionPicker, RecognitionFakeServer;

class _CameraPicker extends FakeRecognitionPicker
    implements RecognitionCameraPicker {
  int captures = 0;
  int picks = 0;
  bool cancelled = false;

  @override
  Future<RecognitionImage?> capture() async {
    captures++;
    return cancelled ? null : super.pick();
  }

  @override
  Future<RecognitionImage?> recover() async => null;

  @override
  Future<RecognitionImage?> pick() async {
    picks++;
    return cancelled ? null : super.pick();
  }
}

void _useView(WidgetTester tester, Size size, double scale) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _pumpGuide(
  WidgetTester tester, {
  required bool darkSystem,
  Future<bool> Function()? onCapture,
  Future<bool> Function()? onPick,
  bool enabled = true,
  String? classSubject = '10A1 · Toán',
  String? component = 'Giữa kỳ',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: darkSystem ? AppTheme.dark() : AppTheme.light(),
      home: CaptureGuideScreen(
        classSubjectLabel: classSubject,
        componentLabel: component,
        enabled: enabled,
        onCapture: onCapture ?? () async => false,
        onPickFromLibrary: onPick ?? () async => false,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final darkSystem in [false, true]) {
    for (final width in [320.0, 390.0, 800.0]) {
      testWidgets('màn hướng dẫn chụp luôn tối, ${width.toInt()} px, '
          'hệ thống ${darkSystem ? 'tối' : 'sáng'}, chữ 1,3x, không tràn', (
        tester,
      ) async {
        _useView(tester, Size(width, 640), 1.3);
        await _pumpGuide(tester, darkSystem: darkSystem);
        expect(tester.takeException(), isNull);

        final dark = AppTokens.dark;
        final scaffold = tester.widget<Scaffold>(
          find.byKey(const ValueKey('capture-guide')),
        );
        expect(scaffold.backgroundColor, dark.bg);
        expect(
          Theme.of(
            tester.element(find.byKey(const ValueKey('capture-guide'))),
          ).brightness,
          Brightness.dark,
        );

        // Pill đúng nhãn.
        expect(find.text('10A1 · Toán · Giữa kỳ'), findsOneWidget);
        // Nút đóng, chụp, thư viện đủ cỡ chạm.
        expect(find.byTooltip('Đóng'), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const ValueKey('capture-guide-close'))),
          const Size(48, 48),
        );
        expect(
          tester
              .getSize(find.byKey(const ValueKey('capture-guide-shutter')))
              .height,
          72,
        );
        expect(
          tester
              .getSize(find.byKey(const ValueKey('capture-guide-gallery')))
              .shortestSide,
          greaterThanOrEqualTo(48),
        );
        // Mẹo lấy từ hướng dẫn chụp có sẵn.
        expect(find.textContaining('Họ tên, Điểm số, Điểm chữ'), findsWidgets);
        // Ghi chú không hứa khung trên camera thật.
        expect(
          find.textContaining('không hiện trên màn camera'),
          findsOneWidget,
        );
        // Không có "Trang 1/2" hay flash.
        expect(find.textContaining('Trang 1'), findsNothing);
        expect(find.byIcon(Icons.flash_on), findsNothing);
        expect(find.byIcon(Icons.flash_off), findsNothing);
      });
    }
  }

  testWidgets('có đủ 4 góc khung dùng tokens.acc', (tester) async {
    _useView(tester, const Size(390, 800), 1.0);
    await _pumpGuide(tester, darkSystem: false);
    var solidSides = 0;
    for (var i = 0; i < 4; i++) {
      final box = tester.widget<DecoratedBox>(
        find.byKey(ValueKey('capture-guide-corner-$i')),
      );
      final border = (box.decoration as BoxDecoration).border! as Border;
      final sides = [
        border.top,
        border.bottom,
        border.left,
        border.right,
      ].where((s) => s.style == BorderStyle.solid && s.width > 0).toList();
      expect(sides, hasLength(2), reason: 'góc $i có hai cạnh');
      for (final side in sides) {
        expect(side.color, AppTokens.dark.acc);
      }
      solidSides += sides.length;
    }
    expect(solidSides, 8);
    // Bốn góc nằm ở bốn phía khác nhau của khung.
    final view = tester.getRect(
      find.byKey(const ValueKey('capture-guide-view')),
    );
    Rect corner(int i) =>
        tester.getRect(find.byKey(ValueKey('capture-guide-corner-$i')));
    expect(corner(0).center.dx, lessThan(view.center.dx));
    expect(corner(0).center.dy, lessThan(view.center.dy));
    expect(corner(1).center.dx, greaterThan(view.center.dx));
    expect(corner(1).center.dy, lessThan(view.center.dy));
    expect(corner(2).center.dx, lessThan(view.center.dx));
    expect(corner(2).center.dy, greaterThan(view.center.dy));
    expect(corner(3).center.dx, greaterThan(view.center.dx));
    expect(corner(3).center.dy, greaterThan(view.center.dy));
  });

  testWidgets('nút chụp và nút thư viện gọi đúng callback', (tester) async {
    _useView(tester, const Size(390, 800), 1.0);
    var captures = 0;
    var picks = 0;
    await _pumpGuide(
      tester,
      darkSystem: true,
      onCapture: () async {
        captures++;
        return false;
      },
      onPick: () async {
        picks++;
        return false;
      },
    );
    await tester.tap(find.byKey(const ValueKey('capture-guide-shutter')));
    await tester.pump();
    expect((captures, picks), (1, 0));
    await tester.tap(find.byKey(const ValueKey('capture-guide-gallery')));
    await tester.pump();
    expect((captures, picks), (1, 1));
    // Callback trả false (hủy): màn ở lại.
    expect(find.byKey(const ValueKey('capture-guide')), findsOneWidget);
  });

  testWidgets('callback trả true thì màn tự đóng; nút đóng thoát màn', (
    tester,
  ) async {
    _useView(tester, const Size(390, 800), 1.0);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => CaptureGuideScreen(
                  onCapture: () async => true,
                  onPickFromLibrary: () async => false,
                ),
              ),
            ),
            child: const Text('mở'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('capture-guide')), findsOneWidget);
    // Không có nhãn thì không có pill.
    expect(find.byKey(const ValueKey('capture-guide-pill')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('capture-guide-shutter')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('capture-guide')), findsNothing);

    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('capture-guide')), findsNothing);
  });

  testWidgets('khi không được phép gửi ảnh, nút chụp bị khóa', (tester) async {
    _useView(tester, const Size(390, 800), 1.0);
    var captures = 0;
    await _pumpGuide(
      tester,
      darkSystem: false,
      enabled: false,
      onCapture: () async {
        captures++;
        return true;
      },
    );
    await tester.tap(
      find.byKey(const ValueKey('capture-guide-shutter')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(captures, 0);
    expect(find.textContaining('chưa gửi được ảnh'), findsOneWidget);
  });

  test('buildLabel ghép các phần có giá trị', () {
    expect(
      CaptureGuideScreen.buildLabel('10A1 · Toán', 'Giữa kỳ'),
      '10A1 · Toán · Giữa kỳ',
    );
    expect(CaptureGuideScreen.buildLabel('10A1 · Toán', null), '10A1 · Toán');
    expect(CaptureGuideScreen.buildLabel(null, ' '), isNull);
  });

  Future<_CameraPicker> pumpPanel(
    WidgetTester tester,
    TargetPlatform platform,
    Size size,
  ) async {
    debugDefaultTargetPlatformOverride = platform;
    _useView(tester, size, 1.0);
    final picker = _CameraPicker();
    final api = ApiClientDart(
      dio: Dio()..httpClientAdapter = RecognitionFakeServer(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiProvider.overrideWithValue(api),
          recognitionImagePickerProvider.overrideWithValue(picker),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RecognitionPanel(
                gradebookId: 7,
                components: const [RecognitionComponentOption(201, 'Giữa kỳ')],
                gradebookVersion: 1,
                enabled: true,
                embedded: true,
                classSubjectLabel: '10A1 · Toán',
                onApproved: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return picker;
  }

  testWidgets('panel trên điện thoại hẹp: nút phụ mở màn, chụp xong quay về '
      'xem trước', (tester) async {
    final picker = await pumpPanel(
      tester,
      TargetPlatform.android,
      const Size(390, 1400),
    );
    // 'Chụp bảng điểm' vẫn có mặt và gọi camera ngay như cũ.
    expect(find.byKey(const ValueKey('recognition-camera')), findsOneWidget);
    final guideButton = find.byKey(const ValueKey('recognition-capture-guide'));
    expect(guideButton, findsOneWidget);
    expect(find.text('Hướng dẫn chụp'), findsOneWidget);

    await tester.ensureVisible(guideButton);
    await tester.tap(guideButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('capture-guide')), findsOneWidget);
    expect(find.text('10A1 · Toán · Giữa kỳ'), findsOneWidget);
    expect(picker.captures, 0);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('capture-guide-shutter')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(picker.captures, 1);
    expect(find.byKey(const ValueKey('capture-guide')), findsNothing);
    expect(find.byKey(const ValueKey('recognition-filename')), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('nút thư viện của màn gọi hàm chọn ảnh có sẵn', (tester) async {
    final picker = await pumpPanel(
      tester,
      TargetPlatform.iOS,
      const Size(390, 1400),
    );
    final guideButton = find.byKey(const ValueKey('recognition-capture-guide'));
    await tester.ensureVisible(guideButton);
    await tester.tap(guideButton);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('capture-guide-gallery')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(picker.picks, 1);
    expect(picker.captures, 0);
    expect(find.byKey(const ValueKey('capture-guide')), findsNothing);
    expect(find.byKey(const ValueKey('recognition-filename')), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('hủy chụp thì màn ở lại, chưa có ảnh', (tester) async {
    final picker = await pumpPanel(
      tester,
      TargetPlatform.android,
      const Size(390, 1400),
    );
    picker.cancelled = true;
    final guideButton = find.byKey(const ValueKey('recognition-capture-guide'));
    await tester.ensureVisible(guideButton);
    await tester.tap(guideButton);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('capture-guide-shutter')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(picker.captures, 1);
    expect(find.byKey(const ValueKey('capture-guide')), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('máy tính hoặc màn rộng không có nút Hướng dẫn chụp', (
    tester,
  ) async {
    await pumpPanel(tester, TargetPlatform.windows, const Size(1280, 900));
    expect(
      find.byKey(const ValueKey('recognition-capture-guide')),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpPanel(tester, TargetPlatform.android, const Size(800, 900));
    expect(
      find.byKey(const ValueKey('recognition-capture-guide')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('recognition-camera')), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
