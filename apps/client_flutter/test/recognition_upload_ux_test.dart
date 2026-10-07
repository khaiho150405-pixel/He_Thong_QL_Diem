import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/recognition/image_picker.dart';
import 'package:client_flutter/features/recognition/image_preview.dart';
import 'package:client_flutter/features/recognition/recognition_panel.dart';
import 'package:client_flutter/app/widgets/app_controls.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'phase3_recognition_test.dart'
    show FakeRecognitionPicker, RecognitionFakeServer;

class CameraPicker extends FakeRecognitionPicker
    implements RecognitionCameraPicker {
  bool cancelled = false;
  bool invalid = false;
  int captures = 0;
  @override
  Future<RecognitionImage?> capture() async {
    captures++;
    return pick();
  }

  @override
  Future<RecognitionImage?> recover() async => null;
  @override
  Future<RecognitionImage?> pick() async => cancelled
      ? null
      : invalid
      ? RecognitionImage(name: 'fake.jpg', bytes: Uint8List.fromList([1, 2, 3]))
      : super.pick();
}

void main() {
  test(
    'upload preflight rejects invalid, empty and oversized image content',
    () {
      for (final bytes in [
        Uint8List(0),
        Uint8List.fromList([1, 2, 3]),
        Uint8List(10 * 1024 * 1024 + 1),
      ]) {
        expect(
          () => recognitionImageMime(
            RecognitionImage(name: 'valid.png', bytes: bytes),
          ),
          throwsA(isA<RecognitionImageException>()),
        );
      }
      expect(
        recognitionFailureMessage('MODEL_UNAVAILABLE'),
        contains('Mô hình'),
      );
      expect(
        recognitionFailureMessage('MODEL_UNAVAILABLE'),
        isNot(contains('ảnh khác')),
      );
    },
  );

  test(
    'MIME is derived from content rather than a misleading filename',
    () async {
      final original = (await FakeRecognitionPicker().pick())!;
      expect(
        recognitionImageMime(
          RecognitionImage(name: 'misleading.jpg', bytes: original.bytes),
        ),
        'png',
      );
    },
  );

  for (final profile in [
    (platform: TargetPlatform.android, width: 320.0, scale: 1.0),
    (platform: TargetPlatform.iOS, width: 390.0, scale: 1.3),
    (platform: TargetPlatform.windows, width: 1280.0, scale: 1.0),
  ]) {
    testWidgets(
      'capture, preview, cancellation and review fit ${profile.platform}',
      (tester) async {
        debugDefaultTargetPlatformOverride = profile.platform;
        tester.view.physicalSize = Size(profile.width, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = profile.scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final picker = CameraPicker();
        final server = RecognitionFakeServer();
        final api = ApiClientDart(dio: Dio()..httpClientAdapter = server);
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
                    components: const [
                      RecognitionComponentOption(
                        201,
                        'Điểm thường xuyên kiểm tra viết tay',
                      ),
                    ],
                    gradebookVersion: 1,
                    enabled: true,
                    onApproved: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Nhận dạng bảng điểm từ ảnh'));
        await tester.pumpAndSettle();
        final upload = find.byKey(const ValueKey('recognition-upload'));
        expect(tester.widget<AppActionButton>(upload).onPressed, isNull);
        final action = find.byKey(
          ValueKey(
            profile.platform == TargetPlatform.windows
                ? 'recognition-pick'
                : 'recognition-camera',
          ),
        );
        await tester.ensureVisible(action);
        await tester.runAsync(() async {
          await tester.tap(action);
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('recognition-filename')),
          findsOneWidget,
        );
        if (profile.platform != TargetPlatform.windows) {
          expect(picker.captures, 1);
        }
        picker.cancelled = true;
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('recognition-filename')),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('Phóng to ảnh'));
        await tester.tap(find.text('Phóng to ảnh'));
        await tester.pumpAndSettle();
        expect(find.byType(InteractiveViewer), findsOneWidget);
        await tester.tap(find.byTooltip('Đóng ảnh'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(upload);
        await tester.tap(upload);
        await tester.pumpAndSettle();
        expect(server.uploaded, isTrue);
        expect(find.byKey(const ValueKey('review-screen')), findsOneWidget);
        expect(find.textContaining('Giá trị: 0.0'), findsNWidgets(2));

        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }
}
