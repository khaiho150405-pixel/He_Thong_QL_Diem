import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/features/academic_catalog/academic_year_scope.dart';
import 'package:client_flutter/features/academic_catalog/semester_deadlines_repository.dart';
import 'package:client_flutter/features/academic_catalog/semester_deadlines_screen.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/gradebooks/grade_deadlines_panel.dart';
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

class FakeSemesterDeadlinesRepository implements SemesterDeadlinesRepository {
  FakeSemesterDeadlinesRepository({this.semesters = const [], this.deadlines});

  final List<SemestersDto> semesters;
  final SemesterDeadlinesDto? deadlines;

  @override
  Future<List<SemestersDto>> listSemesters({num? yearId}) async {
    if (yearId != null) {
      return semesters.where((s) => s.maNamHoc == yearId).toList();
    }
    return semesters;
  }

  @override
  Future<SemesterDeadlinesDto> getDeadlines(num semesterId) async {
    return deadlines ?? SemesterDeadlinesDto(items: []);
  }

  @override
  Future<SemesterDeadlineDto> setDeadline({
    required num semesterId,
    required String type,
    required DateTime opensAt,
    required DateTime closesAt,
    required num expectedVersion,
  }) async {
    return SemesterDeadlineDto(
      type: SemesterDeadlineDtoTypeEnum.values.firstWhere(
        (e) => e.value == type,
        orElse: () => SemesterDeadlineDtoTypeEnum.TX,
      ),
      opensAt: opensAt,
      closesAt: closesAt,
      version: expectedVersion + 1,
      expired: false,
    );
  }

  @override
  Future<PublishReadinessDto> publishReadiness(num semesterId) async {
    return PublishReadinessDto(ready: true, issues: []);
  }
}

GradeCellDto testCell({
  required num id,
  required String name,
  required bool requiredCol,
  GradeCellDtoDeadlineSourceEnum? source,
}) => GradeCellDto.fromJson({
  'id': id.toString(),
  'studentId': 1,
  'studentName': 'Nguyen Van A',
  'stt': 1,
  'active': true,
  'componentId': id,
  'componentName': name,
  'coefficient': '1.00',
  'required': requiredCol,
  'displayOrder': id,
  'value': null,
  'status': 'CHUA_CO',
  'exemptionReason': null,
  'source': 'NHAP_TAY',
  'deadlineSource': source?.value,
  'deadlineVersion': 0,
});

void main() {
  group('Lỗi tiếng Việt theo trường code', () {
    test('chuyển đúng mã lỗi quy định', () {
      DioException makeDioError(String code) => DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          data: {'code': code},
        ),
      );

      expect(
        deadlineErrorMessage(makeDioError('DEADLINE_VERSION_CONFLICT')),
        'Lịch vừa được thay đổi, hãy tải lại',
      );
      expect(
        deadlineErrorMessage(makeDioError('COLUMN_LOCKED')),
        'Lịch đã qua hạn, không sửa được',
      );
      expect(
        deadlineErrorMessage(makeDioError('INVALID_ENTRY_WINDOW')),
        'Hạn nhập phải sau giờ mở và ở tương lai',
      );
      expect(
        deadlineErrorMessage(makeDioError('TERM_ALREADY_PUBLISHED')),
        'Học kỳ đã công bố',
      );
    });
  });

  group('GradeDeadlinesPanel', () {
    testWidgets('hiện nhãn Bắt buộc / Không bắt buộc và câu giải thích hết hạn', (
      tester,
    ) async {
      final compRequired = testCell(id: 1, name: 'Miệng', requiredCol: true);
      final compOptional = testCell(id: 2, name: 'Tự chọn', requiredCol: false);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GradeDeadlinesPanel(
                bookId: 10,
                components: [compRequired, compOptional],
                isAdmin: true,
                locked: false,
                onReload: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Hết hạn: cột bắt buộc còn trống sẽ ghi 0; cột không bắt buộc để trống, không tính vào điểm trung bình.',
        ),
        findsOneWidget,
      );

      expect(find.text('Bắt buộc'), findsOneWidget);
      expect(find.text('Không bắt buộc'), findsOneWidget);
    });

    testWidgets(
      'hiện đúng nhãn nguồn lịch và nút Đặt lịch riêng cho bảng này',
      (tester) async {
        final cellHocKy = testCell(
          id: 1,
          name: 'Giữa kỳ',
          requiredCol: true,
          source: GradeCellDtoDeadlineSourceEnum.HOC_KY,
        );
        final cellRieng = testCell(
          id: 2,
          name: 'Cuối kỳ',
          requiredCol: true,
          source: GradeCellDtoDeadlineSourceEnum.RIENG,
        );
        final cellChuaCo = testCell(
          id: 3,
          name: 'TX 1',
          requiredCol: true,
          source: null,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: GradeDeadlinesPanel(
                  bookId: 10,
                  components: [cellHocKy, cellRieng, cellChuaCo],
                  isAdmin: true,
                  locked: false,
                  onReload: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Theo lịch học kỳ'), findsOneWidget);
        expect(find.text('Lịch riêng'), findsOneWidget);
        expect(find.text('Chưa có lịch'), findsOneWidget);

        expect(find.text('Đặt lịch riêng cho bảng này'), findsNWidgets(3));
      },
    );
  });

  group('SemesterDeadlinesScreen', () {
    final mockSemesters = [
      SemestersDto(
        maHocKy: 1,
        ten: 'Học kỳ 1',
        maNamHoc: 2024,
        thuTu: 1,
        ngayBatDau: '2024-09-05',
        ngayKetThuc: '2025-01-15',
        label: 'HK1 (2024-2025)',
      ),
    ];

    final mockDeadlines = SemesterDeadlinesDto(
      items: [
        SemesterDeadlineDto(
          type: SemesterDeadlineDtoTypeEnum.TX,
          opensAt: DateTime.utc(2026, 10, 1, 0, 0),
          closesAt: DateTime.utc(2026, 10, 30, 23, 59),
          version: 1,
          expired: false,
        ),
        SemesterDeadlineDto(
          type: SemesterDeadlineDtoTypeEnum.GK,
          opensAt: DateTime.utc(2026, 9, 1, 0, 0),
          closesAt: DateTime.utc(2026, 9, 30, 23, 59),
          version: 2,
          expired: true,
        ),
        SemesterDeadlineDto(
          type: SemesterDeadlineDtoTypeEnum.CK,
          opensAt: null,
          closesAt: null,
          version: 0,
          expired: false,
        ),
      ],
    );

    testWidgets('3 thẻ lịch + thẻ hết hạn chỉ đọc', (tester) async {
      final repo = FakeSemesterDeadlinesRepository(
        semesters: mockSemesters,
        deadlines: mockDeadlines,
      );

      final session = SessionDto(
        id: 1,
        username: 'admin',
        role: SessionDtoRoleEnum.QUAN_TRI_VIEN,
        active: true,
        token: 'tok',
        csrf: 'csrf',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            semesterDeadlinesRepositoryProvider.overrideWithValue(repo),
            sessionProvider.overrideWith(
              (ref) => FakeSessionController(session),
            ),
          ],
          child: const MaterialApp(home: SemesterDeadlinesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Điểm thường xuyên (TX)'), findsOneWidget);
      expect(find.text('Điểm giữa kỳ (GK)'), findsOneWidget);
      expect(find.text('Điểm cuối kỳ (CK)'), findsOneWidget);

      expect(find.text('Đã hết hạn'), findsWidgets);
      expect(find.text('Lịch đã qua hạn, không sửa được'), findsOneWidget);

      expect(find.text('Sửa lịch'), findsOneWidget);
      expect(find.text('Đặt lịch'), findsOneWidget);
    });

    testWidgets('không còn nút tạo bảng điểm thủ công', (tester) async {
      final repo = FakeSemesterDeadlinesRepository(
        semesters: mockSemesters,
        deadlines: mockDeadlines,
      );

      final session = SessionDto(
        id: 1,
        username: 'admin',
        role: SessionDtoRoleEnum.QUAN_TRI_VIEN,
        active: true,
        token: 'tok',
        csrf: 'csrf',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            semesterDeadlinesRepositoryProvider.overrideWithValue(repo),
            sessionProvider.overrideWith(
              (ref) => FakeSessionController(session),
            ),
          ],
          child: const MaterialApp(home: SemesterDeadlinesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Khởi tạo bảng điểm còn thiếu'), findsNothing);
      expect(find.text('Sửa lịch'), findsWidgets);
    });
  });

  group('Bộ lọc năm học & nhãn học kỳ', () {
    final today = DateTime.now();
    final prevMonthStr = today
        .subtract(const Duration(days: 30))
        .toIso8601String()
        .substring(0, 10);
    final nextMonthStr = today
        .add(const Duration(days: 60))
        .toIso8601String()
        .substring(0, 10);

    final multiYearSemesters = [
      SemestersDto(
        maHocKy: 10,
        ten: 'Học kỳ 1',
        maNamHoc: 2024,
        thuTu: 1,
        ngayBatDau: '2024-09-05',
        ngayKetThuc: '2025-01-15',
        label: 'HK1 (2024-2025)',
      ),
      SemestersDto(
        maHocKy: 11,
        ten: 'Học kỳ 2',
        maNamHoc: 2024,
        thuTu: 2,
        ngayBatDau: '2025-01-16',
        ngayKetThuc: '2025-05-30',
        label: 'HK2 (2024-2025)',
      ),
      SemestersDto(
        maHocKy: 20,
        ten: 'Học kỳ 1',
        maNamHoc: 2026,
        thuTu: 1,
        ngayBatDau: prevMonthStr,
        ngayKetThuc: nextMonthStr,
        label: 'HK1 (2026-2027)',
      ),
      SemestersDto(
        maHocKy: 21,
        ten: 'Học kỳ 2',
        maNamHoc: 2026,
        thuTu: 2,
        ngayBatDau: '2027-01-16',
        ngayKetThuc: '2027-05-30',
        label: 'HK2 (2026-2027)',
      ),
    ];

    final mockYears = [
      {'ma_nam_hoc': 2024, 'ten': '2024-2025', 'hien_hanh': false},
      {'ma_nam_hoc': 2026, 'ten': '2026-2027', 'hien_hanh': true},
      {'ma_nam_hoc': 2028, 'ten': '2028-2029', 'hien_hanh': false},
    ];

    final session = SessionDto(
      id: 1,
      username: 'admin',
      role: SessionDtoRoleEnum.QUAN_TRI_VIEN,
      active: true,
      token: 'tok',
      csrf: 'csrf',
    );

    testWidgets('chỉ hiện học kỳ của năm đang xem và nhãn có tên năm', (
      tester,
    ) async {
      final repo = FakeSemesterDeadlinesRepository(
        semesters: multiYearSemesters,
      );

      final container = ProviderContainer(
        overrides: [
          semesterDeadlinesRepositoryProvider.overrideWithValue(repo),
          sessionProvider.overrideWith((ref) => FakeSessionController(session)),
          academicYearsProvider.overrideWith((ref) => mockYears),
        ],
      );
      container
          .read(viewingYearProvider.notifier)
          .selectYear(const ViewingYear(id: 2024, name: '2024-2025'));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SemesterDeadlinesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Học kỳ 1 · 2024-2025'), findsWidgets);
      expect(find.text('Học kỳ 1 · 2026-2027'), findsNothing);
    });

    testWidgets('mặc định chọn học kỳ chứa ngày hiện tại', (tester) async {
      final repo = FakeSemesterDeadlinesRepository(
        semesters: multiYearSemesters,
      );

      final container = ProviderContainer(
        overrides: [
          semesterDeadlinesRepositoryProvider.overrideWithValue(repo),
          sessionProvider.overrideWith((ref) => FakeSessionController(session)),
          academicYearsProvider.overrideWith((ref) => mockYears),
        ],
      );
      container
          .read(viewingYearProvider.notifier)
          .selectYear(
            const ViewingYear(id: 2026, name: '2026-2027', isCurrent: true),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SemesterDeadlinesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Học kỳ 1 · 2026-2027'), findsWidgets);
    });

    testWidgets(
      'không có học kỳ chứa ngày hiện tại thì chọn học kỳ đầu tiên của năm đó',
      (tester) async {
        final repo = FakeSemesterDeadlinesRepository(
          semesters: multiYearSemesters,
        );

        final container = ProviderContainer(
          overrides: [
            semesterDeadlinesRepositoryProvider.overrideWithValue(repo),
            sessionProvider.overrideWith(
              (ref) => FakeSessionController(session),
            ),
            academicYearsProvider.overrideWith((ref) => mockYears),
          ],
        );
        container
            .read(viewingYearProvider.notifier)
            .selectYear(const ViewingYear(id: 2024, name: '2024-2025'));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: SemesterDeadlinesScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Học kỳ 1 · 2024-2025'), findsWidgets);
      },
    );

    testWidgets(
      'đổi năm học thì danh sách đổi và năm không có học kỳ hiện thông báo',
      (tester) async {
        final repo = FakeSemesterDeadlinesRepository(
          semesters: multiYearSemesters,
        );

        final container = ProviderContainer(
          overrides: [
            semesterDeadlinesRepositoryProvider.overrideWithValue(repo),
            sessionProvider.overrideWith(
              (ref) => FakeSessionController(session),
            ),
            academicYearsProvider.overrideWith((ref) => mockYears),
          ],
        );
        container
            .read(viewingYearProvider.notifier)
            .selectYear(const ViewingYear(id: 2024, name: '2024-2025'));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: SemesterDeadlinesScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Học kỳ 1 · 2024-2025'), findsWidgets);

        container
            .read(viewingYearProvider.notifier)
            .selectYear(
              const ViewingYear(id: 2026, name: '2026-2027', isCurrent: true),
            );
        await tester.pumpAndSettle();

        expect(find.text('Học kỳ 1 · 2026-2027'), findsWidgets);
        expect(find.text('Học kỳ 1 · 2024-2025'), findsNothing);

        container
            .read(viewingYearProvider.notifier)
            .selectYear(const ViewingYear(id: 2028, name: '2028-2029'));
        await tester.pumpAndSettle();

        expect(find.text('Năm học này chưa có học kỳ'), findsOneWidget);
      },
    );

    testWidgets(
      'hộp thoại xác nhận khởi tạo và lưu lịch ghi rõ Học kỳ … · Năm học …',
      (tester) async {
        final repo = FakeSemesterDeadlinesRepository(
          semesters: multiYearSemesters,
          deadlines: SemesterDeadlinesDto(
            items: [
              SemesterDeadlineDto(
                type: SemesterDeadlineDtoTypeEnum.TX,
                opensAt: DateTime.utc(2026, 10, 1),
                closesAt: DateTime.utc(2026, 10, 30),
                version: 1,
                expired: false,
              ),
            ],
          ),
        );

        final container = ProviderContainer(
          overrides: [
            semesterDeadlinesRepositoryProvider.overrideWithValue(repo),
            sessionProvider.overrideWith(
              (ref) => FakeSessionController(session),
            ),
            academicYearsProvider.overrideWith((ref) => mockYears),
          ],
        );
        container
            .read(viewingYearProvider.notifier)
            .selectYear(const ViewingYear(id: 2024, name: '2024-2025'));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: SemesterDeadlinesScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final editBtn = find.text('Sửa lịch');
        await tester.tap(editBtn);
        await tester.pumpAndSettle();

        expect(find.text('Học kỳ 1 · Năm học 2024-2025'), findsOneWidget);
        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'nút Tải lại trên AppScaffold gọi lại API và cập nhật giao diện',
      (tester) async {
        final repo = FakeSemesterDeadlinesRepository(
          semesters: multiYearSemesters,
        );

        final container = ProviderContainer(
          overrides: [
            semesterDeadlinesRepositoryProvider.overrideWithValue(repo),
            sessionProvider.overrideWith(
              (ref) => FakeSessionController(session),
            ),
            academicYearsProvider.overrideWith((ref) => mockYears),
          ],
        );
        container
            .read(viewingYearProvider.notifier)
            .selectYear(const ViewingYear(id: 2024, name: '2024-2025'));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: SemesterDeadlinesScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('semester-deadlines-refresh-btn')),
          findsNothing,
        );
        expect(find.text('Học kỳ 1 · 2024-2025'), findsWidgets);
      },
    );
  });
}
