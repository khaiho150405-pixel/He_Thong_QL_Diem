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
    this.failCells = false,
    this.rowsOverride,
  });

  final String role;
  String ticketStatus;
  String? ticketErrorCode;
  final bool includeNameCrop;
  bool failCells;
  final List<Map<String, dynamic>>? rowsOverride;
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
    } else if (options.path.endsWith('/gradebooks/7/cells') && failCells) {
      status = 500;
      body = {'code': 'INTERNAL', 'message': 'lỗi giả lập'};
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
          'pendingAdjustmentId': null,
          'resultsOutdated': false,
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
            'exemptionReason': null,
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
        'cancelReason': null,
        'cancelledAt': null,
        'sourceImageUrl': 'https://storage.test/source-$detailCalls.png',
        'imageUrlExpiresInSeconds': 300,
        'rows': (rowsOverride ??
            [
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
                'suggestedSource': 'SO',
                'matchLevel': 'XANH',
                'gradeLevel': 'XANH',
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
                'sttOnPaper': 5,
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
                'suggestedSource': 'SO',
                'matchLevel': 'VANG',
                'gradeLevel': 'VANG',
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
                'sttOnPaper': 3,
                'studentId': 103,
                'studentName': 'Lê Hoàng Cúc',
                'nameRead': 'Le Hoang Cuc',
                'matchConfidence': '0.4500',
                'matchNote':
                    'Tên trên giấy không khớp chắc chắn với danh sách lớp',
                'numericRaw': '9.0',
                'numericValue': '9.0',
                'numericConfidence': '0.9000',
                'writtenRaw': 'tám',
                'writtenValue': '8.0',
                'writtenConfidence': '0.8800',
                'comparison': 'LECH',
                'reviewLevel': 'DO',
                'suggestedSource': null,
                'matchLevel': 'DO',
                'gradeLevel': 'DO',
                'finalValue': null,
                'numericCropUrl': 'https://storage.test/crop-num-3.png',
                'writtenCropUrl': 'https://storage.test/crop-wri-3.png',
                'nameCropUrl': includeNameCrop
                    ? 'https://storage.test/crop-name-3.png'
                    : null,
              },
            ]).map((r) => <String, dynamic>{...r, 'exempt': r['exempt'] ?? false}).toList(),
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
          'cancelReason': null,
          'cancelledAt': null,
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

/// Một dòng bằng chứng đầy đủ trường (dữ liệu giả) để thử các tổ hợp mức điểm / mức ghép.
Map<String, dynamic> evidenceRow({
  required String level,
  required String? matchLevel,
  required String? gradeLevel,
  String? matchNote = 'Khớp danh sách',
  int stt = 1,
  int? sttOnPaper = 1,
  String comparison = 'KHOP',
  String? suggestedSource,
  String? numericValue = '8.5',
  String? numericConfidence = '0.9600',
  String? writtenRaw = 'tám rưỡi',
  String? writtenValue = '8.5',
  String? writtenConfidence = '0.9400',
  String? numericCropUrl = 'https://storage.test/crop-num-1.png',
  String? writtenCropUrl = 'https://storage.test/crop-wri-1.png',
  String? nameCropUrl = 'https://storage.test/crop-name-1.png',
}) {
  return {
    'rowId': 'r-1',
    'order': 1,
    'stt': stt,
    'sttOnPaper': sttOnPaper,
    'studentId': 101,
    'studentName': 'Nguyễn Văn An',
    'nameRead': 'Nguyen Van An',
    'matchConfidence': '0.9850',
    'matchNote': matchNote,
    'numericRaw': numericValue,
    'numericValue': numericValue,
    'numericConfidence': numericConfidence,
    'writtenRaw': writtenRaw,
    'writtenValue': writtenValue,
    'writtenConfidence': writtenConfidence,
    'comparison': comparison,
    'reviewLevel': level,
    'suggestedSource': suggestedSource,
    'matchLevel': matchLevel,
    'gradeLevel': gradeLevel,
    'finalValue': null,
    'numericCropUrl': numericCropUrl,
    'writtenCropUrl': writtenCropUrl,
    'nameCropUrl': nameCropUrl,
  };
}

Future<void> openReview(
  WidgetTester tester,
  ReviewTestServer server, {
  Size? physicalSize = const Size(1280, 2500),
}) async {
  if (physicalSize != null) {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
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
}

void main() {
  group('ReviewScreen and auto-navigation', () {
    testWidgets(
      'ReviewScreen without a gradebook version shows an error, disables approval and recovers on reload',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 3000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final server = ReviewTestServer(failCells: true);
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

        expect(
          find.textContaining('Không tải được phiên bản bảng điểm'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('review-retry-version')),
          findsOneWidget,
        );

        final confirm = find.byKey(const ValueKey('review-confirm-all'));
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        FilledButton approveButton() => tester.widget<FilledButton>(
          find.byKey(const ValueKey('review-approve')),
        );
        expect(approveButton().onPressed, isNull);
        expect(server.lastApprovalBody, isNull);

        // Reload after the server recovers: error gone, approval allowed with the real version.
        server.failCells = false;
        await tester.tap(find.byKey(const ValueKey('review-retry-version')));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Không tải được phiên bản bảng điểm'),
          findsNothing,
        );

        // Đỏ row cần được nhập điểm để nút Duyệt mở
        await tester.enterText(
          find.byKey(const ValueKey('review-value-r-red')),
          '8.0',
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('review-stt-confirm-r-yellow')),
        );
        await tester.pumpAndSettle();

        expect(approveButton().onPressed, isNotNull);
      },
    );

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
      'ReviewScreen displays new design elements, filters, DO empty suggestion, hides confidences and raw values',
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
        expect(find.text('Bảng điểm #7'), findsOneWidget);
        expect(find.text(' › Phiếu #42'), findsOneWidget);

        // KHÔNG hiển thị: Ký tự thô, Độ tin cậy, Tên đọc được, Điểm chưa đủ tin cậy, enum tiếng Anh trong tiêu đề
        expect(find.textContaining('Ký tự thô'), findsNothing);
        expect(find.textContaining('Độ tin cậy'), findsNothing);
        expect(find.textContaining('Tên đọc được'), findsNothing);
        expect(find.textContaining('Điểm chưa đủ tin cậy'), findsNothing);
        expect(find.textContaining('· DO'), findsNothing);
        expect(find.textContaining('· VANG'), findsNothing);
        expect(find.textContaining('· XANH'), findsNothing);

        // STT và tên học sinh cho các dòng cần xem (Đỏ / Vàng)
        // row 2: stt 2, sttOnPaper 5 (khác nhau) -> hiển thị chip "STT giấy 5 ≠ hệ thống 2"
        expect(
          find.textContaining('STT hệ thống 2 · Trần Thị Bình'),
          findsOneWidget,
        );
        expect(find.text('STT giấy 5 ≠ hệ thống 2'), findsOneWidget);
        // row 3: stt 3, sttOnPaper 3 (bằng nhau) -> KHÔNG hiển thị "trên giấy 3"
        expect(
          find.textContaining('STT hệ thống 3 · Lê Hoàng Cúc'),
          findsOneWidget,
        );
        expect(find.textContaining('STT hệ thống 3 · trên giấy'), findsNothing);

        // Mở mục thu gọn dòng Xanh để kiểm tra học sinh dòng Xanh (Nguyễn Văn An)
        await tester.tap(find.byKey(const ValueKey('review-green-group')));
        await tester.pumpAndSettle();
        expect(find.text('Nguyễn Văn An'), findsOneWidget);

        // Kiểm tra chip STT giấy khác hệ thống
        expect(find.text('STT giấy 5 ≠ hệ thống 2'), findsOneWidget);

        // Ảnh họ tên chỉ hiện khi matchLevel ≠ XANH
        // row 2 (VANG) và row 3 (DO) hiển thị "Họ tên trên giấy", row 1 (XANH) ẩn
        expect(find.text('Họ tên trên giấy'), findsNWidgets(2));
        expect(find.text('Kiểm tra đúng học sinh'), findsWidgets);

        // Giá trị gợi ý:
        // Green row: 8.5
        final greenField = tester.widget<TextFormField>(
          find.byKey(const ValueKey('review-value-r-green')),
        );
        expect(greenField.controller?.text, '8.5');

        // Yellow row: 7.0
        final yellowField = tester.widget<TextFormField>(
          find.byKey(const ValueKey('review-value-r-yellow')),
        );
        expect(yellowField.controller?.text, '7.0');
        expect(find.textContaining('Lấy theo'), findsNothing);
        expect(find.textContaining('khác nhau'), findsNothing);

        // RED ROW PHẢI ĐỂ TRỐNG
        final redField = tester.widget<TextFormField>(
          find.byKey(const ValueKey('review-value-r-red')),
        );
        expect(redField.controller?.text, isEmpty);

        // Cảnh báo Đỏ do matchLevel == DO -> "Kiểm tra đúng học sinh"
        expect(find.textContaining('Kiểm tra đúng học sinh'), findsWidgets);
        // Dòng Vàng do matchLevel == VANG -> "Kiểm tra đúng học sinh (STT trên giấy khác)"
        expect(
          find.textContaining('Kiểm tra đúng học sinh (STT trên giấy khác)'),
          findsOneWidget,
        );

        // Bộ lọc màu
        // Default ALL: có cả r-yellow và r-red
        expect(
          find.byKey(const ValueKey('review-value-r-yellow')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('review-value-r-red')),
          findsOneWidget,
        );

        // Lọc DO
        await tester.tap(find.byKey(const ValueKey('DO')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('review-value-r-yellow')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('review-value-r-red')),
          findsOneWidget,
        );

        // Lọc VANG
        await tester.tap(find.byKey(const ValueKey('VANG')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('review-value-r-yellow')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('review-value-r-red')), findsNothing);

        // Trở về ALL
        await tester.tap(find.byKey(const ValueKey('ALL')));
        await tester.pumpAndSettle();

        // Nhập điểm cho dòng Đỏ để mở duyệt
        await tester.enterText(
          find.byKey(const ValueKey('review-value-r-red')),
          '8.5',
        );
        await tester.tap(
          find.byKey(const ValueKey('review-stt-confirm-r-yellow')),
        );
        await tester.pumpAndSettle();

        // Xác nhận và Duyệt
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
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('review-approve')));
        await tester.pumpAndSettle();

        expect(server.lastApprovalBody, isNotNull);
        final decisions =
            server.lastApprovalBody!['decisions'] as List<dynamic>;
        expect(decisions.length, 3);
        final redDecision =
            decisions.firstWhere((d) => d['rowId'] == 'r-red')
                as Map<String, dynamic>;
        expect(redDecision['value'], '8.5');
        expect(redDecision['reason'], 'Đã đối chiếu ảnh nhận dạng');
      },
    );

    testWidgets(
      'reason case 1: matchLevel == DO displays "Kiểm tra đúng học sinh" and shows name crop',
      (tester) async {
        await openReview(
          tester,
          ReviewTestServer(
            rowsOverride: [
              evidenceRow(
                level: 'DO',
                matchLevel: 'DO',
                gradeLevel: 'XANH',
                matchNote: 'Họ tên khớp STT 3 hơn STT 2; nghi lệch dòng.',
              ),
            ],
          ),
        );
        expect(find.textContaining('Kiểm tra đúng học sinh'), findsOneWidget);
        expect(find.text('Họ tên trên giấy'), findsOneWidget);
        expect(find.textContaining('khác nhau'), findsNothing);
        expect(find.textContaining('Lấy theo'), findsNothing);
      },
    );

    testWidgets(
      'reason case 2: matchLevel == VANG displays "Kiểm tra đúng học sinh (STT trên giấy khác)" and shows name crop',
      (tester) async {
        await openReview(
          tester,
          ReviewTestServer(
            rowsOverride: [
              evidenceRow(
                level: 'VANG',
                matchLevel: 'VANG',
                gradeLevel: 'XANH',
                stt: 2,
                sttOnPaper: 5,
                matchNote: 'STT trên giấy 5 khác STT 2',
              ),
            ],
          ),
        );
        expect(
          find.textContaining('Kiểm tra đúng học sinh (STT trên giấy khác)'),
          findsOneWidget,
        );
        expect(find.text('Họ tên trên giấy'), findsOneWidget);
        expect(find.textContaining('khác nhau'), findsNothing);
        expect(find.textContaining('Lấy theo'), findsNothing);
      },
    );

    testWidgets(
      'reason case 3: comparison == KHONG_DOC_DUOC or missing crop displays "Ô điểm mờ, nhập theo ảnh"',
      (tester) async {
        await openReview(
          tester,
          ReviewTestServer(
            rowsOverride: [
              evidenceRow(
                level: 'DO',
                matchLevel: 'XANH',
                gradeLevel: 'DO',
                comparison: 'KHONG_DOC_DUOC',
              ),
            ],
          ),
        );
        expect(find.textContaining('Ô điểm mờ, nhập theo ảnh'), findsOneWidget);
        expect(find.textContaining('khác nhau'), findsNothing);
        expect(find.textContaining('Lấy theo'), findsNothing);
      },
    );

    testWidgets(
      'reason case 4: reviewLevel == DO displays "Nhập điểm theo ảnh"',
      (tester) async {
        await openReview(
          tester,
          ReviewTestServer(
            rowsOverride: [
              evidenceRow(
                level: 'DO',
                matchLevel: 'XANH',
                gradeLevel: 'DO',
                comparison: 'LECH',
                numericValue: '9.0',
                writtenValue: '8.0',
              ),
            ],
          ),
        );
        expect(find.textContaining('Nhập điểm theo ảnh'), findsOneWidget);
        expect(find.textContaining('khác nhau'), findsNothing);
        expect(find.textContaining('Lấy theo'), findsNothing);
      },
    );

    testWidgets(
      'reason case 5: reviewLevel == VANG displays "Kiểm tra điểm đã điền"',
      (tester) async {
        await openReview(
          tester,
          ReviewTestServer(
            rowsOverride: [
              evidenceRow(
                level: 'VANG',
                matchLevel: 'XANH',
                gradeLevel: 'VANG',
                comparison: 'MOT_KENH',
                numericValue: '10.0',
                writtenValue: null,
                writtenRaw: null,
              ),
            ],
          ),
        );
        expect(find.textContaining('Kiểm tra điểm đã điền'), findsOneWidget);
        expect(find.textContaining('khác nhau'), findsNothing);
        expect(find.textContaining('Lấy theo'), findsNothing);
      },
    );

    testWidgets(
      'ReviewScreen locks approve button when DO row unhandled and unlocks when handled',
      (tester) async {
        await openReview(
          tester,
          ReviewTestServer(
            rowsOverride: [
              evidenceRow(
                level: 'DO',
                matchLevel: 'DO',
                gradeLevel: 'DO',
                matchNote: 'Nghi lệch học sinh',
                numericValue: '8.0',
              ),
            ],
          ),
        );

        FilledButton approveButton() => tester.widget<FilledButton>(
          find.byKey(const ValueKey('review-approve')),
        );

        // Tick xác nhận: nút Duyệt vẫn vô hiệu vì dòng Đỏ chưa xử lý
        await tester.tap(find.byKey(const ValueKey('review-confirm-all')));
        await tester.pumpAndSettle();
        expect(approveButton().onPressed, isNull);

        // Nhập điểm hợp lệ cho dòng Đỏ -> nút Duyệt mở
        await tester.enterText(
          find.byKey(const ValueKey('review-value-r-1')),
          '8.0',
        );
        await tester.pumpAndSettle();
        expect(approveButton().onPressed, isNotNull);
      },
    );

    testWidgets(
      'ReviewScreen "Không ghi điểm" requires reason and sends value null with quick chip',
      (tester) async {
        final server = ReviewTestServer(
          rowsOverride: [
            evidenceRow(
              level: 'DO',
              matchLevel: 'DO',
              gradeLevel: 'DO',
              matchNote: 'Nghi lệch học sinh',
              numericValue: '8.0',
            ),
          ],
        );
        await openReview(tester, server);

        // Mở menu ⋮
        await tester.tap(find.byKey(const ValueKey('review-menu-r-1')));
        await tester.pumpAndSettle();

        // Chọn mục "Không ghi điểm (vắng/miễn…)"
        expect(find.text('Không ghi điểm (vắng/miễn…)'), findsOneWidget);
        await tester.tap(find.text('Không ghi điểm (vắng/miễn…)'));
        await tester.pumpAndSettle();

        // Ô lý do xuất hiện kèm các chip chọn nhanh
        expect(find.byKey(const ValueKey('review-reason-r-1')), findsOneWidget);
        expect(find.text('Vắng thi'), findsOneWidget);
        expect(find.text('Miễn'), findsOneWidget);
        expect(find.text('Nhập sau'), findsOneWidget);
        expect(find.text('Khác…'), findsOneWidget);

        // Thử nút "Hủy"
        expect(
          find.byKey(const ValueKey('review-cancel-empty-r-1')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('review-cancel-empty-r-1')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('review-reason-r-1')), findsNothing);

        // Mở lại menu ⋮ và chọn Không ghi điểm
        await tester.tap(find.byKey(const ValueKey('review-menu-r-1')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Không ghi điểm (vắng/miễn…)'));
        await tester.pumpAndSettle();

        // Bấm chip "Vắng thi"
        await tester.tap(find.text('Vắng thi'));
        await tester.pumpAndSettle();

        final reasonField = tester.widget<TextFormField>(
          find.byKey(const ValueKey('review-reason-r-1')),
        );
        expect(reasonField.controller?.text, 'Vắng thi');

        // Xác nhận và Duyệt
        await tester.tap(find.byKey(const ValueKey('review-confirm-all')));
        await tester.pumpAndSettle();

        FilledButton approveButton() => tester.widget<FilledButton>(
          find.byKey(const ValueKey('review-approve')),
        );
        expect(approveButton().onPressed, isNotNull);

        await tester.tap(find.byKey(const ValueKey('review-approve')));
        await tester.pumpAndSettle();

        expect(server.lastApprovalBody, isNotNull);
        final decisions =
            server.lastApprovalBody!['decisions'] as List<dynamic>;
        final dec = decisions.single as Map<String, dynamic>;
        expect(dec['value'], isNull);
        expect(dec['reason'], 'Vắng thi');
      },
    );

    testWidgets(
      'ReviewScreen in DA_DUYET status renders read-only banner and hides inputs, agree button and approve button',
      (tester) async {
        final server = ReviewTestServer(ticketStatus: 'DA_DUYET');
        await openReview(tester, server);

        // Banner chỉ xem
        expect(find.text('Phiếu đã duyệt — chỉ xem'), findsOneWidget);

        // Ẩn ô nhập điểm
        expect(
          find.byKey(const ValueKey('review-value-r-green')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('review-value-r-yellow')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('review-value-r-red')), findsNothing);

        // Ẩn menu ⋮
        expect(
          find.byKey(const ValueKey('review-menu-r-yellow')),
          findsNothing,
        );

        // Ẩn nút Đồng ý
        expect(
          find.byKey(const ValueKey('review-agree-r-yellow')),
          findsNothing,
        );

        // Ẩn ô xác nhận và nút Duyệt
        expect(find.byKey(const ValueKey('review-confirm-all')), findsNothing);
        expect(find.byKey(const ValueKey('review-approve')), findsNothing);
      },
    );

    testWidgets(
      'ReviewScreen shows placeholder "Không có ảnh họ tên" when nameCropUrl is null and matchLevel is VANG/DO',
      (tester) async {
        final server = ReviewTestServer(includeNameCrop: false);
        await openReview(tester, server);

        // matchLevel == XANH: ẩn ảnh họ tên
        // matchLevel == VANG (r-yellow) & DO (r-red): hiển thị placeholder
        expect(find.text('Không có ảnh họ tên'), findsNWidgets(2));
      },
    );

    testWidgets('mobile (320x640) uses PageView and next button switches row', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
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

      // Chế độ PageView trên mobile
      expect(find.byType(PageView), findsOneWidget);
      expect(find.textContaining('Dòng 1'), findsOneWidget);

      // Dòng 1 là Đỏ (ưu tiên sắp xếp đầu): nút là 'Tiếp ›'
      expect(find.text('Tiếp ›'), findsOneWidget);
      await tester.tap(find.text('Tiếp ›'));
      await tester.pumpAndSettle();

      // Chuyển sang dòng 2 (Vàng): nút là '✓ Đồng ý & tiếp'
      expect(find.textContaining('Dòng 2'), findsOneWidget);
      expect(find.text('✓ Đồng ý & tiếp'), findsOneWidget);
      await tester.tap(find.text('✓ Đồng ý & tiếp'));
      await tester.pumpAndSettle();

      // Chuyển sang trang tổng kết
      expect(find.textContaining('Trang tổng kết'), findsOneWidget);
    });

    testWidgets('web (1440x900) has source image column', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
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

      // Cột ảnh gốc trên desktop
      expect(
        find.byKey(const ValueKey('review-source-image-column')),
        findsOneWidget,
      );
    });

    testWidgets('STT equals: no STT mismatch box and no STT filter chip', (
      tester,
    ) async {
      await openReview(
        tester,
        ReviewTestServer(
          rowsOverride: [
            evidenceRow(
              level: 'XANH',
              matchLevel: 'XANH',
              gradeLevel: 'XANH',
              stt: 1,
              sttOnPaper: 1,
            ),
          ],
        ),
      );
      expect(find.byKey(const ValueKey('review-stt-box-r-1')), findsNothing);
      expect(find.byKey(const ValueKey('STT_DIFF')), findsNothing);
      expect(find.textContaining('STT giấy'), findsNothing);
    });

    testWidgets('STT mismatch + matchLevel XANH: shows info box, no checkbox', (
      tester,
    ) async {
      await openReview(
        tester,
        ReviewTestServer(
          rowsOverride: [
            evidenceRow(
              level: 'XANH',
              matchLevel: 'XANH',
              gradeLevel: 'XANH',
              stt: 1,
              sttOnPaper: 4,
              numericValue: '8.5',
            ),
          ],
        ),
      );
      // Tiêu đề có chip STT giấy
      expect(find.text('STT giấy 4 ≠ hệ thống 1'), findsOneWidget);
      // Khung thông tin
      expect(find.byKey(const ValueKey('review-stt-box-r-1')), findsOneWidget);
      expect(
        find.text('STT khác nhau: trên giấy là 4, trong hệ thống là 1'),
        findsOneWidget,
      );
      expect(
        find.text('Tờ giấy xếp tên khác hệ thống; đã ghép theo họ tên.'),
        findsOneWidget,
      );
      expect(find.text('Họ tên trên giấy'), findsOneWidget);
      // Không có checkbox xác nhận
      expect(find.text('Đúng học sinh này'), findsNothing);
      expect(
        find.byKey(const ValueKey('review-stt-confirm-r-1')),
        findsNothing,
      );
    });

    testWidgets(
      'STT mismatch + matchLevel VANG: shows warning box, locks approve until checked',
      (tester) async {
        final server = ReviewTestServer(
          rowsOverride: [
            evidenceRow(
              level: 'VANG',
              matchLevel: 'VANG',
              gradeLevel: 'XANH',
              stt: 2,
              sttOnPaper: 5,
              numericValue: '9.0',
            ),
          ],
        );
        await openReview(tester, server);

        // Tiêu đề có chip STT giấy
        expect(find.text('STT giấy 5 ≠ hệ thống 2'), findsOneWidget);
        // Khung cảnh báo
        expect(
          find.byKey(const ValueKey('review-stt-box-r-1')),
          findsOneWidget,
        );
        expect(
          find.text('STT không khớp: trên giấy là 5, trong hệ thống là 2'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Hãy kiểm tra ảnh họ tên có đúng là'),
          findsOneWidget,
        );
        expect(find.text('Họ tên trên giấy'), findsOneWidget);
        // Có checkbox
        expect(find.text('Đúng học sinh này'), findsOneWidget);

        // Bấm tick xác nhận tất cả ở bottom bar
        await tester.tap(find.byKey(const ValueKey('review-confirm-all')));
        await tester.pumpAndSettle();

        FilledButton approveButton() => tester.widget<FilledButton>(
          find.byKey(const ValueKey('review-approve')),
        );
        // Nút Duyệt vẫn vô hiệu vì chưa tích "Đúng học sinh này"
        expect(approveButton().onPressed, isNull);

        // Tích "Đúng học sinh này"
        await tester.tap(find.byKey(const ValueKey('review-stt-confirm-r-1')));
        await tester.pumpAndSettle();

        // Nút Duyệt mở
        expect(approveButton().onPressed, isNotNull);
      },
    );

    testWidgets('STT summary chip counts correctly and filters matching rows', (
      tester,
    ) async {
      final server = ReviewTestServer(
        rowsOverride: [
          evidenceRow(
            level: 'XANH',
            matchLevel: 'XANH',
            gradeLevel: 'XANH',
            stt: 1,
            sttOnPaper: 1,
          ),
          {
            ...evidenceRow(
              level: 'VANG',
              matchLevel: 'VANG',
              gradeLevel: 'XANH',
              stt: 2,
              sttOnPaper: 5,
            ),
            'rowId': 'r-2',
            'order': 2,
          },
          {
            ...evidenceRow(
              level: 'XANH',
              matchLevel: 'XANH',
              gradeLevel: 'XANH',
              stt: 3,
              sttOnPaper: 6,
            ),
            'rowId': 'r-3',
            'order': 3,
          },
        ],
      );
      await openReview(tester, server);

      // Chip tóm tắt hiển thị: 2 dòng khác
      expect(find.text('⇄ STT khác: 2'), findsOneWidget);

      // Mặc định hiện tất cả dòng có STT khác
      expect(find.byKey(const ValueKey('review-stt-box-r-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('review-stt-box-r-3')), findsOneWidget);

      // Bấm vào chip để lọc STT khác
      await tester.tap(
        find.byKey(const ValueKey('STT_DIFF')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Chỉ hiện 2 dòng có STT khác
      expect(find.byKey(const ValueKey('review-stt-box-r-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('review-stt-box-r-3')), findsOneWidget);
    });

    testWidgets(
      'Read-only DA_DUYET status still displays STT mismatch box without checkbox',
      (tester) async {
        final server = ReviewTestServer(
          ticketStatus: 'DA_DUYET',
          rowsOverride: [
            evidenceRow(
              level: 'VANG',
              matchLevel: 'VANG',
              gradeLevel: 'XANH',
              stt: 2,
              sttOnPaper: 5,
            ),
          ],
        );
        await openReview(tester, server);

        // Banner chỉ xem
        expect(find.text('Phiếu đã duyệt — chỉ xem'), findsOneWidget);

        // Vẫn hiện chip tiêu đề & khung ghi chú
        expect(find.text('STT giấy 5 ≠ hệ thống 2'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('review-stt-box-r-1')),
          findsOneWidget,
        );
        expect(
          find.text('STT không khớp: trên giấy là 5, trong hệ thống là 2'),
          findsOneWidget,
        );

        // KHÔNG có checkbox
        expect(find.text('Đúng học sinh này'), findsNothing);
        expect(
          find.byKey(const ValueKey('review-stt-confirm-r-1')),
          findsNothing,
        );
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

        await tester.tap(find.text('Nhận dạng bảng điểm từ ảnh'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'Không xác định được học sinh cho một số dòng. Kiểm tra đúng lớp và chụp lại rõ cột Họ tên.',
          ),
          findsOneWidget,
        );
      },
    );

    for (final size in [const Size(1440, 900), const Size(360, 800)]) {
      final modeName = size.width >= 600
          ? 'Web (1440x900)'
          : 'Mobile (360x800)';
      testWidgets(
        '$modeName confirms identical content: no forbidden text, reasons, inputs, STT mismatch, and blocking',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final server = ReviewTestServer(
            rowsOverride: [
              evidenceRow(
                level: 'DO',
                matchLevel: 'XANH',
                gradeLevel: 'DO',
                stt: 1,
                sttOnPaper: 1,
              )..addAll({
                'rowId': 'r-1',
                'order': 1,
                'studentName': 'Học sinh A',
              }),
              evidenceRow(
                level: 'VANG',
                matchLevel: 'VANG',
                gradeLevel: 'VANG',
                stt: 2,
                sttOnPaper: 5,
                numericValue: '7.0',
                writtenValue: '7.0',
              )..addAll({
                'rowId': 'r-2',
                'order': 2,
                'studentName': 'Học sinh B',
              }),
            ],
          );
          await openReview(tester, server, physicalSize: size);

          // 1. Không hiển thị các chuỗi cấm
          expect(find.textContaining('Ký tự thô'), findsNothing);
          expect(find.textContaining('Độ tin cậy'), findsNothing);
          expect(find.textContaining('Lấy theo'), findsNothing);
          expect(find.textContaining('khác nhau'), findsNothing);

          // 2. Đúng câu lý do
          expect(find.text('Nhập điểm theo ảnh'), findsWidgets);

          // 3. Đỏ để trống, Vàng điền sẵn
          final redField = tester.widget<TextFormField>(
            find.byKey(const ValueKey('review-value-r-1')),
          );
          expect(redField.controller?.text, isEmpty);

          // 4. Chip và khung STT khác nhau ở dòng r-2 (trên mobile pager có thể cần chuyển slide hoặc xem dạng danh sách)
          if (size.width < 600) {
            // Chuyển sang dòng 2 trên mobile pager
            await tester.tap(find.text('Tiếp ›'));
            await tester.pumpAndSettle();
          }

          final yellowField = tester.widget<TextFormField>(
            find.byKey(const ValueKey('review-value-r-2')),
          );
          expect(yellowField.controller?.text, '7.0');

          expect(find.text('STT giấy 5 ≠ hệ thống 2'), findsOneWidget);
          expect(
            find.byKey(const ValueKey('review-stt-box-r-2')),
            findsOneWidget,
          );
          expect(find.text('Đúng học sinh này'), findsOneWidget);

          // 5. Menu ⋮ và Không ghi điểm bắt buộc lý do (thực hiện ở r-2)
          await tester.tap(find.byKey(const ValueKey('review-menu-r-2')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('review-empty-r-2')));
          await tester.pumpAndSettle();
          expect(find.text('Không ghi điểm'), findsOneWidget);
          expect(find.text('Vắng thi'), findsOneWidget);
          await tester.tap(
            find.byKey(const ValueKey('review-cancel-empty-r-2')),
            warnIfMissed: false,
          );
          await tester.pumpAndSettle();

          // 6. Checkbox chặn duyệt phiếu
          if (size.width >= 600) {
            final approveBtn = tester.widget<FilledButton>(
              find.byKey(const ValueKey('review-approve')),
            );
            expect(approveBtn.onPressed, isNull);
          } else {
            // Trên mobile, nút duyệt ở trang tổng kết
            await tester.tap(find.text('✓ Đồng ý & tiếp'));
            await tester.pumpAndSettle();
            final approveBtn = tester.widget<FilledButton>(
              find.byKey(const ValueKey('review-approve')),
            );
            expect(approveBtn.onPressed, isNull);
          }
        },
      );
    }

    testWidgets(
      'ReviewScreen renders responsively at 320x568 with 1.3 text scale without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
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
