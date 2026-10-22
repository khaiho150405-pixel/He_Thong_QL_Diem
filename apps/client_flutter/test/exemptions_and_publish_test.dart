import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/features/academic_catalog/edit_dialog.dart';
import 'package:client_flutter/features/academic_catalog/semester_deadlines_repository.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/final_results/final_results_panel.dart';
import 'package:client_flutter/features/final_results/repository.dart';
import 'package:client_flutter/features/recognition/review/review_row_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({this.role = 'GIAO_VIEN', this.missingStudentsList = const []});

  final String role;
  final List<Map<String, dynamic>> missingStudentsList;

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
        'id': role == 'QUAN_TRI_VIEN' ? 1 : 2,
        'username': 'test_user',
        'role': role,
        'active': true,
        'token': 'fake-token',
        'csrf': 'fake-csrf',
      };
    } else if (options.path.endsWith('/gradebooks/10/cells')) {
      body = {
        'book': {
          'id': 10,
          'classId': 101,
          'subjectId': 201,
          'termId': 301,
          'className': '10A1',
          'subjectName': 'Toán',
          'termName': 'Học kỳ I',
          'status': 'DANG_NHAP_LIEU',
          'version': 1,
          'pendingAdjustmentId': null,
          'resultsOutdated': false,
        },
        'items': [
          {
            'id': 'cell-1',
            'studentId': 1,
            'studentName': 'Nguyễn Văn A',
            'stt': 1,
            'active': true,
            'componentId': 11,
            'componentName': 'Miệng',
            'coefficient': '1.00',
            'required': true,
            'displayOrder': 1,
            'value': null,
            'status': 'MIEN',
            'exemptionReason': 'Có giấy miễn y tế',
            'source': 'NHAP_TAY',
            'openForInput': true,
            'columnLocked': false,
          },
          {
            'id': 'cell-2',
            'studentId': 2,
            'studentName': 'Trần Thị B',
            'stt': 2,
            'active': true,
            'componentId': 11,
            'componentName': 'Miệng',
            'coefficient': '1.00',
            'required': true,
            'displayOrder': 1,
            'value': null,
            'status': 'CHUA_CO',
            'exemptionReason': null,
            'source': 'NHAP_TAY',
            'openForInput': true,
            'columnLocked': false,
          },
        ],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/gradebooks/10/missing-students')) {
      body = {
        'items': missingStudentsList,
      };
    } else {
      status = 404;
      body = {'code': 'NOT_FOUND'};
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

class FakeDeadlinesRepo implements SemesterDeadlinesRepository {
  FakeDeadlinesRepo({required this.readinessDto});

  final PublishReadinessDto readinessDto;

  @override
  Future<PublishReadinessDto> publishReadiness(num semesterId) async {
    return readinessDto;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFinalResultsRepo extends FinalResultsRepository {
  FakeFinalResultsRepo({this.listDto}) : super(ApiClientDart());

  final FinalResultListDto? listDto;

  @override
  Future<FinalResultListDto> list(num gradebookId) async =>
      listDto ??
      FinalResultListDto(
        items: [
          FinalResultDto(
            id: 'res-1',
            studentId: 1,
            studentName: 'Nguyễn Văn A',
            finalScore: '8.5',
            classification: 'GIOI',
            calculatedAt: DateTime.parse('2026-10-22T08:00:00Z'),
            weightVersion: 'W-1',
            policyVersion: '1.0',
          ),
        ],
        nextCursor: null,
        exemptedStudents: 1,
        exempted: [
          ExemptedStudentDto(studentId: 2, studentName: 'Học sinh được miễn'),
        ],
        skippedStudents: 1,
        skipped: [
          SkippedStudentDto(
            studentId: 1,
            studentName: 'Học sinh thiếu điểm',
            missingComponents: [
              MissingComponentDto(componentId: 1, name: 'CK'),
            ],
          ),
        ],
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Ô Miễn hiển thị nhãn "Miễn", không cho gõ và QTV thấy banner missing-students',
    (tester) async {
      final adapter = _FakeAdapter(
        role: 'QUAN_TRI_VIEN',
        missingStudentsList: [
          {'studentId': 99, 'studentName': 'Lê Văn Muộn'},
        ],
      );
      final api = ApiClientDart(dio: Dio()..httpClientAdapter = adapter);
      final container = ProviderContainer(
        overrides: [apiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      await tester.runAsync(
        () => container
            .read(sessionProvider.notifier)
            .login('test_user', 'password'),
      );

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const GradebookApp(initialLocation: '/gradebooks/10'),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra ô Miễn
      expect(find.text('Miễn'), findsWidgets);

      // Kiểm tra banner QTV missing-students
      expect(
        find.text('Có 1 học sinh vào lớp sau khi cột đã chốt'),
        findsOneWidget,
      );
      expect(find.text('Lê Văn Muộn'), findsOneWidget);
      expect(find.text('Xử lý'), findsOneWidget);

      // Bấm Xử lý mở hộp thoại lý do bắt buộc
      await tester.tap(find.text('Xử lý'));
      await tester.pumpAndSettle();

      expect(find.text('Xử lý học sinh vào muộn'), findsOneWidget);
      // Bấm Xác nhận khi chưa nhập lý do -> validator báo lỗi
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(find.text('Cần nhập lý do.'), findsOneWidget);
    },
  );

  testWidgets('Tổng kết hiển thị nhóm Miễn môn tách khỏi Thiếu điểm', (
    tester,
  ) async {
    final summary = CalculateFinalResultsDto(
      gradebookId: 10,
      gradebookVersion: 1,
      weightVersion: 'W1',
      policyVersion: 'P1',
      calculatedStudents: 10,
      skippedStudents: 1,
      exemptedStudents: 1,
      results: [],
      skipped: [
        SkippedStudentDto(
          studentId: 1,
          studentName: 'Học sinh thiếu điểm',
          missingComponents: [
            MissingComponentDto(componentId: 1, name: 'CK'),
          ],
        ),
      ],
      exempted: [
        ExemptedStudentDto(studentId: 2, studentName: 'Học sinh được miễn'),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        finalResultsRepositoryProvider.overrideWithValue(FakeFinalResultsRepo()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: FinalResultsPanel(
                gradebookId: 10,
                gradebookVersion: 1,
                initialSummary: summary,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('group-tab-exempted')), findsOneWidget);
    expect(find.byKey(const ValueKey('group-tab-skipped')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('group-tab-exempted')));
    await tester.pumpAndSettle();
    expect(find.text('Học sinh được miễn'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('group-tab-skipped')));
    await tester.pumpAndSettle();
    expect(find.text('Học sinh thiếu điểm'), findsOneWidget);
    expect(find.text('CK'), findsOneWidget);
  });

  testWidgets(
    'Dòng đối chiếu exempt:true hiển thị nhãn Miễn và khóa ở để trống',
    (tester) async {
      final valueCtrl = TextEditingController();
      final reasonCtrl = TextEditingController(
        text: 'Học sinh được miễn cột này',
      );

      final row = RecognitionEvidenceRowDto.fromJson({
        'rowId': 'row-1',
        'order': 1,
        'stt': 1,
        'sttOnPaper': 1,
        'studentId': 10,
        'studentName': 'Phạm Minh C',
        'nameRead': 'Pham Minh C',
        'matchConfidence': '0.99',
        'matchNote': null,
        'numericRaw': null,
        'numericValue': null,
        'numericConfidence': null,
        'writtenRaw': null,
        'writtenValue': null,
        'writtenConfidence': null,
        'comparison': 'KHONG_DOC_DUOC',
        'suggestedSource': null,
        'finalValue': null,
        'reviewLevel': 'DO',
        'gradeLevel': 'DO',
        'matchLevel': 'XANH',
        'numericCropUrl': 'https://storage.test/num.png',
        'writtenCropUrl': 'https://storage.test/text.png',
        'nameCropUrl': 'https://storage.test/name.png',
        'exempt': true,
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ReviewRowCard(
              row: row,
              valueController: valueCtrl,
              reasonController: reasonCtrl,
              isLeavingEmpty: true,
              isAgreedYellow: false,
              enabled: false,
              focusNode: FocusNode(),
              onFocusNext: null,
              onGradeChanged: (_) {},
              onReasonChanged: (_) {},
              onLeaveEmpty: () {},
              onCancelLeaveEmpty: () {},
              onAgreeYellow: () {},
              onRefresh: () async {},
              isDesktop: true,
              readOnly: false,
              isSttConfirmed: true,
              onSttConfirmedChanged: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra nhãn Miễn
      expect(find.text('Miễn'), findsOneWidget);
      expect(find.text('Học sinh được miễn'), findsOneWidget);
      // Kiểm tra lý do điền sẵn
      expect(find.text('Học sinh được miễn cột này'), findsWidgets);
    },
  );

  testWidgets(
    'PublishReadinessDialog hiển thị đủ các nhóm issue và chặn lưu khi ready=false',
    (tester) async {
      final issues = [
        PublishIssueDto(
          code: PublishIssueDtoCodeEnum.GRADEBOOK_MISSING,
          severity: PublishIssueDtoSeverityEnum.BLOCKING,
          classId: 1,
          className: '10A1',
          subjectId: 1,
          subjectName: 'Toán',
          gradebookId: null,
          studentIds: null,
          count: null,
        ),
        PublishIssueDto(
          code: PublishIssueDtoCodeEnum.GRADEBOOK_NOT_LOCKED,
          severity: PublishIssueDtoSeverityEnum.BLOCKING,
          classId: 2,
          className: '10A2',
          subjectId: 2,
          subjectName: 'Văn',
          gradebookId: 102,
          studentIds: null,
          count: null,
        ),
        PublishIssueDto(
          code: PublishIssueDtoCodeEnum.COLUMNS_WITHOUT_DEADLINE,
          severity: PublishIssueDtoSeverityEnum.WARNING,
          classId: 3,
          className: '10A3',
          subjectId: 3,
          subjectName: 'Anh',
          gradebookId: 103,
          studentIds: null,
          count: null,
        ),
      ];

      final repo = FakeDeadlinesRepo(
        readinessDto: PublishReadinessDto(ready: false, issues: issues),
      );

      final container = ProviderContainer(
        overrides: [semesterDeadlinesRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: PublishReadinessDialog(semesterId: 1),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra các nhóm và mô tả
      expect(find.text('Chưa có bảng điểm'), findsOneWidget);
      expect(
        find.text(
          'Chưa có bảng điểm — dùng Khởi tạo bảng điểm ở màn Lịch nhập điểm học kỳ',
        ),
        findsOneWidget,
      );

      expect(find.text('Bảng điểm chưa chốt'), findsOneWidget);
      expect(
        find.text(
          'Bảng điểm chưa chốt (còn cột chưa hết hạn hoặc chưa có lịch)',
        ),
        findsOneWidget,
      );

      expect(find.text('Cột chưa có lịch nhập (Cảnh báo)'), findsOneWidget);
      expect(find.text('Có cột chưa có lịch nhập'), findsOneWidget);

      // Có nút Mở bảng điểm cho dòng có gradebookId
      expect(find.byKey(const ValueKey('open-gradebook-102')), findsOneWidget);

      // Nút Xác nhận công bố bị disable khi ready == false
      final confirmBtn = tester.widget<FilledButton>(
        find.byKey(const ValueKey('app-dialog-confirm')),
      );
      expect(confirmBtn.onPressed, isNull);
    },
  );

  testWidgets(
    'GV đánh dấu miễn trên ô trống hiển thị hộp thoại lý do bắt buộc',
    (tester) async {
      final adapter = _FakeAdapter(role: 'GIAO_VIEN');
      final api = ApiClientDart(dio: Dio()..httpClientAdapter = adapter);
      final container = ProviderContainer(
        overrides: [apiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      await tester.runAsync(
        () => container
            .read(sessionProvider.notifier)
            .login('test_user', 'password'),
      );

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const GradebookApp(initialLocation: '/gradebooks/10'),
        ),
      );
      await tester.pumpAndSettle();

      // cell-2 là ô trống của cột mở -> có menu Đánh dấu miễn
      await tester.tap(find.byKey(const ValueKey('cell-menu-cell-2')));
      await tester.pumpAndSettle();

      expect(find.text('Đánh dấu miễn'), findsOneWidget);
      await tester.tap(find.text('Đánh dấu miễn'));
      await tester.pumpAndSettle();

      expect(find.text('Đánh dấu miễn'), findsWidgets);
      // Bấm Xác nhận khi chưa có lý do -> báo lỗi
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(find.text('Cần nhập lý do.'), findsOneWidget);
    },
  );
}

