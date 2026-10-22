import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/recognition/image_picker.dart';
import 'package:client_flutter/features/recognition/recognition_panel.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'phase3_recognition_test.dart' show FakeRecognitionPicker;

class CancelNavigationTestServer implements HttpClientAdapter {
  String role = 'GIAO_VIEN';
  String ticketStatus = 'CHO_DOI_CHIEU';
  String? cancelReason;
  String? cancelledAt;
  String sourceImageUrl = 'https://storage.test/source.png';
  bool includeCancelledParam = false;
  Map<String, dynamic>? lastCancelBody;
  int cancelStatusCode = 200;
  String? cancelErrorMessage;
  bool uploadShouldDelay = false;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    int status = 200;
    dynamic body = {};

    if (path.endsWith('/identity/login') || path.endsWith('/identity/me')) {
      body = {
        'id': 1,
        'username': '0987654321',
        'role': role,
        'active': true,
        'token': 'test-token',
        'csrf': 'test-csrf',
      };
    } else if (path.contains('/recognition-tickets/') &&
        path.endsWith('/cancel')) {
      if (cancelStatusCode != 200) {
        status = cancelStatusCode;
        body = {
          'code': 'CONFLICT',
          'message': cancelErrorMessage ?? 'Phiếu đã duyệt hoặc không hợp lệ',
        };
      } else {
        lastCancelBody =
            jsonDecode(options.data as String) as Map<String, dynamic>;
        ticketStatus = 'DA_HUY';
        cancelReason = lastCancelBody?['reason'] as String?;
        cancelledAt = DateTime.now().toUtc().toIso8601String();
        sourceImageUrl = '';
        body = {
          'ticketId': '42',
          'gradebookId': 7,
          'componentId': 201,
          'componentName': 'Kiểm tra 1',
          'declaredRows': 1,
          'detectedRows': 1,
          'greenRows': 0,
          'yellowRows': 0,
          'redRows': 0,
          'status': 'DA_HUY',
          'errorCode': null,
          'modelVersion': 'v2',
          'version': 2,
          'createdAt': '2026-09-12T01:02:03.000Z',
          'cancelReason': cancelReason,
          'cancelledAt': cancelledAt,
          'sourceImageUrl': '',
          'imageUrlExpiresInSeconds': 0,
          'rows': [],
        };
      }
    } else if (path.endsWith('/recognition-tickets/upload')) {
      if (uploadShouldDelay) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      body = {
        'ticketId': '42',
        'status': 'DANG_XU_LY',
        'receiptAt': '2026-09-12T01:02:03.000Z',
      };
    } else if (path.contains('/recognition-tickets/42')) {
      body = {
        'ticketId': '42',
        'gradebookId': 7,
        'componentId': 201,
        'componentName': 'Kiểm tra 1',
        'declaredRows': 1,
        'detectedRows': 1,
        'greenRows': 1,
        'yellowRows': 0,
        'redRows': 0,
        'status': ticketStatus,
        'errorCode': null,
        'modelVersion': 'v2',
        'version': 1,
        'createdAt': '2026-09-12T01:02:03.000Z',
        'cancelReason': cancelReason,
        'cancelledAt': cancelledAt,
        'sourceImageUrl': sourceImageUrl,
        'imageUrlExpiresInSeconds': 300,
        'rows': [
          {
            'rowId': 'r-1',
            'order': 1,
            'stt': 1,
            'sttOnPaper': null,
            'studentId': 101,
            'studentName': 'Học sinh A',
            'exempt': false,
            'nameRead': 'Hoc sinh A',
            'matchConfidence': '0.98',
            'matchNote': null,
            'numericRaw': '8.0',
            'numericValue': '8.0',
            'numericConfidence': '0.95',
            'writtenRaw': 'tám',
            'writtenValue': '8.0',
            'writtenConfidence': '0.95',
            'comparison': 'KHOP',
            'reviewLevel': 'XANH',
            'suggestedSource': 'SO',
            'matchLevel': 'XANH',
            'gradeLevel': 'XANH',
            'finalValue': null,
            'numericCropUrl': ticketStatus == 'DA_HUY'
                ? null
                : 'https://storage.test/num-1.png',
            'writtenCropUrl': ticketStatus == 'DA_HUY'
                ? null
                : 'https://storage.test/wri-1.png',
            'nameCropUrl': ticketStatus == 'DA_HUY'
                ? null
                : 'https://storage.test/name-1.png',
          },
        ],
      };
    } else if (path.contains('/recognition-tickets')) {
      includeCancelledParam =
          options.queryParameters['includeCancelled'] == true ||
          options.queryParameters['includeCancelled'] == 'true';
      final tickets = <Map<String, dynamic>>[];
      if (ticketStatus != 'DA_HUY' || includeCancelledParam) {
        tickets.add({
          'ticketId': '42',
          'gradebookId': 7,
          'componentId': 201,
          'componentName': 'Kiểm tra 1',
          'declaredRows': 1,
          'detectedRows': 1,
          'greenRows': ticketStatus == 'DA_HUY' ? 0 : 1,
          'yellowRows': 0,
          'redRows': 0,
          'status': ticketStatus,
          'errorCode': null,
          'modelVersion': 'v2',
          'version': 1,
          'createdAt': '2026-09-12T01:02:03.000Z',
          'cancelReason': cancelReason,
          'cancelledAt': cancelledAt,
        });
      }
      body = tickets;
    } else if (path.contains('/final-results')) {
      body = [];
    } else if (path.contains('/gradebooks/7/cells')) {
      body = {
        'book': {
          'id': 7,
          'classId': 10,
          'subjectId': 20,
          'termId': 30,
          'className': '10A1',
          'subjectName': 'Toán',
          'termName': 'Học kỳ 1',
          'status': 'DANG_NHAP_LIEU',
          'version': 1,
          'pendingAdjustmentId': null,
          'resultsOutdated': false,
        },
        'items': [
          {
            'id': '9001',
            'studentId': 101,
            'studentName': 'Học sinh A',
            'stt': 1,
            'active': true,
            'componentId': 201,
            'componentName': 'Kiểm tra 1',
            'coefficient': '1.0',
            'required': true,
            'displayOrder': 1,
            'value': null,
            'status': 'CHUA_CO',
            'exemptionReason': null,
            'source': 'NHAP_TAY',
          },
        ],
        'nextCursor': null,
      };
    }

    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

Future<ProviderContainer> setupAuthenticatedContainer(
  WidgetTester tester, {
  required CancelNavigationTestServer server,
  String role = 'GIAO_VIEN',
  RecognitionImagePicker? picker,
}) async {
  server.role = role;
  final dio = Dio()..httpClientAdapter = server;
  final api = ApiClientDart(dio: dio);
  final container = ProviderContainer(
    overrides: [
      apiProvider.overrideWithValue(api),
      if (picker != null)
        recognitionImagePickerProvider.overrideWithValue(picker),
    ],
  );
  await tester.runAsync(
    () => container
        .read(sessionProvider.notifier)
        .login('0987654321', 'password'),
  );
  return container;
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('A & D: Điều hướng quay lại Web vs Mobile', () {
    testWidgets(
      'Web 1440x900: KHÔNG có Icons.arrow_back, có breadcrumb quay lại bảng điểm',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final server = CancelNavigationTestServer();
        final container = await setupAuthenticatedContainer(
          tester,
          server: server,
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const GradebookApp(
              initialLocation: '/gradebooks/7/recognition/42',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Kiểm tra Web layout: AppBar không có nút Icons.arrow_back
        expect(find.byIcon(Icons.arrow_back), findsNothing);

        // Có breadcrumb "Bảng điểm #7" và " › Phiếu #42"
        expect(find.text('Bảng điểm #7'), findsOneWidget);
        expect(find.text(' › Phiếu #42'), findsOneWidget);

        // Bấm vào "Bảng điểm #7" để quay lại bảng điểm
        await tester.tap(find.text('Bảng điểm #7'));
        await tester.pumpAndSettle();

        // Xác nhận đã về bảng điểm
        expect(find.text('10A1 · Toán'), findsOneWidget);
      },
    );

    testWidgets(
      'Mobile 360x800: có IconButton(Icons.arrow_back), không có breadcrumb',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final server = CancelNavigationTestServer();
        final container = await setupAuthenticatedContainer(
          tester,
          server: server,
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const GradebookApp(
              initialLocation: '/gradebooks/7/recognition/42',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Mobile layout: Có nút Icons.arrow_back
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        expect(find.byTooltip('Quay lại bảng điểm'), findsOneWidget);

        // Không hiện breadcrumb, AppBar có tiêu đề "Phiếu #42"
        expect(find.text(' › Phiếu #42'), findsNothing);
        expect(find.widgetWithText(AppBar, 'Phiếu #42'), findsOneWidget);

        // Bấm quay lại
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Xác nhận đã về bảng điểm
        expect(find.text('10A1 · Toán'), findsOneWidget);
      },
    );

    testWidgets(
      'PopScope: Android system back quay lại bảng điểm khi không có thay đổi',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final server = CancelNavigationTestServer();
        final container = await setupAuthenticatedContainer(
          tester,
          server: server,
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const GradebookApp(
              initialLocation: '/gradebooks/7/recognition/42',
            ),
          ),
        );
        await tester.pumpAndSettle();

        final popScope = find.byKey(const ValueKey('review-pop-scope'));
        expect(popScope, findsOneWidget);
        final widget = tester.widget<PopScope>(popScope);
        expect(widget.canPop, isTrue);
      },
    );
  });

  group('A & D: Cảnh báo bỏ thay đổi chưa duyệt', () {
    testWidgets(
      'Web: Dialog hỏi "Bỏ các thay đổi chưa duyệt?" khi đã sửa điểm',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final server = CancelNavigationTestServer();
        final container = await setupAuthenticatedContainer(
          tester,
          server: server,
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const GradebookApp(
              initialLocation: '/gradebooks/7/recognition/42',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Sửa điểm của dòng
        await tester.enterText(find.byType(TextFormField).first, '9.5');
        await tester.pumpAndSettle();

        // Bấm breadcrumb quay lại
        await tester.tap(find.text('Bảng điểm #7'));
        await tester.pumpAndSettle();

        // Hiện dialog xác nhận
        expect(find.text('Bỏ các thay đổi chưa duyệt?'), findsOneWidget);
        expect(find.text('Ở lại'), findsOneWidget);
        expect(find.text('Rời đi'), findsOneWidget);

        // Bấm "Ở lại" -> vẫn ở màn hình đối chiếu
        await tester.tap(find.text('Ở lại'));
        await tester.pumpAndSettle();
        expect(find.text('Bảng điểm #7'), findsOneWidget);
        expect(find.text('10A1 · Toán'), findsNothing);

        // Bấm lại breadcrumb -> bấm "Rời đi" -> về bảng điểm
        await tester.tap(find.text('Bảng điểm #7'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Rời đi'));
        await tester.pumpAndSettle();
        expect(find.text('10A1 · Toán'), findsOneWidget);
      },
    );

    testWidgets(
      'Mobile: Bottom sheet hỏi "Bỏ các thay đổi chưa duyệt?" khi đã sửa điểm',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final server = CancelNavigationTestServer();
        final container = await setupAuthenticatedContainer(
          tester,
          server: server,
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const GradebookApp(
              initialLocation: '/gradebooks/7/recognition/42',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Sửa điểm
        await tester.enterText(find.byType(TextFormField).first, '9.0');
        await tester.pumpAndSettle();

        // Bấm nút back trên AppBar
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Hiện Modal Bottom Sheet
        expect(
          find.byKey(const ValueKey('discard-changes-bottom-sheet')),
          findsOneWidget,
        );
        expect(find.text('Bỏ các thay đổi chưa duyệt?'), findsOneWidget);
        expect(find.text('Ở lại'), findsOneWidget);
        expect(find.text('Rời đi'), findsOneWidget);

        // Bấm "Rời đi"
        await tester.tap(find.text('Rời đi'));
        await tester.pumpAndSettle();
        expect(find.text('10A1 · Toán'), findsOneWidget);
      },
    );
  });

  group('B & D: Hủy tải lên (recognition_panel)', () {
    testWidgets('"Hủy tải lên" hủy request và giữ nguyên ảnh đã chọn', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final picker = FakeRecognitionPicker();
      final server = CancelNavigationTestServer();
      server.uploadShouldDelay = true;

      final container = await setupAuthenticatedContainer(
        tester,
        server: server,
        picker: picker,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: RecognitionPanel(
                  gradebookId: 7,
                  components: const [
                    RecognitionComponentOption(201, 'Kiểm tra 1'),
                  ],
                  gradebookVersion: 1,
                  enabled: true,
                  embedded: true,
                  onApproved: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Chọn ảnh
      final pickAction = find.byKey(const ValueKey('recognition-pick'));
      await tester.ensureVisible(pickAction);
      await tester.runAsync(() async {
        await tester.tap(pickAction);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('bang-diem.png'), findsOneWidget);

      // Bấm Tải ảnh & Nhận dạng
      await tester.tap(find.byKey(const ValueKey('recognition-upload')));
      await tester.pump();

      // Đang upload -> Hiện nút "Hủy tải lên"
      final cancelUploadBtn = find.byKey(
        const ValueKey('recognition-cancel-upload'),
      );
      expect(cancelUploadBtn, findsOneWidget);
      await tester.ensureVisible(cancelUploadBtn);

      // Bấm Hủy tải lên
      await tester.tap(cancelUploadBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Hiện snackbar "Đã hủy tải lên" và ảnh vẫn được giữ nguyên
      expect(find.text('Đã hủy tải lên'), findsOneWidget);
      expect(find.text('bang-diem.png'), findsOneWidget);
    });
  });

  group('C & D: Hủy phiếu nhận dạng', () {
    testWidgets('Thẻ phiếu: menu ⋮ có "Hủy phiếu" cho GIAO_VIEN, ẩn với QTV', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final server = CancelNavigationTestServer();
      server.ticketStatus = 'CHO_DOI_CHIEU';

      // 1. GIAO_VIEN
      final teacherContainer = await setupAuthenticatedContainer(
        tester,
        server: server,
        role: 'GIAO_VIEN',
      );
      addTearDown(teacherContainer.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: teacherContainer,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: RecognitionPanel(
                  gradebookId: 7,
                  components: const [
                    RecognitionComponentOption(201, 'Kiểm tra 1'),
                  ],
                  gradebookVersion: 1,
                  enabled: true,
                  embedded: true,
                  onApproved: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mở menu ⋮ của phiếu
      await tester.tap(find.byKey(const ValueKey('ticket-menu-42')));
      await tester.pumpAndSettle();

      expect(find.text('Xem phiếu'), findsOneWidget);
      expect(find.text('Hủy phiếu'), findsOneWidget);

      // Đóng menu
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // 2. QTV
      final adminContainer = await setupAuthenticatedContainer(
        tester,
        server: server,
        role: 'QUAN_TRI_VIEN',
      );
      addTearDown(adminContainer.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: adminContainer,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: RecognitionPanel(
                  gradebookId: 7,
                  components: const [
                    RecognitionComponentOption(201, 'Kiểm tra 1'),
                  ],
                  gradebookVersion: 1,
                  enabled: true,
                  embedded: true,
                  onApproved: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ticket-menu-42')));
      await tester.pumpAndSettle();

      expect(find.text('Xem phiếu'), findsOneWidget);
      expect(find.text('Hủy phiếu'), findsNothing);
    });

    testWidgets('Thẻ DANG_XU_LY có nút Hủy nhỏ trực tiếp', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final server = CancelNavigationTestServer();
      server.ticketStatus = 'DANG_XU_LY';
      final container = await setupAuthenticatedContainer(
        tester,
        server: server,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: RecognitionPanel(
                  gradebookId: 7,
                  components: const [
                    RecognitionComponentOption(201, 'Kiểm tra 1'),
                  ],
                  gradebookVersion: 1,
                  enabled: true,
                  embedded: true,
                  onApproved: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byKey(const ValueKey('ticket-cancel-quick-42')),
        findsOneWidget,
      );
    });

    testWidgets(
      'Hộp thoại hủy (Web dialog): nút bị khóa khi chưa chọn lý do, gửi đúng version & reason',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final server = CancelNavigationTestServer();
        server.ticketStatus = 'CHO_DOI_CHIEU';
        final container = await setupAuthenticatedContainer(
          tester,
          server: server,
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: RecognitionPanel(
                    gradebookId: 7,
                    components: const [
                      RecognitionComponentOption(201, 'Kiểm tra 1'),
                    ],
                    gradebookVersion: 1,
                    enabled: true,
                    embedded: true,
                    onApproved: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Bấm Hủy phiếu từ menu ⋮
        await tester.tap(find.byKey(const ValueKey('ticket-menu-42')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hủy phiếu'));
        await tester.pumpAndSettle();

        // Kiểm tra dialog xuất hiện
        expect(find.text('Hủy phiếu #42?'), findsOneWidget);
        expect(find.text('Chọn nhầm ảnh'), findsOneWidget);
        expect(find.text('Nhầm thành phần điểm'), findsOneWidget);
        expect(find.text('Ảnh mờ / chụp lại'), findsOneWidget);
        expect(find.text('Khác…'), findsOneWidget);

        // Nút Hủy phiếu ban đầu bị disable
        final confirmBtnFinder = find.byKey(
          const ValueKey('confirm-cancel-ticket-button'),
        );
        expect(confirmBtnFinder, findsOneWidget);
        final btn = tester.widget<FilledButton>(confirmBtnFinder);
        expect(btn.onPressed, isNull);

        // Chọn chip "Chọn nhầm ảnh"
        await tester.tap(find.text('Chọn nhầm ảnh'));
        await tester.pumpAndSettle();

        final btnEnabled = tester.widget<FilledButton>(confirmBtnFinder);
        expect(btnEnabled.onPressed, isNotNull);

        // Xác nhận hủy
        await tester.tap(confirmBtnFinder);
        await tester.pumpAndSettle();

        // Xác nhận đã gửi body
        expect(server.lastCancelBody?['reason'], 'Chọn nhầm ảnh');
        expect(server.lastCancelBody?['expectedVersion'], 1);
        expect(find.text('Đã hủy phiếu #42'), findsOneWidget);
      },
    );

    testWidgets(
      'Hộp thoại hủy (Mobile bottom sheet with Wrap): lỗi 409 hiện đúng message server',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final server = CancelNavigationTestServer();
        server.ticketStatus = 'CHO_DOI_CHIEU';
        server.cancelStatusCode = 409;
        server.cancelErrorMessage = 'Phiếu nhận dạng đã được duyệt trước đó';

        final container = await setupAuthenticatedContainer(
          tester,
          server: server,
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: RecognitionPanel(
                    gradebookId: 7,
                    components: const [
                      RecognitionComponentOption(201, 'Kiểm tra 1'),
                    ],
                    gradebookVersion: 1,
                    enabled: true,
                    embedded: true,
                    onApproved: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final menuBtn = find.byKey(const ValueKey('ticket-menu-42'));
        await tester.ensureVisible(menuBtn);
        await tester.tap(menuBtn);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hủy phiếu'));
        await tester.pumpAndSettle();

        // Trên mobile là BottomSheet
        expect(
          find.byKey(const ValueKey('cancel-ticket-bottom-sheet')),
          findsOneWidget,
        );

        // Chọn "Ảnh mờ / chụp lại"
        await tester.tap(find.text('Ảnh mờ / chụp lại'));
        await tester.pumpAndSettle();

        // Bấm Hủy phiếu
        await tester.tap(
          find.byKey(const ValueKey('confirm-cancel-ticket-button')),
        );
        await tester.pumpAndSettle();

        // Lỗi 409 hiển thị message tiếng Việt từ server
        expect(
          find.text('Phiếu nhận dạng đã được duyệt trước đó'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Công tắc "Hiện phiếu đã hủy" và ReviewScreen chế độ DA_HUY hiển thị "Ảnh đã xóa"',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final server = CancelNavigationTestServer();
        server.ticketStatus = 'DA_HUY';
        server.cancelReason = 'Ảnh chụp bị bóng mờ';
        server.cancelledAt = '2026-09-12T08:30:00.000Z';
        server.sourceImageUrl = '';

        final container = await setupAuthenticatedContainer(
          tester,
          server: server,
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: RecognitionPanel(
                    gradebookId: 7,
                    components: const [
                      RecognitionComponentOption(201, 'Kiểm tra 1'),
                    ],
                    gradebookVersion: 1,
                    enabled: true,
                    embedded: true,
                    onApproved: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Mặc định công tắc tắt -> Không có phiếu nào trong danh sách
        expect(find.text('Chưa có phiếu nhận dạng nào.'), findsOneWidget);

        // Bật công tắc "Hiện phiếu đã hủy"
        await tester.tap(
          find.byKey(const ValueKey('recognition-show-cancelled-switch')),
        );
        await tester.pumpAndSettle();

        // Phiếu DA_HUY xuất hiện kèm nhãn "Đã hủy" và lý do
        expect(find.text('Đã hủy'), findsOneWidget);
        expect(
          find.textContaining('Lý do: Ảnh chụp bị bóng mờ'),
          findsOneWidget,
        );

        // Mở màn hình đối chiếu của phiếu đã hủy
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const GradebookApp(
              initialLocation: '/gradebooks/7/recognition/42',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Banner "Phiếu đã hủy — Ảnh chụp bị bóng mờ"
        expect(
          find.textContaining('Phiếu đã hủy — Ảnh chụp bị bóng mờ'),
          findsOneWidget,
        );

        // Ảnh gốc và ảnh ô hiển thị "Ảnh đã xóa"
        expect(find.text('Ảnh đã xóa'), findsAtLeastNWidgets(1));

        // Không có nút duyệt hoặc lưu
        expect(find.text('Duyệt và ghi điểm chính thức'), findsNothing);
      },
    );

    testWidgets(
      '320x568 với textScale 1.3 không bị tràn (Panel & ReviewScreen)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final server = CancelNavigationTestServer();
        server.ticketStatus = 'DA_HUY';
        server.cancelReason = 'Chọn nhầm ảnh';

        final container = await setupAuthenticatedContainer(
          tester,
          server: server,
        );
        addTearDown(container.dispose);

        // 1. Kiểm tra RecognitionPanel
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: RecognitionPanel(
                    gradebookId: 7,
                    components: const [
                      RecognitionComponentOption(201, 'Kiểm tra 1'),
                    ],
                    gradebookVersion: 1,
                    enabled: true,
                    embedded: true,
                    onApproved: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // 2. Kiểm tra ReviewScreen
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const GradebookApp(
              initialLocation: '/gradebooks/7/recognition/42',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Bấm vào thẻ phiếu CHO_DOI_CHIEU mở màn hình đối chiếu (onTap showDetail)',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final server = CancelNavigationTestServer();
        server.ticketStatus = 'CHO_DOI_CHIEU';

        final container = await setupAuthenticatedContainer(
          tester,
          server: server,
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const GradebookApp(initialLocation: '/gradebooks/7'),
          ),
        );
        await tester.pumpAndSettle();

        // Mở tab Quét ảnh OCR
        await tester.tap(find.text('Quét ảnh OCR'));
        await tester.pumpAndSettle();

        // Kiểm tra thẻ phiếu xuất hiện và KHÔNG có nút "Đối chiếu ngay"
        expect(find.text('Phiếu #42 · Kiểm tra 1'), findsOneWidget);
        expect(find.text('Đối chiếu ngay'), findsNothing);

        // Bấm trực tiếp vào thẻ phiếu (ListTile)
        await tester.tap(find.text('Phiếu #42 · Kiểm tra 1'));
        await tester.pumpAndSettle();

        // Đã mở màn hình đối chiếu của phiếu #42
        expect(find.text('Bảng điểm #7'), findsOneWidget);
        expect(find.text('Phiếu #42'), findsOneWidget);
        // Xác nhận dòng tiến độ không còn xuất hiện
        expect(find.textContaining('dòng cần xem'), findsNothing);
      },
    );
  });
}
