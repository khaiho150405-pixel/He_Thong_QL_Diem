import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/features/academic_catalog/repository.dart';
import 'package:client_flutter/features/academic_catalog/year_closing_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeYears extends CatalogRepository {
  _FakeYears(this.status) : super(ApiClientDart(dio: Dio()));
  YearClosingDto status;
  final calls = <(bool, String)>[];

  @override
  Future<YearClosingDto> yearClosing(num id) async => status;

  @override
  Future<void> changeYearClosing(
    num id, {
    required bool close,
    required String reason,
  }) async {
    calls.add((close, reason));
  }
}

YearClosingDto _status({
  String? closedAt,
  bool ready = true,
  List<YearClosingIssueDto> issues = const [],
}) => YearClosingDto(
  yearId: 3,
  closedAt: closedAt,
  ready: ready,
  issues: issues,
  history: [],
);

Future<void> _open(WidgetTester tester, _FakeYears repository) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => YearClosingDialog(
                repository: repository,
                yearId: 3,
                yearName: '2025-2026',
              ),
            ),
            child: const Text('mở'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('mở'));
  await tester.pumpAndSettle();
}

FilledButton _confirm(WidgetTester tester) => tester.widget<FilledButton>(
  find.byKey(const ValueKey('app-dialog-confirm')),
);

void main() {
  testWidgets('năm còn việc dở: liệt kê việc cần xử lý, không cho đóng', (
    tester,
  ) async {
    final repository = _FakeYears(
      _status(
        ready: false,
        issues: [
          YearClosingIssueDto(
            code: 'STUDENTS_NOT_PROMOTED',
            severity: 'BLOCKING',
            label: '12A1',
            count: 3,
          ),
        ],
      ),
    );
    await _open(tester, repository);

    expect(find.text('Cần xử lý trước khi đóng'), findsOneWidget);
    expect(find.textContaining('Lớp 12A1 còn 3 học sinh'), findsOneWidget);
    expect(find.byKey(const ValueKey('year-closing-reason')), findsNothing);
    expect(_confirm(tester).onPressed, isNull);
  });

  testWidgets('đóng năm bắt buộc nhập lý do', (tester) async {
    final repository = _FakeYears(_status());
    await _open(tester, repository);

    expect(_confirm(tester).onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('year-closing-reason')),
      '  Hết năm học  ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('app-dialog-confirm')));
    await tester.pumpAndSettle();

    expect(repository.calls, [(true, 'Hết năm học')]);
    expect(find.byType(YearClosingDialog), findsNothing);
  });

  testWidgets('năm đã đóng: nút chuyển thành mở lại', (tester) async {
    final repository = _FakeYears(
      _status(closedAt: '2026-06-30T00:00:00.000Z'),
    );
    await _open(tester, repository);

    expect(find.text('Mở lại năm học 2025-2026?'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('year-closing-reason')),
      'Đính chính',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('app-dialog-confirm')));
    await tester.pumpAndSettle();

    expect(repository.calls, [(false, 'Đính chính')]);
  });
}
