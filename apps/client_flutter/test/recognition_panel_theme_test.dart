import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/app/widgets/app_badge.dart';
import 'package:client_flutter/app/widgets/app_controls.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/recognition/image_picker.dart';
import 'package:client_flutter/features/recognition/recognition_panel.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'phase3_recognition_test.dart' show FakeRecognitionPicker;

/// Server giả cho danh sách phiếu: trả đúng các phiếu được truyền vào.
class _TicketsServer implements HttpClientAdapter {
  _TicketsServer(this.tickets);

  final List<Map<String, Object?>> tickets;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final isList =
        options.path.endsWith('/recognition-tickets') &&
        options.method == 'GET';
    return ResponseBody.fromString(
      jsonEncode(isList ? tickets : <String, Object>{}),
      isList ? 200 : 404,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

Map<String, Object?> _ticket(
  String id,
  String status, {
  String? errorCode,
  String? cancelReason,
  String? cancelledAt,
  String createdAt = '2026-09-12T01:02:03.000Z',
  int greenRows = 0,
  int yellowRows = 0,
  int redRows = 0,
  int? detectedRows,
}) => {
  'ticketId': id,
  'gradebookId': 7,
  'componentId': 201,
  'componentName': 'Kiểm tra 1',
  'declaredRows': 5,
  'detectedRows': detectedRows,
  'status': status,
  'errorCode': errorCode,
  'modelVersion': 'fake-dev-v1',
  'version': 1,
  'createdAt': createdAt,
  'greenRows': greenRows,
  'yellowRows': yellowRows,
  'redRows': redRows,
  'cancelReason': cancelReason,
  'cancelledAt': cancelledAt,
};

/// Đủ năm trạng thái phiếu; phiếu 41 mới nhất (đang đối chiếu).
List<Map<String, Object?>> _allStatuses() => [
  _ticket(
    '41',
    'CHO_DOI_CHIEU',
    createdAt: '2026-09-12T05:00:00.000Z',
    detectedRows: 12,
    greenRows: 8,
    yellowRows: 3,
    redRows: 1,
  ),
  _ticket('42', 'DANG_XU_LY', createdAt: '2026-09-12T04:00:00.000Z'),
  _ticket(
    '43',
    'DA_DUYET',
    createdAt: '2026-09-12T03:00:00.000Z',
    detectedRows: 12,
    greenRows: 12,
  ),
  _ticket(
    '44',
    'LOI',
    errorCode: 'IMAGE_QUALITY_LOW',
    createdAt: '2026-09-12T02:00:00.000Z',
  ),
  _ticket(
    '45',
    'DA_HUY',
    cancelReason: 'Chọn nhầm ảnh',
    cancelledAt: '2026-09-12T02:30:00.000Z',
  ),
];

const _components = [
  RecognitionComponentOption(201, 'Kiểm tra 1'),
  RecognitionComponentOption(202, 'Giữa kỳ'),
  RecognitionComponentOption(203, 'Điểm thường xuyên kiểm tra viết tay'),
];

Future<void> _pumpPanel(
  WidgetTester tester, {
  required List<Map<String, Object?>> tickets,
  required bool dark,
  required Size size,
  double textScale = 1.0,
  bool embedded = true,
  bool enabled = true,
  List<RecognitionComponentOption> components = _components,
  RecognitionImagePicker? picker,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final api = ApiClientDart(
    dio: Dio()..httpClientAdapter = _TicketsServer(tickets),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiProvider.overrideWithValue(api),
        if (picker != null)
          recognitionImagePickerProvider.overrideWithValue(picker),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: RecognitionPanel(
              gradebookId: 7,
              components: components,
              gradebookVersion: 1,
              enabled: enabled,
              embedded: embedded,
              onApproved: () {},
            ),
          ),
        ),
      ),
    ),
  );
  // Phiếu DANG_XU_LY có vòng xoay chạy mãi nên không dùng pumpAndSettle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Gỡ cây widget để hủy hẹn giờ polling 3 giây còn treo.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

BoxDecoration _cardDecoration(WidgetTester tester, String ticketId) {
  final card = tester.widget<Container>(
    find.byKey(ValueKey('recognition-ticket-card-$ticketId')),
  );
  return card.decoration! as BoxDecoration;
}

void main() {
  _narrowTests();
  for (final dark in [false, true]) {
    for (final width in [390.0, 1280.0]) {
      final mode = dark ? 'tối' : 'sáng';
      testWidgets('panel ở chế độ $mode, ${width.toInt()} px: đủ trạng thái, '
          'không tràn', (tester) async {
        final tokens = dark ? AppTokens.dark : AppTokens.light;
        await _pumpPanel(
          tester,
          tickets: _allStatuses(),
          dark: dark,
          size: Size(width, 3000),
        );
        expect(tester.takeException(), isNull);

        // Tiêu đề giữ nguyên, stepper 4 bước.
        expect(find.text('Nhận dạng bảng điểm từ ảnh'), findsOneWidget);
        for (final label in [
          'Chọn bảng điểm',
          'Tải ảnh lên',
          'Hệ thống nhận dạng',
          'Đối chiếu & duyệt',
        ]) {
          expect(find.text(label), findsOneWidget);
        }

        // Chip chọn cột điểm thay cho dropdown.
        expect(find.byType(DropdownButtonFormField<num>), findsNothing);
        for (final c in _components) {
          expect(find.text(c.name), findsOneWidget);
        }
        expect(
          find.text('Bắt buộc chọn cột điểm trước khi nhận dạng'),
          findsOneWidget,
        );

        // Dropzone và các nút giữ chuỗi/key.
        expect(find.byKey(const ValueKey('recognition-pick')), findsOneWidget);
        expect(find.text('Chọn ảnh bảng điểm'), findsOneWidget);
        expect(
          tester
              .widget<AppActionButton>(
                find.byKey(const ValueKey('recognition-upload')),
              )
              .onPressed,
          isNull,
        );
        expect(find.text('Tải ảnh & Nhận dạng'), findsOneWidget);

        // Ba phiếu đầu, rồi mở rộng để thấy cả năm trạng thái.
        await tester.tap(find.text('Xem tất cả phiếu'));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Đang xử lý'), findsOneWidget);
        expect(find.text('Chờ đối chiếu'), findsOneWidget);
        expect(find.text('Đã duyệt'), findsOneWidget);
        expect(find.text('Lỗi'), findsOneWidget);
        expect(find.text('Đã hủy'), findsOneWidget);
        expect(find.text('8 Xanh'), findsOneWidget);
        expect(find.text('3 Vàng'), findsOneWidget);
        expect(find.text('1 Đỏ'), findsOneWidget);
        expect(find.text('12 dòng'), findsWidgets);
        expect(find.textContaining('Lý do: Chọn nhầm ảnh'), findsOneWidget);
        expect(
          find.textContaining('Ảnh mờ hoặc độ phân giải thấp'),
          findsOneWidget,
        );
        // Phiếu không có dữ liệu tiến độ nên không có thanh phần trăm.
        expect(find.byKey(const ValueKey('app-progress-fill')), findsNothing);
        expect(find.byType(AppBadge), findsWidgets);
        expect(find.byKey(const ValueKey('ticket-menu-41')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('ticket-cancel-quick-42')),
          findsOneWidget,
        );

        // Màu thẻ lấy từ token của chế độ hiện tại, không còn trắng cứng.
        expect(_cardDecoration(tester, '43').color, tokens.surface);
        expect(_cardDecoration(tester, '45').color, tokens.subtle);
        expect(
          _cardDecoration(tester, '41').border!.top.color,
          tokens.warnLine,
        );
        expect(_cardDecoration(tester, '43').border!.top.color, tokens.line);

        expect(tester.takeException(), isNull);
        await _teardown(tester);
      });
    }
  }

  testWidgets('stepper suy ra từ phiếu mới nhất, không thêm state', (
    tester,
  ) async {
    // Không có phiếu: bước 1 đã qua (dấu tích), bước 2 đang chọn.
    await _pumpPanel(
      tester,
      tickets: const [],
      dark: false,
      size: const Size(1280, 2000),
    );
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Chưa có phiếu nhận dạng nào.'), findsOneWidget);
    await _teardown(tester);

    // Phiếu mới nhất đang xử lý: tới bước 3 (2 dấu tích).
    await _pumpPanel(
      tester,
      tickets: [_ticket('1', 'DANG_XU_LY')],
      dark: false,
      size: const Size(1280, 2000),
    );
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
    await _teardown(tester);

    // Phiếu mới nhất chờ đối chiếu: tới bước 4 (3 dấu tích).
    await _pumpPanel(
      tester,
      tickets: [_ticket('2', 'CHO_DOI_CHIEU', detectedRows: 3, greenRows: 3)],
      dark: true,
      size: const Size(390, 2000),
    );
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(3));
    await _teardown(tester);

    // Phiếu đã duyệt: quay lại bước 2.
    await _pumpPanel(
      tester,
      tickets: [_ticket('3', 'DA_DUYET', detectedRows: 3, greenRows: 3)],
      dark: true,
      size: const Size(390, 2000),
    );
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await _teardown(tester);
  });

  for (final dark in [false, true]) {
    testWidgets('chọn ảnh và chọn cột điểm (${dark ? 'tối' : 'sáng'}, 390 px, '
        'chữ 1,3x)', (tester) async {
      await _pumpPanel(
        tester,
        tickets: const [],
        dark: dark,
        size: const Size(390, 3000),
        textScale: 1.3,
        picker: FakeRecognitionPicker(),
      );
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('recognition-pick')));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byKey(const ValueKey('recognition-filename')),
        findsOneWidget,
      );
      // Ảnh đã qua kiểm tra định dạng nên có nhãn; chưa chọn cột thì nhắc.
      expect(find.text('Định dạng hợp lệ'), findsOneWidget);
      expect(find.text('Chọn ảnh khác'), findsOneWidget);
      expect(find.text('Phóng to ảnh'), findsOneWidget);
      expect(find.text('Bỏ ảnh đã chọn'), findsOneWidget);
      expect(
        find.textContaining('Vui lòng chọn cột thành phần điểm'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<AppActionButton>(
              find.byKey(const ValueKey('recognition-upload')),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.byKey(const ValueKey('recognition-component-202')));
      await tester.pump();
      expect(
        tester
            .widget<AppActionButton>(
              find.byKey(const ValueKey('recognition-upload')),
            )
            .onPressed,
        isNotNull,
      );
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await _teardown(tester);
    });
  }

  testWidgets('chế độ gập (không embedded) vẫn dựng đúng ở tối', (
    tester,
  ) async {
    await _pumpPanel(
      tester,
      tickets: _allStatuses(),
      dark: true,
      size: const Size(390, 3000),
      embedded: false,
    );
    await tester.tap(find.text('Nhận dạng bảng điểm từ ảnh'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Hệ thống nhận dạng'), findsOneWidget);
    expect(find.byKey(const ValueKey('recognition-pick')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _teardown(tester);
  });

  testWidgets('bảng điểm khóa hoặc không có cột mở nhập: thông báo đúng tông', (
    tester,
  ) async {
    await _pumpPanel(
      tester,
      tickets: const [],
      dark: true,
      size: const Size(390, 2000),
      enabled: false,
      components: const [],
    );
    expect(
      find.textContaining('Bảng điểm hiện không cho phép gửi ảnh'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Không có cột điểm nào đang mở nhập'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppActionButton>(
            find.byKey(const ValueKey('recognition-pick')),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
    await _teardown(tester);
  });

  for (final dark in [false, true]) {
    for (final width in [390.0, 1280.0]) {
      testWidgets(
        'hộp thoại hủy phiếu (${dark ? 'tối' : 'sáng'}, ${width.toInt()} px)',
        (tester) async {
          final tokens = dark ? AppTokens.dark : AppTokens.light;
          await _pumpPanel(
            tester,
            tickets: [_ticket('42', 'CHO_DOI_CHIEU', detectedRows: 2)],
            dark: dark,
            size: Size(width, 1600),
          );
          await tester.tap(find.byKey(const ValueKey('ticket-menu-42')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.text('Hủy phiếu'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(
            find.byKey(
              ValueKey(
                width < 600
                    ? 'cancel-ticket-bottom-sheet'
                    : 'cancel-ticket-dialog',
              ),
            ),
            findsOneWidget,
          );
          expect(find.text('Hủy phiếu #42?'), findsOneWidget);
          for (final reason in [
            'Chọn nhầm ảnh',
            'Nhầm thành phần điểm',
            'Ảnh mờ / chụp lại',
            'Khác…',
          ]) {
            expect(find.text(reason), findsOneWidget);
          }
          final confirm = find.byKey(
            const ValueKey('confirm-cancel-ticket-button'),
          );
          expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
          expect(tester.getSize(confirm).height, 48);

          await tester.tap(find.byKey(const ValueKey('cancel-reason-Khác…')));
          await tester.pump();
          expect(
            find.byKey(const ValueKey('cancel-reason-other-input')),
            findsOneWidget,
          );
          // Nút xác nhận lấy màu lỗi từ token.
          final style = tester.widget<FilledButton>(confirm).style!;
          expect(style.backgroundColor!.resolve(<WidgetState>{}), tokens.bad);
          expect(tester.takeException(), isNull);

          await tester.tap(
            find.byKey(const ValueKey('close-cancel-ticket-button')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await _teardown(tester);
        },
      );
    }
  }
}

void _narrowTests() {
  for (final dark in [false, true]) {
    testWidgets(
      '320 px, chữ 1,3x, đủ trạng thái phiếu không tràn (${dark ? 'tối' : 'sáng'})',
      (tester) async {
        await _pumpPanel(
          tester,
          tickets: _allStatuses(),
          dark: dark,
          size: const Size(320, 4000),
          textScale: 1.3,
        );
        await tester.tap(find.text('Xem tất cả phiếu'));
        await tester.pump();
        expect(find.text('Đối chiếu & duyệt'), findsOneWidget);
        expect(find.text('Đã hủy'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _teardown(tester);
      },
    );
  }
}
