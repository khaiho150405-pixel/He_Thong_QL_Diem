import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/widgets/app_controls.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/recognition/image_picker.dart';
import 'package:client_flutter/features/recognition/recognition_panel.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'phase3_recognition_test.dart'
    show FakeRecognitionPicker, RecognitionFakeServer;

class ScriptedPicker implements RecognitionImagePicker {
  RecognitionImage? next;
  int calls = 0;

  @override
  Future<RecognitionImage?> pick() async {
    calls++;
    return next;
  }
}

Uint8List pngHeader(int width, int height) {
  final bytes = ByteData(33);
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  for (var i = 0; i < signature.length; i++) {
    bytes.setUint8(i, signature[i]);
  }
  bytes.setUint32(8, 13);
  for (final entry in 'IHDR'.codeUnits.indexed) {
    bytes.setUint8(12 + entry.$1, entry.$2);
  }
  bytes.setUint32(16, width);
  bytes.setUint32(20, height);
  return bytes.buffer.asUint8List();
}

Future<void> openPanel(WidgetTester tester, ScriptedPicker picker) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
}

Future<void> closePanel(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  debugDefaultTargetPlatformOverride = null;
}

Future<void> pickImage(WidgetTester tester) async {
  final action = find.byKey(const ValueKey('recognition-pick'));
  await tester.ensureVisible(action);
  await tester.runAsync(() async {
    await tester.tap(action);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pumpAndSettle();
}

bool uploadEnabled(WidgetTester tester) =>
    tester
        .widget<AppActionButton>(
          find.byKey(const ValueKey('recognition-upload')),
        )
        .onPressed !=
    null;

final filename = find.byKey(const ValueKey('recognition-filename'));

void main() {
  testWidgets('TC-01 chọn ảnh PNG hợp lệ: hiện tên tệp và bật nút tải', (
    tester,
  ) async {
    final picker = ScriptedPicker();
    await openPanel(tester, picker);
    expect(filename, findsNothing);
    expect(uploadEnabled(tester), isFalse);

    picker.next = (await FakeRecognitionPicker().pick())!;
    await pickImage(tester);

    expect(picker.calls, 1);
    expect(filename, findsOneWidget);
    expect(find.text('bang-diem.png'), findsWidgets);
    expect(uploadEnabled(tester), isTrue);
    await closePanel(tester);
  });

  testWidgets(
    'TC-02 tệp đuôi .jpg nhưng nội dung không phải ảnh: báo lỗi, không nhận',
    (tester) async {
      final picker = ScriptedPicker()
        ..next = RecognitionImage(
          name: 'bang-diem.jpg',
          bytes: Uint8List.fromList([1, 2, 3, 4, 5]),
        );
      await openPanel(tester, picker);
      await pickImage(tester);

      expect(find.textContaining('Chỉ hỗ trợ ảnh PNG/JPEG hợp lệ'), findsOne);
      expect(filename, findsNothing);
      expect(uploadEnabled(tester), isFalse);
      expect(
        find.byKey(const ValueKey('recognition-retry-pick')),
        findsOneWidget,
      );
      await closePanel(tester);
    },
  );

  testWidgets('TC-03 ảnh lớn hơn 10 MB bị từ chối kèm thông báo rõ ràng', (
    tester,
  ) async {
    final picker = ScriptedPicker()
      ..next = RecognitionImage(
        name: 'anh-lon.png',
        bytes: Uint8List(10 * 1024 * 1024 + 1),
      );
    await openPanel(tester, picker);
    await pickImage(tester);

    expect(find.textContaining('vượt quá 10 MB'), findsOne);
    expect(filename, findsNothing);
    expect(uploadEnabled(tester), isFalse);
    await closePanel(tester);
  });

  testWidgets('TC-04 ảnh PNG quá nhiều pixel (12000 x 800) bị từ chối', (
    tester,
  ) async {
    final picker = ScriptedPicker()
      ..next = RecognitionImage(
        name: 'qua-lon.png',
        bytes: pngHeader(12000, 800),
      );
    await openPanel(tester, picker);
    await pickImage(tester);

    expect(find.textContaining('Ảnh quá lớn'), findsOne);
    expect(filename, findsNothing);
    expect(uploadEnabled(tester), isFalse);
    await closePanel(tester);
  });

  testWidgets(
    'TC-05 hủy hộp chọn không làm mất ảnh đang chọn; bỏ chọn thì tắt nút tải',
    (tester) async {
      final picker = ScriptedPicker();
      await openPanel(tester, picker);
      picker.next = (await FakeRecognitionPicker().pick())!;
      await pickImage(tester);
      expect(filename, findsOneWidget);

      picker.next = null;
      await pickImage(tester);
      expect(picker.calls, 2);
      expect(filename, findsOneWidget);
      expect(uploadEnabled(tester), isTrue);

      final clear = find.byKey(const ValueKey('recognition-clear'));
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(filename, findsNothing);
      expect(uploadEnabled(tester), isFalse);
      await closePanel(tester);
    },
  );
}
