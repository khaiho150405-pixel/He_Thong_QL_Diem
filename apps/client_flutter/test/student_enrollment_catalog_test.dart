import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/widgets/app_select_field.dart';
import 'package:client_flutter/features/academic_catalog/edit_dialog.dart';
import 'package:client_flutter/features/academic_catalog/fields.dart';
import 'package:client_flutter/features/academic_catalog/semester_deadlines_repository.dart';
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
      'ten': '2024-2025',
      'ngay_bat_dau': '2024-09-01',
      'ngay_ket_thuc': '2025-06-01',
      'hien_hanh': false,
      'label': '2024-2025',
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
    } else if (path.endsWith('/students/me/results')) {
      final yearId = options.queryParameters['yearId']?.toString();
      body = {
        'items': [
          {
            'gradebookId': 1,
            'subjectId': 10,
            'subjectName': 'Toán $yearId',
            'termId': 30,
            'termName': 'Học kỳ I',
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
        'summary': {
          'termId': 30,
          'termName': 'Học kỳ I',
          'className': '10A1',
          'averageScore': '8.50',
          'publishedSubjects': 1,
          'totalSubjects': 1,
          'classRank': 1,
          'classSize': 35,
        },
      };
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
          find.text('Đổi lớp, lên lớp, nghỉ học: dùng chức năng Xếp lớp (sắp có)'),
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
