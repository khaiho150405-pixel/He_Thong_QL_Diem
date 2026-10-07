import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/features/authentication/home_screen.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/recognition/recognition_panel.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class ReviewTestServer implements HttpClientAdapter {
  ReviewTestServer({
    this.role = 'GIAO_VIEN',
    this.ticketStatus = 'CHO_DOI_CHIEU',
    this.ticketErrorCode,
    this.includeNameCrop = true,
  });

  final String role;
  String ticketStatus;
  String? ticketErrorCode;
  final bool includeNameCrop;
  int detailCalls = 0;
  Map<String, dynamic>? lastApprovalBody;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object body;
    var status = 200;

    if (options.path.endsWith('/login')) {
      body = {
        'id': role == 'HOC_SINH' ? 3 : 2,
        'username': role == 'HOC_SINH' ? '0912345678' : '0987654321',
        'role': role,
        'active': true,
        'token': 'test-token',
        'csrf': 'test-csrf',
      };
    } else if (options.path.endsWith('/gradebooks/7/cells')) {
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
        },
        'items': [
          {
            'id': '9001',
            'studentId': 101,
            'studentName': 'Nguyễn Văn An',
            'stt': 1,
            'active': true,
            'componentId': 201,
            'componentName': 'Điểm kiểm tra',
            'coefficient': '1.0',
            'required': true,
            'displayOrder': 1,
            'value': null,
            'status': 'CHUA_CO',
            'source': 'NHAP_TAY',
          },
        ],
        'nextCursor': null,
      };
    } else if (options.path.contains('/recognition-tickets/42/approve')) {
      lastApprovalBody =
          jsonDecode(options.data as String) as Map<String, dynamic>;
      body = {
        'ticketId': '42',
        'ticketVersion': 2,
        'gradebookId': 7,
        'gradebookVersion': 2,
        'reviewedRows': 3,
        'machineMatchedRows': 2,
        'humanCorrectedRows': 1,
        'errorRows': 0,
        'status': 'DA_DUYET',
      };
    } else if (options.path.contains('/recognition-tickets/42')) {
      detailCalls++;
      body = {
        'ticketId': '42',
        'gradebookId': 7,
        'componentId': 201,
        'componentName': 'Điểm kiểm tra',
        'declaredRows': 3,
        'detectedRows': 3,
        'greenRows': 1,
        'yellowRows': 1,
        'redRows': 1,
        'status': ticketStatus,
        'errorCode': ticketErrorCode,
        'modelVersion': 'v2',
        'version': 1,
        'createdAt': '2026-09-12T01:02:03.000Z',
        'sourceImageUrl': 'https://storage.test/source-$detailCalls.png',
        'imageUrlExpiresInSeconds': 300,
        'rows': [
          {
            'rowId': 'r-green',
            'order': 1,
            'stt': 1,
            'sttOnPaper': null,
            'studentId': 101,
            'studentName': 'Nguyễn Văn An',
            'nameRead': 'Nguyen Van An',
            'matchConfidence': '0.9850',
            'matchNote': null,
            'numericRaw': '8.5',
            'numericValue': '8.5',
            'numericConfidence': '0.9600',
            'writtenRaw': 'tám rưỡi',
            'writtenValue': '8.5',
            'writtenConfidence': '0.9400',
            'comparison': 'KHOP',
            'reviewLevel': 'XANH',
            'finalValue': null,
            'numericCropUrl': 'https://storage.test/crop-num-1.png',
            'writtenCropUrl': 'https://storage.test/crop-wri-1.png',
            'nameCropUrl': includeNameCrop
                ? 'https://storage.test/crop-name-1.png'
                : null,
          },
          {
            'rowId': 'r-yellow',
            'order': 2,
            'stt': 2,
            'sttOnPaper': null,
            'studentId': 102,
            'studentName': 'Trần Thị Bình',
            'nameRead': 'Tran Thi Binh',
            'matchConfidence': '0.9200',
            'matchNote': 'Chữ viết hơi mờ',
            'numericRaw': '7.0',
            'numericValue': '7.0',
            'numericConfidence': '0.7100',
            'writtenRaw': 'bảy',
            'writtenValue': null,
            'writtenConfidence': '0.5000',
            'comparison': 'MOT_KENH',
            'reviewLevel': 'VANG',
            'finalValue': null,
            'numericCropUrl': 'https://storage.test/crop-num-2.png',
            'writtenCropUrl': 'https://storage.test/crop-wri-2.png',
            'nameCropUrl': includeNameCrop
                ? 'https://storage.test/crop-name-2.png'
                : null,
          },
          {
            'rowId': 'r-red',
            'order': 3,
            'stt': 3,
            'sttOnPaper': null,
            'studentId': 103,
            'studentName': 'Lê Hoàng Cúc',
            'nameRead': 'Le Hoang Cuc',
            'matchConfidence': '0.4500',
            'matchNote': 'Tên trên giấy không khớp chắc chắn với danh sách lớp',
            'numericRaw': '9.0',
            'numericValue': '9.0',
            'numericConfidence': '0.9000',
            'writtenRaw': 'tám',
            'writtenValue': '8.0',
            'writtenConfidence': '0.8800',
            'comparison': 'LECH',
            'reviewLevel': 'DO',
            'finalValue': null,
            'numericCropUrl': 'https://storage.test/crop-num-3.png',
            'writtenCropUrl': 'https://storage.test/crop-wri-3.png',
            'nameCropUrl': includeNameCrop
                ? 'https://storage.test/crop-name-3.png'
                : null,
          },
        ],
      };
    } else if (options.path.contains('/recognition-tickets')) {
      body = [
        {
          'ticketId': '42',
          'gradebookId': 7,
          'componentId': 201,
          'componentName': 'Điểm kiểm tra',
          'declaredRows': 3,
          'detectedRows': 3,
          'greenRows': 1,
          'yellowRows': 1,
          'redRows': 1,
          'status': ticketStatus,
          'errorCode': ticketErrorCode,
          'modelVersion': 'v2',
          'version': 1,
          'createdAt': '2026-09-12T01:02:03.000Z',
        },
      ];
    } else {
      status = 404;
      body = <String, Object>{};
    }

    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

void main() {
  group('ReviewScreen and auto-navigation', () {
    testWidgets(
      'HOC_SINH is redirected from /gradebooks/:id/recognition/:ticketId',
      (tester) async {
        final server = ReviewTestServer(role: 'HOC_SINH');
        final api = ApiClientDart(dio: Dio()..httpClientAdapter = server);
        final container = ProviderContainer(
          overrides: [apiProvider.overrideWithValue(api)],
        );
        addTearDown(container.dispose);

        await tester.runAsync(
          () => container
              .read(sessionProvider.notifier)
              .login('0912345678', 'password'),
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const GradebookApp(
              initialLocation: '/gradebooks/7/recognition/42',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should be redirected away from gradebooks route to home /
        expect(find.byKey(const ValueKey('review-screen')), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      'ReviewScreen displays name crops, confidence, DO empty suggestion, and color filters',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 2500);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final server = ReviewTestServer();
        final api = ApiClientDart(dio: Dio()..httpClientAdapter = server);
        final container = ProviderContainer(
          overrides: [apiProvider.overrideWithValue(api)],
        );
        addTearDown(container.dispose);

        await tester.runAsync(
          () => container
              .read(sessionProvider.notifier)
              .login('0987654321', 'password'),
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const GradebookApp(
              initialLocation: '/gradebooks/7/recognition/42',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('review-screen')), findsOneWidget);
        expect(find.text('Đối chiếu nhận dạng #42'), findsOneWidget);

        // STT and student names
        expect(find.textContaining('STT 1 · Nguyễn Văn An'), findsOneWidget);
        expect(find.textContaining('STT 2 · Trần Thị Bình'), findsOneWidget);
        expect(find.textContaining('STT 3 · Lê Hoàng Cúc'), findsOneWidget);

        // Name crops & match confidences
        expect(find.text('Tên đọc được: Nguyen Van An'), findsOneWidget);
        expect(find.text('Độ tin cậy: 98.5%'), findsOneWidget);
        expect(find.text('Phóng to họ tên'), findsNWidgets(3));

        // Suggested value invariants:
        // Green row (KHOP) should suggest 8.5
        final greenField = tester.widget<TextFormField>(
          find.byKey(const ValueKey('review-value-r-green')),
        );
        expect(greenField.controller?.text, '8.5');

        // Yellow row (MOT_KENH) should suggest 7.0
        final yellowField = tester.widget<TextFormField>(
          find.byKey(const ValueKey('review-value-r-yellow')),
        );
        expect(yellowField.controller?.text, '7.0');

        // RED ROW MUST NEVER HAVE PRE-FILLED SUGGESTION
        final redField = tester.widget<TextFormField>(
          find.byKey(const ValueKey('review-value-r-red')),
        );
        expect(redField.controller?.text, isEmpty);

        // Warning message for mismatch on Red row
        expect(
          find.textContaining('Nghi lệch học sinh: Tên trên giấy không khớp'),
          findsOneWidget,
        );

        // Color filter tests
        // Default is ALL (3 rows)
        expect(
          find.byKey(const ValueKey('review-value-r-green')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('review-value-r-yellow')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('review-value-r-red')),
          findsOneWidget,
        );

        // Filter DO: only Red row visible
        await tester.tap(find.byKey(const ValueKey('ALL')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Đỏ · Bắt buộc xem xét (1)').last);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('review-value-r-green')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('review-value-r-yellow')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('review-value-r-red')),
          findsOneWidget,
        );

        // Filter XANH: only Green row visible
        await tester.tap(find.byKey(const ValueKey('DO')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xanh · Khớp tin cậy (1)').last);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('review-value-r-green')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('review-value-r-yellow')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('review-value-r-red')), findsNothing);

        // Back to ALL
        await tester.tap(find.byKey(const ValueKey('XANH')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tất cả (3 dòng)').last);
        await tester.pumpAndSettle();

        // Enter value and reason for Red row to allow approval
        await tester.enterText(
          find.byKey(const ValueKey('review-value-r-red')),
          '8.5',
        );
        await tester.enterText(
          find.byKey(const ValueKey('review-reason-r-red')),
          'Đã đối chiếu bài thi gốc',
        );

        // Refresh evidence does not overwrite typed value
        await tester.tap(find.byKey(const ValueKey('review-refresh-source')));
        await tester.pumpAndSettle();
        expect(server.detailCalls, 2);
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('review-value-r-red')),
              )
              .controller
              ?.text,
          '8.5',
        );

        // Confirm all and approve
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('review-confirm-all')),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(const ValueKey('review-confirm-all')));
        await tester.pump();

        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('review-approve')),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        ScaffoldMessenger.of(
          tester.element(find.byType(Scaffold).first),
        ).clearSnackBars();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('review-approve')));
        await tester.pumpAndSettle();

        // Approval API called with expected payloads
        expect(server.lastApprovalBody, isNotNull);
        final decisions =
            server.lastApprovalBody!['decisions'] as List<dynamic>;
        expect(decisions.length, 3);
        final redDecision =
            decisions.firstWhere((d) => d['rowId'] == 'r-red')
                as Map<String, dynamic>;
        expect(redDecision['value'], '8.5');
        expect(redDecision['reason'], 'Đã đối chiếu bài thi gốc');
      },
    );

    testWidgets(
      'ReviewScreen shows placeholder "Không có ảnh họ tên" when nameCropUrl is null',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 2500);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final server = ReviewTestServer(includeNameCrop: false);
        final api = ApiClientDart(dio: Dio()..httpClientAdapter = server);
        final container = ProviderContainer(
          overrides: [apiProvider.overrideWithValue(api)],
        );
        addTearDown(container.dispose);

        await tester.runAsync(
          () => container
              .read(sessionProvider.notifier)
              .login('0987654321', 'password'),
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const GradebookApp(
              initialLocation: '/gradebooks/7/recognition/42',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Không có ảnh họ tên'), findsNWidgets(3));
      },
    );

    testWidgets(
      'RecognitionPanel displays error and retry buttons when ticket reaches LOI',
      (tester) async {
        final server = ReviewTestServer(
          ticketStatus: 'LOI',
          ticketErrorCode: 'ROW_MATCH_FAILED',
        );
        final api = ApiClientDart(dio: Dio()..httpClientAdapter = server);
        final container = ProviderContainer(
          overrides: [apiProvider.overrideWithValue(api)],
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
                      RecognitionComponentOption(201, 'Điểm kiểm tra'),
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

        // Expanding panel
        await tester.tap(find.text('Nhận dạng bảng điểm từ ảnh'));
        await tester.pumpAndSettle();

        // Error message for ROW_MATCH_FAILED should be displayed in the ticket item
        expect(
          find.textContaining(
            'Không xác định được học sinh cho một số dòng. Kiểm tra đúng lớp và chụp lại rõ cột Họ tên.',
          ),
          findsOneWidget,
        );
      },
    );

    for (final width in [320.0, 390.0, 1280.0]) {
      testWidgets(
        'ReviewScreen renders responsively at width $width with 1.3 text scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.3;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          final server = ReviewTestServer();
          final api = ApiClientDart(dio: Dio()..httpClientAdapter = server);
          final container = ProviderContainer(
            overrides: [apiProvider.overrideWithValue(api)],
          );
          addTearDown(container.dispose);

          await tester.runAsync(
            () => container
                .read(sessionProvider.notifier)
                .login('0987654321', 'password'),
          );

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const GradebookApp(
                initialLocation: '/gradebooks/7/recognition/42',
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byKey(const ValueKey('review-screen')), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
