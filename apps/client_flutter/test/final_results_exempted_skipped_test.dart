import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/final_results/final_results_panel.dart';
import 'package:client_flutter/features/final_results/repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockFinalResultsRepo extends FinalResultsRepository {
  _MockFinalResultsRepo({required this.currentList}) : super(ApiClientDart());

  FinalResultListDto currentList;
  int calculateCallCount = 0;

  @override
  Future<FinalResultListDto> list(num gradebookId) async {
    return currentList;
  }

  @override
  Future<CalculateFinalResultsDto> calculate({
    required num gradebookId,
    required num expectedVersion,
    required String reason,
  }) async {
    calculateCallCount++;
    return CalculateFinalResultsDto(
      gradebookId: gradebookId,
      gradebookVersion: expectedVersion,
      calculatedStudents: 1,
      skippedStudents: currentList.skipped.length,
      policyVersion: 'DEV-2026-01',
      weightVersion: 'W-01',
      exemptedStudents: currentList.exempted.length,
      results: [],
      skipped: currentList.skipped,
      exempted: currentList.exempted,
    );
  }
}

class _FakeSessionController extends SessionController {
  _FakeSessionController() : super(ApiClientDart()) {
    state = SessionDto(
      id: 2,
      username: 'gv_toan',
      role: SessionDtoRoleEnum.GIAO_VIEN,
      active: true,
      token: 'test-token',
      csrf: 'test-csrf',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final initialList = FinalResultListDto(
    items: [
      FinalResultDto(
        id: 'res-1',
        studentId: 101,
        studentName: 'Nguyễn Văn An',
        finalScore: '8.5',
        classification: 'GIOI',
        weightVersion: 'W-01',
        policyVersion: 'DEV-2026-01',
        calculatedAt: DateTime.parse('2026-10-22T08:00:00Z'),
      ),
    ],
    nextCursor: null,
    exemptedStudents: 2,
    exempted: [
      ExemptedStudentDto(studentId: 201, studentName: 'Trần Miễn 1'),
      ExemptedStudentDto(studentId: 202, studentName: 'Lê Miễn 2'),
    ],
    skippedStudents: 1,
    skipped: [
      SkippedStudentDto(
        studentId: 301,
        studentName: 'Phạm Thiếu 1',
        missingComponents: [
          MissingComponentDto(componentId: 10, name: 'CK'),
        ],
      ),
    ],
  );

  final updatedListAfterCalculate = FinalResultListDto(
    items: [
      FinalResultDto(
        id: 'res-1',
        studentId: 101,
        studentName: 'Nguyễn Văn An',
        finalScore: '9.0',
        classification: 'GIOI',
        weightVersion: 'W-01',
        policyVersion: 'DEV-2026-01',
        calculatedAt: DateTime.parse('2026-10-22T09:00:00Z'),
      ),
    ],
    nextCursor: null,
    exemptedStudents: 1,
    exempted: [
      ExemptedStudentDto(studentId: 201, studentName: 'Trần Miễn 1'),
    ],
    skippedStudents: 0,
    skipped: [],
  );

  testWidgets(
    'Mở panel với list có exempted 2 học sinh, skipped 1 hiển thị đúng danh sách không cần bấm Tính',
    (tester) async {
      final repo = _MockFinalResultsRepo(currentList: initialList);
      final container = ProviderContainer(
        overrides: [
          finalResultsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: FinalResultsPanel(
                  gradebookId: 10,
                  gradebookVersion: 1,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra tab số lượng
      expect(find.byKey(const ValueKey('group-tab-exempted')), findsOneWidget);
      expect(find.byKey(const ValueKey('group-tab-skipped')), findsOneWidget);
      expect(find.text('Miễn môn (2)'), findsOneWidget);
      expect(find.text('Thiếu điểm (1)'), findsOneWidget);

      // Xem tab Miễn môn
      await tester.tap(find.byKey(const ValueKey('group-tab-exempted')));
      await tester.pumpAndSettle();
      expect(find.text('Trần Miễn 1'), findsOneWidget);
      expect(find.text('Lê Miễn 2'), findsOneWidget);

      // Xem tab Thiếu điểm
      await tester.tap(find.byKey(const ValueKey('group-tab-skipped')));
      await tester.pumpAndSettle();
      expect(find.text('Phạm Thiếu 1'), findsOneWidget);
      expect(find.text('CK'), findsOneWidget);
    },
  );

  testWidgets('Đóng và mở lại panel vẫn đúng số lượng', (tester) async {
    final repo = _MockFinalResultsRepo(currentList: initialList);
    final container = ProviderContainer(
      overrides: [
        finalResultsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    var showPanel = true;
    late StateSetter setHostState;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                if (!showPanel) {
                  return const Text('Panel đã đóng');
                }
                return const SingleChildScrollView(
                  child: FinalResultsPanel(
                    gradebookId: 10,
                    gradebookVersion: 1,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Miễn môn (2)'), findsOneWidget);
    expect(find.text('Thiếu điểm (1)'), findsOneWidget);

    // Đóng panel
    setHostState(() => showPanel = false);
    await tester.pumpAndSettle();
    expect(find.text('Panel đã đóng'), findsOneWidget);
    expect(find.text('Miễn môn (2)'), findsNothing);

    // Mở lại panel
    setHostState(() => showPanel = true);
    await tester.pumpAndSettle();

    // Vẫn đúng số lượng mà không cần bấm tính
    expect(find.text('Miễn môn (2)'), findsOneWidget);
    expect(find.text('Thiếu điểm (1)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('group-tab-exempted')));
    await tester.pumpAndSettle();
    expect(find.text('Trần Miễn 1'), findsOneWidget);
    expect(find.text('Lê Miễn 2'), findsOneWidget);
  });

  testWidgets(
    'Bấm Tính → sau khi tải lại list số lượng cập nhật theo list mới',
    (tester) async {
      final repo = _MockFinalResultsRepo(currentList: initialList);
      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(
            (ref) => _FakeSessionController(),
          ),
          finalResultsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: FinalResultsPanel(
                  gradebookId: 10,
                  gradebookVersion: 1,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Miễn môn (2)'), findsOneWidget);
      expect(find.text('Thiếu điểm (1)'), findsOneWidget);

      // Cập nhật dữ liệu mà repository trả về khi tải lại
      repo.currentList = updatedListAfterCalculate;

      // Bấm "Tính kết quả"
      final calculateButton = find.byKey(const ValueKey('calculate-final-results'));
      expect(calculateButton, findsOneWidget);
      await tester.tap(calculateButton);
      await tester.pumpAndSettle();

      // Nhập lý do
      expect(find.text('Tính kết quả tổng kết'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Lý do tính hoặc tính lại'),
        'Tổng kết học kỳ I',
      );
      await tester.tap(find.text('Tính kết quả').last);
      await tester.pumpAndSettle();

      expect(repo.calculateCallCount, 1);

      // Sau khi tính và tải lại, số lượng cập nhật theo list mới
      expect(find.text('Miễn môn (1)'), findsOneWidget);
      expect(find.text('Thiếu điểm (0)'), findsOneWidget);

      // Mở nhóm Miễn môn: chỉ còn 1 học sinh
      await tester.tap(find.byKey(const ValueKey('group-tab-exempted')));
      await tester.pumpAndSettle();
      expect(find.text('Trần Miễn 1'), findsOneWidget);
      expect(find.text('Lê Miễn 2'), findsNothing);

      // Mở nhóm Thiếu điểm: hiển thị rỗng
      await tester.tap(find.byKey(const ValueKey('group-tab-skipped')));
      await tester.pumpAndSettle();
      expect(find.text('Không có học sinh thiếu điểm'), findsOneWidget);
    },
  );
}
