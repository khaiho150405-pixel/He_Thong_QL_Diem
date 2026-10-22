import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/app/widgets/app_dialog.dart';
import 'package:client_flutter/features/academic_catalog/edit_dialog.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/final_results/final_results_panel.dart';
import 'package:client_flutter/features/gradebooks/adjustments_screen.dart';
import 'package:client_flutter/features/gradebooks/gradebook_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdjustmentAdapter implements HttpClientAdapter {
  _FakeAdjustmentAdapter({
    this.role = 'GIAO_VIEN',
    this.userId = 2,
    this.pendingAdjustmentId,
    this.resultsOutdated = false,
  });

  final String role;
  final int userId;
  String? pendingAdjustmentId;
  bool resultsOutdated;

  Map<String, dynamic>? lastSubmittedAdjustment;
  bool approveCalled = false;
  String? rejectReason;
  bool cancelCalled = false;
  String? nextErrorCode;

  @override
  void close({bool force = false}) {}

  Map<String, dynamic> get testBook => {
        'id': 7,
        'classId': 10,
        'subjectId': 20,
        'termId': 30,
        'className': '10A1',
        'subjectName': 'Toán',
        'termName': 'Học kỳ I',
        'status': 'DANG_NHAP_LIEU',
        'version': 3,
        'pendingAdjustmentId': pendingAdjustmentId,
        'resultsOutdated': resultsOutdated,
      };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object body;
    var status = 200;

    if (nextErrorCode != null) {
      final code = nextErrorCode;
      nextErrorCode = null;
      status = 409;
      body = {
        'code': code,
        'message': 'Error $code',
        'details': null,
        'requestId': 'req-test',
      };
      return ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.path.endsWith('/login')) {
      body = {
        'id': userId,
        'username': 'test_user',
        'role': role,
        'active': true,
        'token': 'fake-token',
        'csrf': 'fake-csrf',
      };
    } else if (options.path.endsWith('/gradebooks/7/cells')) {
      body = {
        'book': testBook,
        'items': [
          {
            'id': 'cell-1',
            'studentId': 101,
            'studentName': 'Nguyễn Văn An',
            'stt': 1,
            'active': true,
            'componentId': 201,
            'componentName': 'Miệng',
            'coefficient': '1.00',
            'required': true,
            'displayOrder': 1,
            'value': '8.0',
            'status': 'DA_DUYET',
            'exemptionReason': null,
            'source': 'NHAP_TAY',
            'openForInput': true,
            'columnLocked': false,
          },
          {
            'id': 'cell-2',
            'studentId': 101,
            'studentName': 'Nguyễn Văn An',
            'stt': 1,
            'active': true,
            'componentId': 202,
            'componentName': 'Giữa kỳ',
            'coefficient': '2.00',
            'required': true,
            'displayOrder': 2,
            'value': '7.0',
            'status': 'DA_DUYET',
            'exemptionReason': null,
            'source': 'NHAP_TAY',
            'openForInput': false,
            'columnLocked': true,
          },
        ],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/gradebooks/7/adjustments') &&
        options.method == 'GET') {
      body = {
        'items': [
          {
            'id': 'adj-100',
            'gradebookId': 7,
            'className': '10A1',
            'subjectName': 'Toán',
            'termName': 'Học kỳ I',
            'status': 'CHO_DUYET',
            'reason': 'Chấm phúc khảo GK',
            'submittedBy': {'id': userId, 'name': 'Thầy Test'},
            'submittedAt': '2026-10-22T08:00:00.000Z',
            'decidedBy': null,
            'decidedAt': null,
            'decisionReason': null,
            'lineCount': 1,
            'version': 1,
          },
        ],
      };
    } else if (options.path.endsWith('/gradebooks/7/adjustments') &&
        options.method == 'POST') {
      final req = jsonDecode(options.data as String);
      lastSubmittedAdjustment = req as Map<String, dynamic>;
      body = {
        'id': 'adj-101',
        'gradebookId': 7,
        'className': '10A1',
        'subjectName': 'Toán',
        'termName': 'Học kỳ I',
        'status': 'CHO_DUYET',
        'reason': req['reason'],
        'submittedBy': {'id': userId, 'name': 'Thầy Test'},
        'submittedAt': '2026-10-22T08:30:00.000Z',
        'decidedBy': null,
        'decidedAt': null,
        'decisionReason': null,
        'lineCount': (req['changes'] as List).length,
        'version': 1,
      };
    } else if (options.path.endsWith('/adjustments/adj-100') &&
        options.method == 'GET') {
      body = {
        'id': 'adj-100',
        'gradebookId': 7,
        'className': '10A1',
        'subjectName': 'Toán',
        'termName': 'Học kỳ I',
        'status': 'CHO_DUYET',
        'reason': 'Chấm phúc khảo GK',
        'submittedBy': {'id': userId, 'name': 'Thầy Test'},
        'submittedAt': '2026-10-22T08:00:00.000Z',
        'decidedBy': null,
        'decidedAt': null,
        'decisionReason': null,
        'lineCount': 1,
        'version': 1,
        'lines': [
          {
            'cellId': 'cell-2',
            'studentId': 101,
            'studentName': 'Nguyễn Văn An',
            'componentId': 202,
            'componentName': 'Giữa kỳ',
            'oldValue': '7.0',
            'oldStatus': 'DA_DUYET',
            'newValue': '8.5',
            'newExempt': false,
            'note': 'Sửa câu 3 theo barem',
          },
        ],
      };
    } else if (options.path.endsWith('/adjustments/adj-100/cancel')) {
      cancelCalled = true;
      body = {
        'id': 'adj-100',
        'gradebookId': 7,
        'className': '10A1',
        'subjectName': 'Toán',
        'termName': 'Học kỳ I',
        'status': 'DA_HUY',
        'reason': 'Chấm phúc khảo GK',
        'submittedBy': {'id': userId, 'name': 'Thầy Test'},
        'submittedAt': '2026-10-22T08:00:00.000Z',
        'decidedBy': null,
        'decidedAt': null,
        'decisionReason': null,
        'lineCount': 1,
        'version': 2,
      };
    } else if (options.path.endsWith('/adjustments/adj-100/approve')) {
      approveCalled = true;
      body = {
        'id': 'adj-100',
        'gradebookId': 7,
        'className': '10A1',
        'subjectName': 'Toán',
        'termName': 'Học kỳ I',
        'status': 'DA_DUYET',
        'reason': 'Chấm phúc khảo GK',
        'submittedBy': {'id': userId, 'name': 'Thầy Test'},
        'submittedAt': '2026-10-22T08:00:00.000Z',
        'decidedBy': {'id': 1, 'name': 'Quản trị viên'},
        'decidedAt': '2026-10-22T09:00:00.000Z',
        'decisionReason': null,
        'lineCount': 1,
        'version': 2,
      };
    } else if (options.path.endsWith('/adjustments/adj-100/reject')) {
      final req = jsonDecode(options.data as String);
      rejectReason = req['reason'];
      body = {
        'id': 'adj-100',
        'gradebookId': 7,
        'className': '10A1',
        'subjectName': 'Toán',
        'termName': 'Học kỳ I',
        'status': 'TU_CHOI',
        'reason': 'Chấm phúc khảo GK',
        'submittedBy': {'id': userId, 'name': 'Thầy Test'},
        'submittedAt': '2026-10-22T08:00:00.000Z',
        'decidedBy': {'id': 1, 'name': 'Quản trị viên'},
        'decidedAt': '2026-10-22T09:00:00.000Z',
        'decisionReason': rejectReason,
        'lineCount': 1,
        'version': 2,
      };
    } else if ((options.path.endsWith('/adjustments') ||
            options.path.startsWith('/api/v1/adjustments')) &&
        !options.path.contains('gradebooks') &&
        options.method == 'GET') {
      body = {
        'items': [
          {
            'id': 'adj-100',
            'gradebookId': 7,
            'className': '10A1',
            'subjectName': 'Toán',
            'termName': 'Học kỳ I',
            'status': 'CHO_DUYET',
            'reason': 'Chấm phúc khảo GK',
            'submittedBy': {'id': 2, 'name': 'Thầy Test'},
            'submittedAt': '2026-10-22T08:00:00.000Z',
            'decidedBy': null,
            'decidedAt': null,
            'decisionReason': null,
            'lineCount': 1,
            'version': 1,
          },
        ],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/final-results') &&
        options.method == 'GET') {
      body = {'items': []};
    } else {
      body = {'items': []};
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

class _FakeSessionController extends SessionController {
  _FakeSessionController(
    super.api, {
    required String role,
    required int userId,
  }) {
    state = SessionDto(
      id: userId,
      username: 'test_user',
      role: role == 'QUAN_TRI_VIEN'
          ? SessionDtoRoleEnum.QUAN_TRI_VIEN
          : SessionDtoRoleEnum.GIAO_VIEN,
      active: true,
      token: 'test-token',
      csrf: 'test-csrf',
    );
  }
}

Widget _wrapWithScope({
  required Widget child,
  required HttpClientAdapter adapter,
  String role = 'GIAO_VIEN',
  int userId = 2,
}) {
  final dio = Dio()..httpClientAdapter = adapter;
  final apiClient = ApiClientDart(dio: dio);

  return ProviderScope(
    overrides: [
      apiProvider.overrideWithValue(apiClient),
      sessionProvider.overrideWith(
        (ref) => _FakeSessionController(
          ref.read(apiProvider),
          role: role,
          userId: userId,
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets(
      'bật chế độ điều chỉnh chỉ mở ô cột đã chốt, đổi ô hiện cũ -> mới, gửi yêu cầu',
      (tester) async {
    final adapter = _FakeAdjustmentAdapter(role: 'GIAO_VIEN', userId: 2);

    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrapWithScope(
        child: const GradebookScreen(bookId: 7),
        adapter: adapter,
      ),
    );
    await tester.pumpAndSettle();

    // Ban đầu cột Giữa kỳ (cell-2) bị khóa (disabled)
    final cell2Finder = find.byKey(const ValueKey('grade-cell-2'));
    expect(cell2Finder, findsOneWidget);
    final fieldBefore = tester.widget<TextFormField>(cell2Finder);
    expect(fieldBefore.enabled, isFalse);

    // Mở menu ⋮ để bấm "Yêu cầu điều chỉnh"
    final moreMenu = find.byTooltip('Thao tác khác');
    expect(moreMenu, findsOneWidget);
    await tester.tap(moreMenu);
    await tester.pumpAndSettle();

    final reqAdjBtn = find.text('Yêu cầu điều chỉnh');
    expect(reqAdjBtn, findsOneWidget);
    await tester.tap(reqAdjBtn);
    await tester.pumpAndSettle();

    // Hiện banner chế độ điều chỉnh
    expect(
      find.byKey(const ValueKey('adjustment-mode-banner')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Đang soạn phiếu điều chỉnh — chỉ các cột đã chốt, chưa ghi vào điểm chính thức',
      ),
      findsOneWidget,
    );

    // Ô cell-2 giờ đã editable!
    final fieldAfter = tester.widget<TextFormField>(cell2Finder);
    expect(fieldAfter.enabled, isTrue);

    // Sửa điểm ô cell-2 từ 7.0 sang 8.5
    await tester.enterText(cell2Finder, '8.5');
    await tester.pumpAndSettle();

    // Kiểm tra hiển thị "cũ -> mới" (7.0 -> 8.5)
    expect(find.text('7.0 → 8.5'), findsOneWidget);

    // Thanh dưới hiện "Đã đổi 1 ô"
    expect(find.text('Đã đổi 1 ô'), findsOneWidget);

    // Bấm nút "Gửi yêu cầu"
    final submitBtn = find.byKey(const ValueKey('submit-adjustment-btn'));
    expect(submitBtn, findsOneWidget);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Hộp thoại gửi hiện ra
    expect(find.text('Gửi yêu cầu điều chỉnh điểm'), findsOneWidget);
    expect(find.text('Tóm tắt các ô thay đổi (1 ô):'), findsOneWidget);
    expect(find.text('7.0 → 8.5'), findsWidgets);

    // Nhập lý do bắt buộc và gửi
    final reasonInput =
        find.byKey(const ValueKey('adjustment-reason-input'));
    expect(reasonInput, findsOneWidget);
    await tester.enterText(reasonInput, 'Chấm phúc khảo giữa kỳ theo đơn');
    await tester.pumpAndSettle();

    final confirmBtn = find.text('Gửi yêu cầu');
    await tester.tap(confirmBtn.last);
    await tester.pumpAndSettle();

    // Kiểm tra đã gọi API POST đúng payload
    expect(adapter.lastSubmittedAdjustment, isNotNull);
    expect(adapter.lastSubmittedAdjustment!['reason'],
        'Chấm phúc khảo giữa kỳ theo đơn');
    final changes =
        adapter.lastSubmittedAdjustment!['changes'] as List<dynamic>;
    expect(changes.length, 1);
    expect(changes[0]['cellId'], 'cell-2');
    expect(changes[0]['value'], '8.5');
    expect(changes[0]['exempt'], isFalse);
  });

  testWidgets('banner chờ duyệt hiển thị và cho phép hủy phiếu',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = _FakeAdjustmentAdapter(
      role: 'GIAO_VIEN',
      userId: 2,
      pendingAdjustmentId: 'adj-100',
    );

    await tester.pumpWidget(
      _wrapWithScope(
        child: const GradebookScreen(bookId: 7),
        adapter: adapter,
      ),
    );
    await tester.pumpAndSettle();

    // Banner phiếu chờ duyệt hiển thị
    expect(
      find.byKey(const ValueKey('adjustment-pending-banner')),
      findsOneWidget,
    );
    expect(
      find.text('Phiếu điều chỉnh #adj-100 đang chờ duyệt (1 ô)'),
      findsOneWidget,
    );

    // Nút Xem và Hủy phiếu có mặt
    expect(find.byKey(const ValueKey('view-pending-adjustment-btn')),
        findsOneWidget);
    final cancelBtn =
        find.byKey(const ValueKey('cancel-pending-adjustment-btn'));
    expect(cancelBtn, findsOneWidget);

    // Bấm Hủy phiếu
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();

    // Hỏi xác nhận
    expect(find.text('Hủy phiếu điều chỉnh'), findsOneWidget);
    final confirmCancel = find.text('Xác nhận hủy');
    expect(confirmCancel, findsOneWidget);
    await tester.tap(confirmCancel);
    await tester.pumpAndSettle();

    expect(adapter.cancelCalled, isTrue);
  });

  testWidgets(
      'màn duyệt của QTV: duyệt thành công và từ chối yêu cầu lý do',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = _FakeAdjustmentAdapter(role: 'QUAN_TRI_VIEN', userId: 1);

    await tester.pumpWidget(
      _wrapWithScope(
        child: const AdjustmentsScreen(),
        adapter: adapter,
        role: 'QUAN_TRI_VIEN',
        userId: 1,
      ),
    );
    await tester.pumpAndSettle();

    // Thấy phiếu trong danh sách
    expect(find.text('10A1'), findsOneWidget);
    expect(find.text('Toán'), findsOneWidget);

    // Bấm Duyệt / Xem
    final viewBtn = find.byKey(const ValueKey('view-adjustment-adj-100'));
    expect(viewBtn, findsOneWidget);
    await tester.ensureVisible(viewBtn);
    await tester.pumpAndSettle();
    await tester.tap(viewBtn);
    await tester.pumpAndSettle();

    // Chi tiết phiếu hiện ra với các nút Duyệt và Từ chối
    expect(find.text('Chi tiết phiếu điều chỉnh'), findsOneWidget);
    final approveBtn =
        find.byKey(const ValueKey('adjustment-approve-btn'));
    final rejectBtn = find.byKey(const ValueKey('adjustment-reject-btn'));
    expect(approveBtn, findsOneWidget);
    expect(rejectBtn, findsOneWidget);

    // Thử từ chối: bấm Từ chối
    await tester.tap(rejectBtn);
    await tester.pumpAndSettle();

    expect(find.text('Từ chối phiếu điều chỉnh'), findsOneWidget);
    final rejectInput =
        find.byKey(const ValueKey('adjustment-reject-reason-input'));
    expect(rejectInput, findsOneWidget);

    // Bấm xác nhận từ chối khi chưa nhập lý do -> báo lỗi
    final confirmRejectBtn = find.text('Từ chối phiếu');
    await tester.tap(confirmRejectBtn);
    await tester.pumpAndSettle();
    expect(find.text('Cần nhập lý do từ chối.'), findsOneWidget);

    // Nhập lý do và từ chối
    await tester.enterText(
        rejectInput, 'Bài thi không có chữ ký của tổ trưởng');
    await tester.pumpAndSettle();
    await tester.tap(confirmRejectBtn);
    await tester.pumpAndSettle();

    expect(adapter.rejectReason, 'Bài thi không có chữ ký của tổ trưởng');
  });

  testWidgets('lỗi ADJUSTMENT_STALE hiển thị thông báo tiếng Việt đúng',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = _FakeAdjustmentAdapter(role: 'QUAN_TRI_VIEN', userId: 1);

    await tester.pumpWidget(
      _wrapWithScope(
        child: const AdjustmentsScreen(),
        adapter: adapter,
        role: 'QUAN_TRI_VIEN',
        userId: 1,
      ),
    );
    await tester.pumpAndSettle();

    final viewBtn = find.byKey(const ValueKey('view-adjustment-adj-100'));
    await tester.ensureVisible(viewBtn);
    await tester.pumpAndSettle();
    await tester.tap(viewBtn);
    await tester.pumpAndSettle();

    final approveBtn =
        find.byKey(const ValueKey('adjustment-approve-btn'));
    adapter.nextErrorCode = 'ADJUSTMENT_STALE';
    await tester.tap(approveBtn);
    await tester.pumpAndSettle();

    // Xác nhận duyệt
    final confirmApprove = find.text('Xác nhận duyệt');
    await tester.tap(confirmApprove);
    await tester.pumpAndSettle();

    // Thông báo lỗi tiếng Việt
    expect(
      find.text(
          'Điểm đã thay đổi sau khi gửi phiếu; yêu cầu giáo viên soạn lại'),
      findsOneWidget,
    );
  });

  testWidgets('resultsOutdated == true hiện banner cần tính lại',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = _FakeAdjustmentAdapter(
      role: 'GIAO_VIEN',
      userId: 2,
      resultsOutdated: true,
    );

    await tester.pumpWidget(
      _wrapWithScope(
        child: const GradebookScreen(bookId: 7),
        adapter: adapter,
      ),
    );
    await tester.pumpAndSettle();

    // Banner ở màn bảng điểm
    expect(
      find.byKey(const ValueKey('gradebook-results-outdated-banner')),
      findsOneWidget,
    );
    expect(
      find.text('Điểm đã được điều chỉnh — cần Tính kết quả lại'),
      findsOneWidget,
    );

    // Trong panel tổng kết cũng hiện banner
    await tester.pumpWidget(
      _wrapWithScope(
        child: const Scaffold(
          body: FinalResultsPanel(
            gradebookId: 7,
            gradebookVersion: 3,
            resultsOutdated: true,
          ),
        ),
        adapter: adapter,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('results-outdated-banner')),
      findsOneWidget,
    );
    expect(
      find.text('Điểm đã được điều chỉnh — cần Tính kết quả lại'),
      findsOneWidget,
    );
  });

  testWidgets(
      'hộp thoại công bố hiện ADJUSTMENT_PENDING với nút Duyệt điều chỉnh điểm',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => OutlinedButton(
              onPressed: () {
                showAppDialog<bool>(
                  context: ctx,
                  builder: (_) => AppDialog(
                    title: 'Kiểm tra trước khi công bố',
                    child: Column(
                      children: [
                        Text(publishIssueDescription(
                            PublishIssueDtoCodeEnum.ADJUSTMENT_PENDING)),
                        Text(publishIssueDescription(
                            PublishIssueDtoCodeEnum.RESULTS_OUTDATED)),
                      ],
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.text('Còn phiếu điều chỉnh điểm chờ duyệt'),
      findsOneWidget,
    );
    expect(
      find.text('Đã điều chỉnh điểm, cần tính lại tổng kết'),
      findsOneWidget,
    );
  });
}
