import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/features/academic_catalog/academic_year_scope.dart';
import 'package:client_flutter/features/academic_catalog/semester_deadlines_repository.dart';
import 'package:client_flutter/features/academic_catalog/semester_deadlines_screen.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/final_results/student_results_screen.dart';
import 'package:client_flutter/features/gradebooks/grade_deadlines_panel.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSessionController extends StateNotifier<SessionDto?>
    implements SessionController {
  _FakeSessionController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDeadlinesRepo implements SemesterDeadlinesRepository {
  _FakeDeadlinesRepo({
    required this.semesters,
    required this.deadlines,
  });

  final List<SemestersDto> semesters;
  final SemesterDeadlinesDto deadlines;

  @override
  Future<List<SemestersDto>> listSemesters({num? yearId}) async {
    if (yearId == null) return semesters;
    return semesters.where((s) => s.maNamHoc == yearId).toList();
  }

  @override
  Future<SemesterDeadlinesDto> getDeadlines(num semesterId) async => deadlines;

  @override
  Future<SemesterDeadlineDto> setDeadline({
    required num semesterId,
    required String type,
    required DateTime opensAt,
    required DateTime closesAt,
    required num expectedVersion,
  }) async =>
      SemesterDeadlineDto(
        type: SemesterDeadlineDtoTypeEnum.values.firstWhere(
          (e) => e.value == type,
          orElse: () => SemesterDeadlineDtoTypeEnum.TX,
        ),
        opensAt: opensAt,
        closesAt: closesAt,
        version: expectedVersion + 1,
        expired: false,
      );

  @override
  Future<InitializeGradebooksResultDto> initializeGradebooks({
    required num semesterId,
    required String idempotencyKey,
  }) async =>
      InitializeGradebooksResultDto(
        created: [],
        skipped: [],
      );

  @override
  Future<PublishReadinessDto> publishReadiness(num semesterId) async =>
      PublishReadinessDto(
        ready: true,
        issues: [],
      );
}

class _GradebookFakeServer implements HttpClientAdapter {
  int version = 2;
  String? nextErrorCode;

  @override
  void close({bool force = false}) {}

  Map<String, dynamic> get book => {
        'id': 7,
        'classId': 10,
        'subjectId': 20,
        'termId': 30,
        'className': '10A1',
        'subjectName': 'Toán',
        'termName': 'Học kỳ I',
        'status': 'DANG_NHAP_LIEU',
        'version': version,
        'resultsOutdated': false,
        'pendingAdjustmentId': null,
      };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body;
    var status = 200;

    if (options.path.endsWith('/login')) {
      body = {
        'id': 2,
        'username': 'giao_vien_test',
        'role': 'GIAO_VIEN',
        'active': true,
        'token': 'tok',
        'csrf': 'csrf',
      };
    } else if (options.path.endsWith('/gradebooks/7/cells')) {
      body = {
        'book': book,
        'items': [
          {
            'id': '9001',
            'studentId': 101,
            'studentName': 'Nguyễn Văn An',
            'stt': 1,
            'active': true,
            'componentId': 201,
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
    } else if (options.path.endsWith('/gradebooks/7/missing-students')) {
      body = {'items': []};
    } else if (options.path.endsWith('/gradebooks/7/grades')) {
      if (nextErrorCode != null) {
        status = 409;
        body = {
          'code': nextErrorCode,
          'message': 'Thao tác không được phép',
          'details': null,
          'requestId': 'req-test',
        };
        nextErrorCode = null;
      } else {
        version++;
        body = {
          'items': [
            {'id': '9001', 'value': '8.5', 'status': 'DA_DUYET'},
          ],
          'bookId': 7,
          'version': version,
        };
      }
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

void main() {
  final session = SessionDto(
    id: 1,
    username: 'admin',
    role: SessionDtoRoleEnum.QUAN_TRI_VIEN,
    active: true,
    token: 'tok',
    csrf: 'csrf',
  );

  final mockYears = [
    {'ma_nam_hoc': 2024, 'ten': '2024-2025', 'hien_hanh': false},
    {'ma_nam_hoc': 2026, 'ten': '2026-2027', 'hien_hanh': true},
  ];

  final mockSemesters = [
    SemestersDto(
      maHocKy: 1,
      ten: 'Học kỳ 1',
      maNamHoc: 2026,
      thuTu: 1,
      ngayBatDau: '2026-09-05',
      ngayKetThuc: '2027-01-15',
      label: 'HK1 (2026-2027)',
    ),
  ];

  group('Lỗi 1: Chọn giờ 23:40 ở chế độ gõ phím được chấp nhận', () {
    testWidgets('trên màn Lịch học kỳ (SemesterDeadlinesScreen)', (tester) async {
      final repo = _FakeDeadlinesRepo(
        semesters: mockSemesters,
        deadlines: SemesterDeadlinesDto(
          items: [
            SemesterDeadlineDto(
              type: SemesterDeadlineDtoTypeEnum.TX,
              opensAt: DateTime.utc(2026, 9, 10, 8, 0),
              closesAt: DateTime.utc(2026, 12, 30, 23, 59),
              version: 1,
              expired: false,
            ),
          ],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          semesterDeadlinesRepositoryProvider.overrideWithValue(repo),
          sessionProvider.overrideWith((ref) => _FakeSessionController(session)),
          academicYearsProvider.overrideWith((ref) => mockYears),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SemesterDeadlinesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bấm Sửa lịch
      await tester.tap(find.text('Sửa lịch'));
      await tester.pumpAndSettle();

      // Bấm nút Mở nhập để mở DatePicker & TimePicker
      await tester.tap(find.textContaining('Mở nhập:'));
      await tester.pumpAndSettle();

      // Chọn ngày xong -> ấn OK trên DatePickerDialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // TimePicker hiện ra: chuyển sang chế độ gõ phím (icon keyboard)
      final keyboardIcon = find.byIcon(Icons.keyboard_outlined);
      expect(keyboardIcon, findsOneWidget);
      await tester.tap(keyboardIcon);
      await tester.pumpAndSettle();

      // Nhập giờ 23, phút 40
      final textFields = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextField),
      );
      expect(textFields, findsNWidgets(2));
      await tester.enterText(textFields.first, '23');
      await tester.enterText(textFields.last, '40');

      // Bấm OK trên TimePickerDialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Không có lỗi "Nhập thời gian hợp lệ"
      expect(find.text('Nhập thời gian hợp lệ'), findsNothing);
      expect(find.text('Enter a valid time'), findsNothing);

      // Nhãn nút đã cập nhật thành 23:40
      expect(find.textContaining('23:40'), findsOneWidget);
    });

    testWidgets('trên GradeDeadlinesPanel (_DeadlineDialog)', (tester) async {
      final col = GradeCellDto.fromJson({
        'id': '101',
        'studentId': 1,
        'studentName': 'Nguyen Van A',
        'stt': 1,
        'active': true,
        'componentId': 1,
        'componentName': 'Giữa kỳ',
        'coefficient': '1.00',
        'required': true,
        'displayOrder': 1,
        'value': null,
        'status': 'CHUA_CO',
        'exemptionReason': null,
        'source': 'NHAP_TAY',
        'opensAt': '2026-10-01T08:00:00.000Z',
        'closesAt': '2026-10-30T17:00:00.000Z',
        'deadlineVersion': 1,
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GradeDeadlinesPanel(
                bookId: 10,
                components: [col],
                isAdmin: true,
                locked: false,
                onReload: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bấm Đặt lịch riêng cho bảng này
      await tester.tap(find.text('Đặt lịch riêng cho bảng này'));
      await tester.pumpAndSettle();

      // Bấm Mở nhập
      await tester.tap(find.textContaining('Mở nhập:'));
      await tester.pumpAndSettle();

      // Chọn ngày -> OK
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Chuyển sang gõ phím
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();

      // Nhập 23:40
      final textFields = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(textFields.first, '23');
      await tester.enterText(textFields.last, '40');

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Nhập thời gian hợp lệ'), findsNothing);
      expect(find.textContaining('23:40'), findsOneWidget);
    });
  });

  group('Lỗi 2: Thẻ có opensAt tương lai hiện "Chưa mở" (màu trung tính)', () {
    testWidgets('trên màn Lịch học kỳ', (tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 10));
      final repo = _FakeDeadlinesRepo(
        semesters: mockSemesters,
        deadlines: SemesterDeadlinesDto(
          items: [
            SemesterDeadlineDto(
              type: SemesterDeadlineDtoTypeEnum.TX,
              opensAt: futureDate,
              closesAt: futureDate.add(const Duration(days: 7)),
              version: 1,
              expired: false,
            ),
            SemesterDeadlineDto(
              type: SemesterDeadlineDtoTypeEnum.GK,
              opensAt: null,
              closesAt: null,
              version: 0,
              expired: false,
            ),
          ],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          semesterDeadlinesRepositoryProvider.overrideWithValue(repo),
          sessionProvider.overrideWith((ref) => _FakeSessionController(session)),
          academicYearsProvider.overrideWith((ref) => mockYears),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SemesterDeadlinesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // opensAt tương lai -> "Chưa mở"
      expect(find.text('Chưa mở'), findsOneWidget);
      // closesAt null -> "Chưa đặt lịch"
      expect(find.text('Chưa đặt lịch'), findsOneWidget);
      // Không hiện "Đang hiệu lực"
      expect(find.text('Đang hiệu lực'), findsNothing);
    });

    testWidgets('trên GradeDeadlinesPanel', (tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final colFuture = GradeCellDto.fromJson({
        'id': '101',
        'studentId': 1,
        'studentName': 'Nguyen Van A',
        'stt': 1,
        'active': true,
        'componentId': 1,
        'componentName': 'Điểm TX',
        'coefficient': '1.00',
        'required': true,
        'displayOrder': 1,
        'value': null,
        'status': 'CHUA_CO',
        'exemptionReason': null,
        'source': 'NHAP_TAY',
        'opensAt': futureDate.toIso8601String(),
        'closesAt': futureDate.add(const Duration(days: 5)).toIso8601String(),
        'deadlineVersion': 1,
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GradeDeadlinesPanel(
                bookId: 10,
                components: [colFuture],
                isAdmin: true,
                locked: false,
                onReload: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa mở'), findsOneWidget);
      expect(find.text('Đang hiệu lực'), findsNothing);
    });
  });

  group('Lỗi 3: Ô chọn năm trên màn lịch học kỳ không có "Tất cả"', () {
    testWidgets('không có mục "Tất cả các năm" và dùng năm hiện hành nếu viewingYear là all',
        (tester) async {
      final repo = _FakeDeadlinesRepo(
        semesters: mockSemesters,
        deadlines: SemesterDeadlinesDto(items: []),
      );

      final container = ProviderContainer(
        overrides: [
          semesterDeadlinesRepositoryProvider.overrideWithValue(repo),
          sessionProvider.overrideWith((ref) => _FakeSessionController(session)),
          academicYearsProvider.overrideWith((ref) => mockYears),
        ],
      );
      addTearDown(container.dispose);

      // Đặt viewingYear là ViewingYear.all
      container.read(viewingYearProvider.notifier).selectYear(ViewingYear.all);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SemesterDeadlinesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ô chọn năm không hiển thị "Tất cả các năm"
      expect(
        find.descendant(
          of: find.byType(AcademicYearFilterControl),
          matching: find.text('Tất cả các năm'),
        ),
        findsNothing,
      );

      // Màn hình dùng năm hiện hành (2026-2027)
      expect(find.textContaining('2026-2027'), findsWidgets);
    });
  });

  group('Lỗi 4: Lưới điểm xử lý 409 theo mã lỗi nghiệp vụ', () {
    testWidgets('409 code CELL_HAS_VALUE không hiện banner xung đột', (tester) async {
      final server = _GradebookFakeServer()..nextErrorCode = 'CELL_HAS_VALUE';
      final dio = Dio()..httpClientAdapter = server;
      final api = ApiClientDart(dio: dio);
      final container = ProviderContainer(
        overrides: [apiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.runAsync(
        () => container
            .read(sessionProvider.notifier)
            .login('giao_vien_test', 'fake-pass'),
      );

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const GradebookApp(initialLocation: '/gradebooks/7'),
        ),
      );
      await tester.pumpAndSettle();

      final input = find.byKey(const ValueKey('grade-9001'));
      await tester.enterText(input, '8.0');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Lý do thay đổi'),
        'Nhập điểm',
      );
      await tester.tap(find.text('Xác nhận lưu'));
      await tester.pumpAndSettle();

      // Không hiện banner xung đột
      expect(find.textContaining('Bảng điểm đã thay đổi ở nơi khác'), findsNothing);
      // Hiện thông báo tiếng Việt theo code
      expect(find.textContaining('Ô đã có điểm'), findsOneWidget);
    });

    testWidgets('409 code VERSION_OR_STATE_CONFLICT có banner xung đột', (tester) async {
      final server = _GradebookFakeServer()
        ..nextErrorCode = 'VERSION_OR_STATE_CONFLICT';
      final dio = Dio()..httpClientAdapter = server;
      final api = ApiClientDart(dio: dio);
      final container = ProviderContainer(
        overrides: [apiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.runAsync(
        () => container
            .read(sessionProvider.notifier)
            .login('giao_vien_test', 'fake-pass'),
      );

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const GradebookApp(initialLocation: '/gradebooks/7'),
        ),
      );
      await tester.pumpAndSettle();

      final input = find.byKey(const ValueKey('grade-9001'));
      await tester.enterText(input, '9.0');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Lý do thay đổi'),
        'Sửa điểm',
      );
      await tester.tap(find.text('Xác nhận lưu'));
      await tester.pumpAndSettle();

      // Bật banner xung đột
      expect(find.textContaining('Bảng điểm đã thay đổi ở nơi khác'), findsOneWidget);
    });
  });

  group('Lỗi 5: CHUA_CONG_BO hiện "Chưa công bố"', () {
    test('classificationBadgeOf và classificationLabel trả về "Chưa công bố"', () {
      final badge = classificationBadgeOf('CHUA_CONG_BO');
      expect(badge.label, 'Chưa công bố');
      expect(classificationLabel('CHUA_CONG_BO'), 'Chưa công bố');
    });
  });
}
