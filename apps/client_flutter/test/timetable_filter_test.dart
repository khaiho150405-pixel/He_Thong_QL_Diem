import 'package:client_flutter/features/timetable/timetable_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets(
      'teacher filter shows full names and searches without Enter at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        num? selected = 1;
        const longName =
            'Giáo viên Nguyễn Thị Thanh Huyền phụ trách môn Ngữ văn';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: TimetableFilter(
                  label: 'Giáo viên',
                  icon: Icons.badge_outlined,
                  value: selected,
                  options: const [
                    (value: null, label: 'Tất cả giáo viên'),
                    (value: 1, label: longName),
                    (value: 2, label: 'Giáo viên Trần Minh'),
                  ],
                  onChanged: (value) => selected = value,
                ),
              ),
            ),
          ),
        );
        expect(tester.getSize(find.byType(TimetableFilter)).height, 48);
        await tester.tap(find.byType(TimetableFilter));
        await tester.pumpAndSettle();
        final fullText = tester.widget<Text>(
          find.descendant(
            of: find.byType(ListTile).at(1),
            matching: find.byType(Text),
          ),
        );
        expect(fullText.data, longName);
        expect(fullText.maxLines, isNull);
        await tester.enterText(find.byType(TextField), 'trần');
        await tester.pumpAndSettle();
        expect(find.byType(ListTile), findsNWidgets(2));
        await tester.tap(find.text('Giáo viên Trần Minh'));
        await tester.pumpAndSettle();
        expect(selected, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('class filter cancellation keeps selection and All clears it', (
    tester,
  ) async {
    num? selected = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimetableFilter(
            label: 'Lớp học',
            icon: Icons.school_outlined,
            value: selected,
            options: const [
              (value: null, label: 'Tất cả lớp'),
              (value: 1, label: '10A1'),
            ],
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TimetableFilter));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    await tester.tap(find.byType(TimetableFilter));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tất cả lớp'));
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(tester.takeException(), isNull);
  });
}
