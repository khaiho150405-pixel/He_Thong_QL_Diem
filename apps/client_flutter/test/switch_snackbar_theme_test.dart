import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final entry in {
    'sáng': (AppTheme.light(), AppTokens.light),
    'tối': (AppTheme.dark(), AppTokens.dark),
  }.entries) {
    final theme = entry.value.$1;
    final t = entry.value.$2;

    group('giao diện ${entry.key}', () {
      test('thông báo không trùng màu thanh bên', () {
        final snack = theme.snackBarTheme;
        expect(snack.backgroundColor, isNot(t.navy));
        expect(snack.backgroundColor, isNot(t.navy2));
        expect(snack.behavior, SnackBarBehavior.floating);
      });

      test('công tắc bật nhưng bị khóa vẫn thấy nút gạt và dấu tích', () {
        final sw = theme.switchTheme;
        const locked = {WidgetState.selected, WidgetState.disabled};
        final thumb = sw.thumbColor!.resolve(locked)!;
        final track = sw.trackColor!.resolve(locked)!;
        expect(thumb, isNot(track));
        expect(thumb.a, greaterThan(.8));
        expect(sw.thumbIcon!.resolve(locked), isNotNull);
        expect(sw.thumbIcon!.resolve({WidgetState.disabled}), isNull);
      });

      test('công tắc tắt và bị khóa không biến mất vào nền', () {
        final sw = theme.switchTheme;
        const off = {WidgetState.disabled};
        expect(sw.thumbColor!.resolve(off), isNot(sw.trackColor!.resolve(off)));
        expect(sw.trackOutlineColor!.resolve(off), t.line2);
      });
    });
  }

  testWidgets('công tắc bị khóa đang bật dựng được, không lỗi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: Switch(value: true, onChanged: null)),
      ),
    );
    expect(find.byType(Switch), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
