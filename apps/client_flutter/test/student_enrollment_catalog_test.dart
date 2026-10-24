import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/widgets/app_dialog.dart';
import 'package:client_flutter/app/widgets/app_select_field.dart';
import 'package:client_flutter/features/academic_catalog/edit_dialog.dart';
import 'package:client_flutter/features/academic_catalog/fields.dart';
import 'package:client_flutter/features/academic_catalog/promotion_screen.dart';
import 'package:client_flutter/features/academic_catalog/semester_deadlines_repository.dart';
import 'package:client_flutter/features/academic_catalog/student_enrollment_dialogs.dart';
import 'package:client_flutter/features/authentication/presentation/widgets/home_dashboard_content.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/final_results/student_results_screen.dart';
import 'package:client_flutter/features/gradebooks/gradebook_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSessionController extends StateNotifier<SessionDto?>
    implements SessionController {
  FakeSessionController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEnrollmentServer implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  bool shouldFailPromotion = false;
  bool studentResultsNullSummary = false;
  bool studentResultsNetworkError = false;
  bool studentResultsServerError = false;
  List<Map<String, dynamic>>? customPromotionPreviewItems;

  final years = [
    {
      'ma_nam_hoc': 1,
      'ten': '2025-2026',
      'ngay_bat_dau': '2025-09-01',
      'ngay_ket_thuc': '2026-06-01',
      'hien_hanh': true,
      'label': '2025-2026',
    },
    {
      'ma_nam_hoc': 2,
      'ten': '2026-2027',
      'ngay_bat_dau': '2026-09-01',
      'ngay_ket_thuc': '2027-06-01',
      'hien_hanh': false,
      'label': '2026-2027',
    },
  ];

  final classes = [
    {
      'ma_lop': 101,
      'ma_nam_hoc': 1,
      'ten_lop': '10A1',
      'khoi': 10,
      'label': '10A1',
    },
    {
      'ma_lop': 102,
      'ma_nam_hoc': 1,
      'ten_lop': '10A2',
      'khoi': 10,
      'label': '10A2',
    },
  ];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final path = options.path;
    Object body = {};
    int status = 200;

    if (path.endsWith('/identity/login')) {
      body = {
        'id': 1,
        'username': 'admin',
        'role': 'QUAN_TRI_VIEN',
        'active': true,
        'token': 'test-token',
        'csrf': 'test-csrf',
      };
    } else if (path.endsWith('/catalog/years')) {
      body = {'items': years, 'nextCursor': null};
    } else if (path.endsWith('/catalog/classes')) {
      body = {'items': classes, 'nextCursor': null};
    } else if (path.contains('/promotion-preview')) {
      body = {
        'sourceClass': {
          'id': 101,
          'name': '10A1',
          'grade': 10,
          'yearId': 1,
          'yearName': '2025-2026',
        },
        'targetYear': {
          'id': 2,
          'name': '2026-2027',
          'startDate': '2026-09-01',
        },
        'targetClasses': [
          {'id': 201, 'name': '11A1', 'grade': 11},
          {'id': 202, 'name': '11A2', 'grade': 11},
          {'id': 102, 'name': '10A2', 'grade': 10},
        ],
        'items': customPromotionPreviewItems ?? [
          {
            'studentId': 1,
            'studentName': 'Nguyễn Văn A',
            'order': 1,
            'suggestedAction': 'LEN_LOP',
            'suggestedTargetClassId': 201,
            'alreadyEnrolledInTargetYear': false,
            'processedStatus': null,
            'targetClassName': null,
          },
          {
            'studentId': 2,
            'studentName': 'Trần Thị B',
            'order': 2,
            'suggestedAction': 'LEN_LOP',
            'suggestedTargetClassId': 201,
            'alreadyEnrolledInTargetYear': true,
            'processedStatus': null,
            'targetClassName': null,
          },
        ],
      };
    } else if (path.contains('/promotion') && options.method == 'POST') {
      if (shouldFailPromotion) {
        status = 400;
        body = {
          'code': 'STUDENT_ALREADY_ENROLLED',
          'message': 'Học sinh đã có ghi danh trong năm học đích',
          'details': {'studentId': 1},
        };
      } else {
        body = {
          'processed': 1,
          'promoted': 1,
          'retained': 0,
          'graduated': 0,
          'withdrawn': 0,
        };
      }
    } else if (path.contains('/transfer') && options.method == 'POST') {
      body = {
        'enrollment': {
          'id': 'enr-1',
          'classId': 102,
          'className': '10A2',
          'grade': 10,
          'yearId': 1,
          'yearName': '2025-2026',
          'fromDate': '2026-10-22',
          'toDate': null,
          'status': 'DANG_HOC',
          'reason': 'Chuyển lớp theo nguyện vọng',
          'actorName': 'Admin',
          'createdAt': '2026-10-22T08:00:00.000Z',
        },
        'affectedGradebooks': [
          {
            'id': 1,
            'subjectName': 'Toán',
            'termName': 'Học kỳ I',
          },
        ],
      };
    } else if (path.contains('/enrollments') && options.method == 'GET') {
      body = {
        'items': [
          {
            'id': 'e1',
            'classId': 101,
            'className': '10A1',
            'grade': 10,
            'yearId': 1,
            'yearName': '2025-2026',
            'fromDate': '2025-09-01',
            'toDate': null,
            'status': 'DANG_HOC',
            'reason': null,
            'actorName': 'Admin',
            'createdAt': '2025-09-01T00:00:00.000Z',
          },
          {
            'id': 'e2',
            'classId': 101,
            'className': '10A1',
            'grade': 10,
            'yearId': 1,
            'yearName': '2025-2026',
            'fromDate': '2025-09-01',
            'toDate': '2026-05-30',
            'status': 'LEN_LOP',
            'reason': 'Lên lớp thẳng',
            'actorName': 'Admin',
            'createdAt': '2025-09-01T00:00:00.000Z',
          },
          {
            'id': 'e3',
            'classId': 101,
            'className': '10A1',
            'grade': 10,
            'yearId': 1,
            'yearName': '2025-2026',
            'fromDate': '2025-09-01',
            'toDate': '2026-05-30',
            'status': 'LUU_BAN',
            'reason': 'Lưu ban do học lực',
            'actorName': 'Admin',
            'createdAt': '2025-09-01T00:00:00.000Z',
          },
          {
            'id': 'e4',
            'classId': 101,
            'className': '10A1',
            'grade': 10,
            'yearId': 1,
            'yearName': '2025-2026',
            'fromDate': '2025-09-01',
            'toDate': '2026-05-30',
            'status': 'DA_CHUYEN_LOP',
            'reason': 'Chuyển lớp sang 10A2',
            'actorName': 'Admin',
            'createdAt': '2025-09-01T00:00:00.000Z',
          },
          {
            'id': 'e5',
            'classId': 101,
            'className': '10A1',
            'grade': 10,
            'yearId': 1,
            'yearName': '2025-2026',
            'fromDate': '2025-09-01',
            'toDate': '2026-05-30',
            'status': 'NGHI_HOC',
            'reason': 'Nghỉ học có đơn',
            'actorName': 'Admin',
            'createdAt': '2025-09-01T00:00:00.000Z',
          },
          {
            'id': 'e6',
            'classId': 101,
            'className': '12A1',
            'grade': 12,
            'yearId': 1,
            'yearName': '2025-2026',
            'fromDate': '2025-09-01',
            'toDate': '2026-05-30',
            'status': 'TOT_NGHIEP',
            'reason': 'Tốt nghiệp THPT',
            'actorName': 'Admin',
            'createdAt': '2025-09-01T00:00:00.000Z',
          },
        ],
      };
    } else if (path.endsWith('/students/me/results')) {
      if (studentResultsNetworkError) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
          error: 'Connection timeout',
        );
      }
      if (studentResultsServerError) {
        status = 500;
        body = {};
      } else if (studentResultsNullSummary) {
        body = {
          'items': <Object>[],
          'years': [
            {'id': 1, 'name': '2025-2026', 'className': '10A1'},
            {'id': 2, 'name': '2024-2025', 'className': '10A1'},
          ],
          'summary': null,
        };
      } else {
        final yearId = options.queryParameters['yearId']?.toString();
        body = {
          'items': [
          {
            'gradebookId': 1,
            'subjectId': 10,
            'subjectName': 'Toán $yearId',
            'termId': 30,
            'termName': 'Học kỳ I',
            'yearId': 1,
            'yearName': '2025-2026',
            'className': '10A1',
            'components': [
              {
                'componentId': 201,
                'componentName': 'Cuối kỳ',
                'coefficient': '2.00',
                'value': '8.5',
                'status': 'DA_DUYET',
              },
            ],
            'finalScore': '8.5',
            'classification': 'GIOI',
            'calculatedAt': '2026-09-13T01:00:00.000Z',
          },
        ],
        'years': [
          {'id': 1, 'name': '2025-2026', 'className': '10A1'},
          {'id': 2, 'name': '2024-2025', 'className': '10A1'},
        ],
        'summary': {
          'termId': 30,
          'termName': 'Học kỳ I',
          'className': '10A1',
          'yearId': 1,
          'yearName': '2025-2026',
          'averageScore': '8.50',
          'publishedSubjects': 1,
          'totalSubjects': 1,
          'classRank': 1,
          'classSize': 35,
        },
      };
      }
    } else if (path.endsWith('/cells')) {
      body = {
        'book': {
          'id': 1,
          'classId': 101,
          'subjectId': 10,
          'termId': 30,
          'className': '10A1',
          'subjectName': 'Toán',
          'termName': 'Học kỳ I',
          'status': 'DANG_NHAP_LIEU',
          'version': 1,
          'resultsOutdated': false,
          'pendingAdjustmentId': null,
        },
        'items': [
          {
            'id': '1',
            'studentId': 1,
            'studentName': 'Lê Văn Active',
            'stt': 1,
            'active': true,
            'componentId': 201,
            'componentName': 'Cuối kỳ',
            'coefficient': '2.00',
            'required': true,
            'displayOrder': 1,
            'value': '9.0',
            'status': 'DA_DUYET',
            'source': 'NHAP_TAY',
            'exemptionReason': null,
          },
          {
            'id': '2',
            'studentId': 2,
            'studentName': 'Trần Văn Inactive',
            'stt': 2,
            'active': false,
            'componentId': 201,
            'componentName': 'Cuối kỳ',
            'coefficient': '2.00',
            'required': true,
            'displayOrder': 1,
            'value': null,
            'status': 'CHUA_CO',
            'source': 'NHAP_TAY',
            'exemptionReason': null,
          },
        ],
        'nextCursor': null,
      };
    } else {
      body = {'items': [], 'nextCursor': null};
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

ApiClientDart _createClient(_FakeEnrollmentServer server) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost/api/v1',
      connectTimeout: const Duration(seconds: 5),
    ),
  );
  dio.httpClientAdapter = server;
  return ApiClientDart(dio: dio);
}

final _adminSession = SessionDto(
  id: 1,
  username: 'admin',
  role: SessionDtoRoleEnum.QUAN_TRI_VIEN,
  active: true,
  token: 'tok',
  csrf: 'csrf',
);

final _teacherSession = SessionDto(
  id: 2,
  username: 'teacher',
  role: SessionDtoRoleEnum.GIAO_VIEN,
  active: true,
  token: 'tok',
  csrf: 'csrf',
);

void main() {
  group('Student Enrollment & Catalog Ghi Danh Tests', () {
    test('STUDENT_CLASS_VIA_ENROLLMENT error code translates correctly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/catalog/students/1'),
        response: Response(
          requestOptions: RequestOptions(path: '/catalog/students/1'),
          statusCode: 400,
          data: {
            'code': 'STUDENT_CLASS_VIA_ENROLLMENT',
            'message': 'Cannot change student class directly',
          },
        ),
      );

      final message = deadlineErrorMessage(dioException);
      expect(
        message,
        'Không đổi lớp trực tiếp ở đây; dùng chức năng xếp lớp/chuyển lớp',
      );
    });

    testWidgets(
      'Form SỬA học sinh khóa trường Lớp và Đang theo học, kèm dòng gợi ý',
      (tester) async {
        final server = _FakeEnrollmentServer();
        final client = _createClient(server);

        await tester.pumpWidget(
          ProviderContainerWidget(
            overrides: [
              apiProvider.overrideWithValue(client),
              sessionProvider.overrideWith(
                (ref) => FakeSessionController(_adminSession),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: [AppTokens.light]),
              home: Scaffold(
                body: EditDialog(
                  spec: resources.firstWhere((r) => r.key == 'students'),
                  row: {
                    'ma_hoc_sinh': 1,
                    'ho_ten': 'Nguyễn Văn Nam',
                    'ngay_sinh': '2008-01-01',
                    'ma_lop': 101,
                    'currentClassId': 101,
                    'currentClassName': '10A1',
                    'dang_theo_hoc': true,
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Expect the hint text to appear
        expect(
          find.text('Chuyển lớp, nghỉ học, học lại: dùng menu thao tác trên danh mục học sinh'),
          findsWidgets,
        );

        // Check Lớp dropdown is disabled
        final selectField = tester.widget<AppSelectField<num>>(
          find.byWidgetPredicate(
            (w) => w is AppSelectField<num> && (w.label?.contains('Lớp') ?? false),
          ),
        );
        expect(selectField.enabled, isFalse);

        // Check Đang theo học switch is disabled (onChanged is null)
        final switchTile = tester.widget<SwitchListTile>(
          find.byWidgetPredicate(
            (w) => w is SwitchListTile && (w.title is Text && (w.title as Text).data == 'Đang theo học'),
          ),
        );
        expect(switchTile.onChanged, isNull);
      },
    );

    testWidgets(
      'Form TẠO MỚI học sinh cho phép chọn Lớp bình thường, không có hint khóa',
      (tester) async {
        final server = _FakeEnrollmentServer();
        final client = _createClient(server);

        await tester.pumpWidget(
          ProviderContainerWidget(
            overrides: [
              apiProvider.overrideWithValue(client),
              sessionProvider.overrideWith(
                (ref) => FakeSessionController(_adminSession),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: [AppTokens.light]),
              home: Scaffold(
                body: EditDialog(
                  spec: resources.firstWhere((r) => r.key == 'students'),
                  row: null,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Hint text must NOT appear for new student creation
        expect(
          find.text('Đổi lớp, lên lớp, nghỉ học: dùng chức năng Xếp lớp (sắp có)'),
          findsNothing,
        );

        // Lớp field is enabled for creation
        final selectField = tester.widget<AppSelectField<num>>(
          find.byWidgetPredicate(
            (w) => w is AppSelectField<num> && (w.label?.contains('Lớp') ?? false),
          ),
        );
        expect(selectField.enabled, isTrue);

        // Đang theo học switch is enabled
        final switchTile = tester.widget<SwitchListTile>(
          find.byWidgetPredicate(
            (w) => w is SwitchListTile && (w.title is Text && (w.title as Text).data == 'Đang theo học'),
          ),
        );
        expect(switchTile.onChanged, isNotNull);
      },
    );

    testWidgets(
      'Màn học sinh xem điểm: mặc định Tất cả năm học (không truyền yearId) và không phụ thuộc danh mục năm học',
      (tester) async {
        final server = _FakeEnrollmentServer();
        final client = _createClient(server);

        await tester.pumpWidget(
          ProviderContainerWidget(
            overrides: [
              apiProvider.overrideWithValue(client),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: [AppTokens.light]),
              home: const StudentResultsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify initial API call requested without yearId (Tất cả năm học)
        final initialRequests = server.requests.where(
          (r) => r.path.endsWith('/students/me/results'),
        ).toList();
        expect(initialRequests, isNotEmpty);
        expect(initialRequests.last.queryParameters['yearId'], isNull);

        // Check dropdown shows "Tất cả năm học" by default
        expect(find.text('Tất cả năm học'), findsOneWidget);

        // Check grouped headers display class name if available
        expect(find.textContaining('10A1'), findsWidgets);
      },
    );

    testWidgets(
      'Lưới điểm: học sinh active=false hiển thị nhãn "Đã chuyển/nghỉ"',
      (tester) async {
        final server = _FakeEnrollmentServer();
        final client = _createClient(server);

        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderContainerWidget(
            overrides: [
              apiProvider.overrideWithValue(client),
              sessionProvider.overrideWith(
                (ref) => FakeSessionController(_teacherSession),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: [AppTokens.light]),
              home: const GradebookScreen(bookId: 1),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Inactive student row should have label 'Đã chuyển/nghỉ'
        expect(find.textContaining('Đã chuyển/nghỉ'), findsWidgets);
        expect(find.textContaining('Ngừng theo học'), findsNothing);
      },
    );

    testWidgets(
      'PromotionScreen: lọc lớp đích theo hành động (LEN_LOP khối +1, LUU_BAN cùng khối)',
      (tester) async {
        final server = _FakeEnrollmentServer();
        final client = _createClient(server);

        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderContainerWidget(
            overrides: [
              apiProvider.overrideWithValue(client),
              sessionProvider.overrideWith(
                (ref) => FakeSessionController(_adminSession),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: [AppTokens.light]),
              routes: {
                '/catalog/classes': (_) => const Scaffold(),
              },
              home: const PromotionScreen(classId: 101),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Select target year (2026-2027)
        await tester.tap(find.byKey(const ValueKey('promotion-target-year-select')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2026-2027').last);
        await tester.pumpAndSettle();

        // Preview loads. Row 1 has LEN_LOP. Target class dropdown should have 11A1 and 11A2, but not 10A2
        final targetClassDropdownFinder = find.byKey(const ValueKey('promotion-target-class-1'));
        expect(targetClassDropdownFinder, findsOneWidget);
        await tester.tap(targetClassDropdownFinder);
        await tester.pumpAndSettle();
        expect(find.text('11A1'), findsWidgets);
        expect(find.text('11A2'), findsWidgets);
        expect(find.text('10A2'), findsNothing);

        // Close dropdown by selecting 11A1
        await tester.tap(find.text('11A1').last);
        await tester.pumpAndSettle();

        // Change action to LUU_BAN
        await tester.tap(find.byKey(const ValueKey('promotion-action-1')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lưu ban').last);
        await tester.pumpAndSettle();

        // Target class dropdown should now show 10A2, but not 11A1 or 11A2
        await tester.tap(find.byKey(const ValueKey('promotion-target-class-1')));
        await tester.pumpAndSettle();
        expect(find.text('10A2'), findsWidgets);
        expect(find.text('11A2'), findsNothing);
        expect(find.widgetWithText(MenuItemButton, '11A1'), findsNothing);
      },
    );

    testWidgets(
      'PromotionScreen: bỏ dòng đã có ghi danh năm đích khi gửi API',
      (tester) async {
        final server = _FakeEnrollmentServer();
        final client = _createClient(server);

        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderContainerWidget(
            overrides: [
              apiProvider.overrideWithValue(client),
              sessionProvider.overrideWith(
                (ref) => FakeSessionController(_adminSession),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: [AppTokens.light]),
              routes: {
                '/catalog/classes': (_) => const Scaffold(),
              },
              home: const PromotionScreen(classId: 101),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select target year
        await tester.tap(find.byKey(const ValueKey('promotion-target-year-select')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2026-2027').last);
        await tester.pumpAndSettle();

        // Student 2 is already enrolled -> displays badge
        expect(find.text('Đã có ghi danh'), findsOneWidget);

        // Submit promotion
        await tester.ensureVisible(find.byKey(const ValueKey('promotion-submit-btn')));
        await tester.tap(find.byKey(const ValueKey('promotion-submit-btn')));
        await tester.pumpAndSettle();

        // Confirmation dialog appears
        expect(find.text('Xác nhận lên lớp cuối năm'), findsOneWidget);
        await tester.tap(find.text('Xác nhận thực hiện'));
        await tester.pumpAndSettle();

        // Verify request payload only sent student 1
        final promoRequests = server.requests.where(
          (r) => r.path.contains('/promotion') && r.method == 'POST',
        ).toList();
        expect(promoRequests, isNotEmpty);
        final data = jsonDecode(promoRequests.last.data as String) as Map<String, dynamic>;
        final items = data['items'] as List;
        expect(items.length, 1);
        expect(items.first['studentId'], 1);

        // Displays success card
        expect(find.text('Lên lớp cuối năm thành công!'), findsOneWidget);
      },
    );

    testWidgets(
      'PromotionScreen: tô dòng lỗi theo details.studentId',
      (tester) async {
        final server = _FakeEnrollmentServer();
        server.shouldFailPromotion = true;
        final client = _createClient(server);

        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderContainerWidget(
            overrides: [
              apiProvider.overrideWithValue(client),
              sessionProvider.overrideWith(
                (ref) => FakeSessionController(_adminSession),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: [AppTokens.light]),
              routes: {
                '/catalog/classes': (_) => const Scaffold(),
              },
              home: const PromotionScreen(classId: 101),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select target year
        await tester.tap(find.byKey(const ValueKey('promotion-target-year-select')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2026-2027').last);
        await tester.pumpAndSettle();

        // Submit promotion
        await tester.ensureVisible(find.byKey(const ValueKey('promotion-submit-btn')));
        await tester.tap(find.byKey(const ValueKey('promotion-submit-btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xác nhận thực hiện'));
        await tester.pumpAndSettle();

        // Error message displayed
        expect(
          find.text('Học sinh đã có ghi danh trong năm học đích hoặc từng học lớp này'),
          findsWidgets,
        );

        // Row for student 1 has error indication
        expect(find.text('Lỗi dòng này'), findsOneWidget);
      },
    );

    testWidgets(
      'Dialog chuyển lớp: hiện affectedGradebooks và cảnh báo khi thành công',
      (tester) async {
        final server = _FakeEnrollmentServer();
        final client = _createClient(server);

        await tester.pumpWidget(
          ProviderContainerWidget(
            overrides: [
              apiProvider.overrideWithValue(client),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: [AppTokens.light]),
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () async {
                      final res = await showAppDialog<TransferResultDto>(
                        context: ctx,
                        builder: (_) => StudentTransferDialog(
                          student: const {'ma_hoc_sinh': 1, 'ho_ten': 'Nguyễn Văn A', 'ma_lop': 101},
                          api: client,
                          allClasses: const [
                            {'ma_lop': 101, 'ma_nam_hoc': 1, 'khoi': 10, 'ten_lop': '10A1'},
                            {'ma_lop': 102, 'ma_nam_hoc': 1, 'khoi': 10, 'ten_lop': '10A2'},
                          ],
                        ),
                      );
                      if (res != null && res.affectedGradebooks.isNotEmpty) {
                        await showAffectedGradebooksNotice(
                          ctx,
                          affectedGradebooks: res.affectedGradebooks,
                        );
                      }
                    },
                    child: const Text('Open Transfer'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Transfer'));
        await tester.pumpAndSettle();

        expect(find.text('Chuyển lớp: Nguyễn Văn A'), findsOneWidget);

        // Select class 10A2
        await tester.tap(find.byType(AppSelectField<num>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('10A2').last);
        await tester.pumpAndSettle();

        // Enter reason
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Lý do chuyển lớp *'),
          'Chuyển lớp theo nguyện vọng gia đình',
        );
        await tester.pumpAndSettle();

        // Tap confirm
        await tester.tap(find.text('Chuyển lớp').last);
        await tester.pumpAndSettle();

        // Notice dialog appears
        expect(find.text('Bảng điểm bị ảnh hưởng'), findsOneWidget);
        expect(find.text('Toán · Học kỳ I'), findsOneWidget);
        expect(
          find.textContaining('Cột đã chốt: dùng chức năng Học sinh vào lớp sau khi chốt'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Lịch sử xếp lớp: hiển thị đầy đủ các trạng thái tiếng Việt',
      (tester) async {
        final server = _FakeEnrollmentServer();
        final client = _createClient(server);

        await tester.pumpWidget(
          ProviderContainerWidget(
            overrides: [
              apiProvider.overrideWithValue(client),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: [AppTokens.light]),
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () => showAppDialog<void>(
                      context: ctx,
                      builder: (_) => StudentEnrollmentHistoryDialog(
                        student: const {'ma_hoc_sinh': 1, 'ho_ten': 'Nguyễn Văn A'},
                        api: client,
                      ),
                    ),
                    child: const Text('Open History'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open History'));
        await tester.pumpAndSettle();

        expect(find.text('Lịch sử xếp lớp: Nguyễn Văn A'), findsOneWidget);
        expect(find.text('Đang học'), findsOneWidget);
        expect(find.text('Lên lớp'), findsOneWidget);
        expect(find.text('Lưu ban'), findsOneWidget);
        expect(find.text('Đã chuyển lớp'), findsOneWidget);
        expect(find.text('Nghỉ học'), findsOneWidget);
        expect(find.text('Tốt nghiệp'), findsOneWidget);
      },
    );

    testWidgets(
      'Màn kết quả học sinh: nhóm theo năm học (kèm tên lớp) và dùng years mới cho dropdown',
      (tester) async {
        final server = _FakeEnrollmentServer();
        final client = _createClient(server);

        await tester.pumpWidget(
          ProviderContainerWidget(
            overrides: [
              apiProvider.overrideWithValue(client),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: [AppTokens.light]),
              home: const StudentResultsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check dropdown shows "Tất cả năm học" by default
        expect(find.text('Tất cả năm học'), findsOneWidget);

        // Grouping header displays Year name with Class name
        expect(find.text('Năm học 2025-2026'), findsOneWidget);
        expect(find.text('Lớp 10A1'), findsWidgets);

        // Open year dropdown to verify new items from results.years
        await tester.tap(find.byKey(const ValueKey('student-results-year-select')));
        await tester.pumpAndSettle();
        expect(find.text('2025-2026 · Lớp 10A1'), findsWidgets);
        expect(find.text('2024-2025 · Lớp 10A1'), findsWidgets);
      },
    );

    testWidgets(
      'Màn Điểm của tôi: khi summary null hiển thị trạng thái trống và giữ bộ chọn năm',
      (tester) async {
        final server = _FakeEnrollmentServer()..studentResultsNullSummary = true;
        final client = _createClient(server);

        await tester.pumpWidget(
          ProviderContainerWidget(
            overrides: [
              apiProvider.overrideWithValue(client),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: [AppTokens.light]),
              home: const StudentResultsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Chưa có kết quả'), findsOneWidget);
        expect(find.text('Năm học này chưa có kết quả được công bố'), findsOneWidget);
        expect(find.byKey(const ValueKey('student-results-year-select')), findsOneWidget);
      },
    );

    testWidgets(
      'Màn Điểm của tôi: lỗi mạng hiện Không thể kết nối dịch vụ',
      (tester) async {
        final serverTimeout = _FakeEnrollmentServer()..studentResultsNetworkError = true;
        final clientTimeout = _createClient(serverTimeout);

        await tester.pumpWidget(
          ProviderContainerWidget(
            overrides: [
              apiProvider.overrideWithValue(clientTimeout),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: [AppTokens.light]),
              home: const StudentResultsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Không thể kết nối dịch vụ. Vui lòng thử lại.'), findsOneWidget);
      },
    );

    testWidgets(
      'Màn Điểm của tôi: lỗi 500 hiện thông điệp máy chủ',
      (tester) async {
        final server500 = _FakeEnrollmentServer()..studentResultsServerError = true;
        final client500 = _createClient(server500);

        await tester.pumpWidget(
          ProviderContainerWidget(
            overrides: [
              apiProvider.overrideWithValue(client500),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: [AppTokens.light]),
              home: const StudentResultsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Máy chủ đang gặp sự cố. Vui lòng thử lại sau.'), findsOneWidget);
      },
    );

    testWidgets(
      'Dashboard học sinh: hiển thị trạng thái trống khi summary null không lỗi',
      (tester) async {
        final server = _FakeEnrollmentServer()..studentResultsNullSummary = true;
        final client = _createClient(server);

        final user = SessionDto(
          id: 1,
          username: '0912345678',
          role: SessionDtoRoleEnum.HOC_SINH,
          active: true,
          token: 'token',
          csrf: 'csrf',
        );

        await tester.pumpWidget(
          ProviderContainerWidget(
            overrides: [
              apiProvider.overrideWithValue(client),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: [AppTokens.light]),
              home: Scaffold(
                body: HomeDashboardContent(
                  user: user,
                  role: 'HOC_SINH',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Chưa có kết quả'), findsOneWidget);
        expect(find.text('Năm học này chưa có kết quả được công bố'), findsOneWidget);
      },
    );

    testWidgets(
      'PromotionScreen: dòng đã xử lý hiển thị nhãn trạng thái và không gửi lên API',
      (tester) async {
        final server = _FakeEnrollmentServer();
        server.customPromotionPreviewItems = [
          {
            'studentId': 1,
            'studentName': 'Em Đã Lên Lớp',
            'order': 1,
            'suggestedAction': 'LEN_LOP',
            'suggestedTargetClassId': 201,
            'alreadyEnrolledInTargetYear': false,
            'processedStatus': 'LEN_LOP',
            'targetClassName': '11A1',
          },
          {
            'studentId': 2,
            'studentName': 'Em Đã Lưu Ban',
            'order': 2,
            'suggestedAction': 'LEN_LOP',
            'suggestedTargetClassId': 201,
            'alreadyEnrolledInTargetYear': false,
            'processedStatus': 'LUU_BAN',
            'targetClassName': '10A1',
          },
          {
            'studentId': 3,
            'studentName': 'Em Đã Tốt Nghiệp',
            'order': 3,
            'suggestedAction': 'TOT_NGHIEP',
            'suggestedTargetClassId': null,
            'alreadyEnrolledInTargetYear': false,
            'processedStatus': 'TOT_NGHIEP',
            'targetClassName': null,
          },
          {
            'studentId': 4,
            'studentName': 'Em Đã Nghỉ Học',
            'order': 4,
            'suggestedAction': 'LEN_LOP',
            'suggestedTargetClassId': null,
            'alreadyEnrolledInTargetYear': false,
            'processedStatus': 'NGHI_HOC',
            'targetClassName': null,
          },
          {
            'studentId': 5,
            'studentName': 'Em Đã Chuyển Lớp',
            'order': 5,
            'suggestedAction': 'LEN_LOP',
            'suggestedTargetClassId': null,
            'alreadyEnrolledInTargetYear': false,
            'processedStatus': 'DA_CHUYEN_LOP',
            'targetClassName': null,
          },
          {
            'studentId': 6,
            'studentName': 'Em Chưa Xử Lý',
            'order': 6,
            'suggestedAction': 'LEN_LOP',
            'suggestedTargetClassId': 201,
            'alreadyEnrolledInTargetYear': false,
            'processedStatus': null,
            'targetClassName': null,
          },
        ];
        final client = _createClient(server);

        await tester.pumpWidget(
          ProviderContainerWidget(
            overrides: [
              apiProvider.overrideWithValue(client),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: [AppTokens.light]),
              home: const PromotionScreen(classId: 101),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Target year select
        await tester.tap(find.byKey(const ValueKey('promotion-target-year-select')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2026-2027').last);
        await tester.pumpAndSettle();

        // Verify badges
        expect(find.text('Đã lên lớp → 11A1'), findsOneWidget);
        expect(find.text('Đã lưu ban → 10A1'), findsOneWidget);
        expect(find.text('Đã tốt nghiệp'), findsOneWidget);
        expect(find.text('Đã nghỉ học'), findsOneWidget);
        expect(find.text('Đã chuyển lớp'), findsOneWidget);

        // Disabled dropdowns on processed rows
        expect(find.byKey(const ValueKey('promotion-action-1')), findsNothing);
        expect(find.byKey(const ValueKey('promotion-action-6')), findsOneWidget);

        // Active count only counts unhandled row (studentId 6)
        expect(find.text('Số học sinh sẽ thực hiện: 1'), findsOneWidget);
      },
    );

    testWidgets(
      'PromotionScreen: mọi dòng đã xử lý hiện thông báo và khóa nút Thực hiện',
      (tester) async {
        final server = _FakeEnrollmentServer();
        server.customPromotionPreviewItems = [
          {
            'studentId': 1,
            'studentName': 'Em Đã Lên Lớp',
            'order': 1,
            'suggestedAction': 'LEN_LOP',
            'suggestedTargetClassId': 201,
            'alreadyEnrolledInTargetYear': false,
            'processedStatus': 'LEN_LOP',
            'targetClassName': '11A1',
          },
        ];
        final client = _createClient(server);

        await tester.pumpWidget(
          ProviderContainerWidget(
            overrides: [
              apiProvider.overrideWithValue(client),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: [AppTokens.light]),
              home: const PromotionScreen(classId: 101),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Target year select
        await tester.tap(find.byKey(const ValueKey('promotion-target-year-select')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2026-2027').last);
        await tester.pumpAndSettle();

        // Check banner
        expect(
          find.text('Tất cả học sinh của lớp đã được xử lý cho năm 2026-2027'),
          findsOneWidget,
        );

        // Check submit button is disabled
        final submitBtn = tester.widget<FilledButton>(
          find.byKey(const ValueKey('promotion-submit-btn')),
        );
        expect(submitBtn.onPressed, isNull);
        expect(find.text('Số học sinh sẽ thực hiện: 0'), findsOneWidget);
      },
    );
  });
}

class ProviderContainerWidget extends StatefulWidget {
  const ProviderContainerWidget({
    super.key,
    required this.child,
    this.overrides = const [],
  });

  final Widget child;
  final List<dynamic> overrides;

  @override
  State<ProviderContainerWidget> createState() =>
      _ProviderContainerWidgetState();
}

class _ProviderContainerWidgetState extends State<ProviderContainerWidget> {
  late final ProviderContainer container;

  @override
  void initState() {
    super.initState();
    container = ProviderContainer(
      overrides: widget.overrides.cast(),
    );
  }

  @override
  void dispose() {
    container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: container,
      child: widget.child,
    );
  }
}
