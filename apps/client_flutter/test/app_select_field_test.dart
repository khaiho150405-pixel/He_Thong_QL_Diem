import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client_flutter/app/widgets/app_select_field.dart';

void main() {
  testWidgets(
    '1. Tap ô thì menu mở và vị trí top của menu >= bottom của ô (menu nằm dưới ô)',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: SizedBox(
                  width: 320,
                  child: AppSelectField<String>(
                    label: 'Năm học',
                    value: '2025',
                    items: const [
                      DropdownMenuItem(
                        value: '2024',
                        child: Text('2024 - 2025'),
                      ),
                      DropdownMenuItem(
                        value: '2025',
                        child: Text('2025 - 2026'),
                      ),
                      DropdownMenuItem(
                        value: '2026',
                        child: Text('2026 - 2027'),
                      ),
                    ],
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fieldFinder = find.byType(TextField);
      final fieldBottom = tester.getBottomLeft(fieldFinder).dy;

      await tester.tap(fieldFinder);
      await tester.pumpAndSettle();

      final itemFinder = find.widgetWithText(MenuItemButton, '2024 - 2025');
      expect(itemFinder, findsOneWidget);

      final menuTop = tester.getTopLeft(itemFinder).dy;
      // Vị trí top của menu >= bottom của ô (cho phép sai số 1px do border)
      expect(menuTop, greaterThanOrEqualTo(fieldBottom - 1));
    },
  );

  testWidgets('1b. Tap icon mũi tên thì menu cũng mở ra bên dưới ô', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: SizedBox(
                width: 320,
                child: AppSelectField<String>(
                  label: 'Năm học',
                  value: '2025',
                  items: const [
                    DropdownMenuItem(value: '2024', child: Text('2024 - 2025')),
                    DropdownMenuItem(value: '2025', child: Text('2025 - 2026')),
                  ],
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fieldFinder = find.byType(TextField);
    final fieldBottom = tester.getBottomLeft(fieldFinder).dy;

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();

    final itemFinder = find.widgetWithText(MenuItemButton, '2024 - 2025');
    expect(itemFinder, findsOneWidget);

    final menuTop = tester.getTopLeft(itemFinder).dy;
    expect(menuTop, greaterThanOrEqualTo(fieldBottom - 1));
  });

  testWidgets(
    '2. Chọn mục thì onChanged nhận đúng giá trị và ô hiện label mới',
    (tester) async {
      String? selectedValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return AppSelectField<String>(
                      label: 'Lớp học',
                      value: selectedValue ?? '10A1',
                      items: const [
                        DropdownMenuItem(
                          value: '10A1',
                          child: Text('Lớp 10A1'),
                        ),
                        DropdownMenuItem(
                          value: '10A2',
                          child: Text('Lớp 10A2'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => selectedValue = val);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(MenuItemButton, 'Lớp 10A2'));
      await tester.pumpAndSettle();

      expect(selectedValue, '10A2');
      expect(find.widgetWithText(TextField, 'Lớp 10A2'), findsOneWidget);
    },
  );

  testWidgets('3. value: null có mục "Tất cả" thì ô hiện "Tất cả"', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: AppSelectField<int?>(
                label: 'Năm học',
                value: null,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tất cả các năm')),
                  DropdownMenuItem(value: 1, child: Text('Năm 2024-2025')),
                  DropdownMenuItem(value: 2, child: Text('Năm 2025-2026')),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Tất cả các năm'), findsOneWidget);
  });

  testWidgets('4. onChanged: null thì tap không mở menu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: AppSelectField<String>(
                label: 'Khóa',
                value: 'A',
                items: const [
                  DropdownMenuItem(value: 'A', child: Text('Mục A')),
                  DropdownMenuItem(value: 'B', child: Text('Mục B')),
                ],
                onChanged: null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(find.byType(MenuItemButton), findsNothing);
  });

  testWidgets('5. Trong Form, validator trả lỗi thì hiện chữ lỗi', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: Center(
              child: SizedBox(
                width: 320,
                child: AppSelectField<String>(
                  label: 'Vai trò',
                  value: null,
                  items: const [
                    DropdownMenuItem(
                      value: 'ADMIN',
                      child: Text('Quản trị viên'),
                    ),
                    DropdownMenuItem(
                      value: 'TEACHER',
                      child: Text('Giáo viên'),
                    ),
                  ],
                  validator: (val) =>
                      val == null ? 'Vui lòng chọn vai trò' : null,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng chọn vai trò'), findsNothing);

    formKey.currentState!.validate();
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng chọn vai trò'), findsOneWidget);
  });

  testWidgets('6. Danh sách 20 mục: gõ lọc ra đúng mục', (tester) async {
    final items = List.generate(
      20,
      (i) => DropdownMenuItem<int>(
        value: i + 1,
        child: Text('Học sinh số ${i + 1}'),
      ),
    );

    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: AppSelectField<int>(
                label: 'Chọn học sinh',
                items: items,
                onChanged: (val) => selected = val,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hoc sinh so 15');
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(MenuItemButton, 'Học sinh số 15'),
      findsOneWidget,
    );
    expect(find.widgetWithText(MenuItemButton, 'Học sinh số 1'), findsNothing);

    await tester.tap(find.widgetWithText(MenuItemButton, 'Học sinh số 15'));
    await tester.pumpAndSettle();

    expect(selected, 15);
  });

  testWidgets(
    '7. Ô đang có giá trị, mở menu thì thấy đủ mọi mục (không bị lọc)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: AppSelectField<String>(
                  label: 'Năm học',
                  value: '2024',
                  items: const [
                    DropdownMenuItem(
                      value: '2023',
                      child: Text('Năm học 2023-2024'),
                    ),
                    DropdownMenuItem(
                      value: '2024',
                      child: Text('Năm học 2024-2025'),
                    ),
                    DropdownMenuItem(
                      value: '2025',
                      child: Text('Năm học 2025-2026'),
                    ),
                  ],
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ban đầu ô hiển thị "Năm học 2024-2025"
      expect(
        find.widgetWithText(TextField, 'Năm học 2024-2025'),
        findsOneWidget,
      );

      // Tap mở menu
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Thấy đầy đủ 3 mục trong menu, không bị lọc còn 1 mục
      expect(
        find.widgetWithText(MenuItemButton, 'Năm học 2023-2024'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(MenuItemButton, 'Năm học 2024-2025'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(MenuItemButton, 'Năm học 2025-2026'),
        findsOneWidget,
      );
    },
  );

  testWidgets('8. Gõ "nam hoc" khớp "Năm học", gõ "DUONG" khớp "Dương"', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: AppSelectField<String>(
                label: 'Danh sách',
                items: const [
                  DropdownMenuItem(
                    value: '1',
                    child: Text('Năm học 2024-2025'),
                  ),
                  DropdownMenuItem(
                    value: '2',
                    child: Text('Thầy Dương Văn Khoa'),
                  ),
                  DropdownMenuItem(value: '3', child: Text('Môn Vật Lý')),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap và gõ "nam hoc"
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'nam hoc');
    await tester.pumpAndSettle();

    expect(find.textContaining('Năm học 2024-2025'), findsOneWidget);
    expect(find.textContaining('Thầy Dương'), findsNothing);

    // Xóa và gõ "DUONG"
    await tester.enterText(find.byType(TextField), 'DUONG');
    await tester.pumpAndSettle();

    expect(find.textContaining('Thầy Dương Văn Khoa'), findsOneWidget);
    expect(find.textContaining('Năm học'), findsNothing);
  });

  testWidgets('9. Danh sách 4 mục vẫn gõ lọc được', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: AppSelectField<String>(
                label: 'Khối',
                items: const [
                  DropdownMenuItem(value: '10', child: Text('Khối 10')),
                  DropdownMenuItem(value: '11', child: Text('Khối 11')),
                  DropdownMenuItem(value: '12', child: Text('Khối 12')),
                  DropdownMenuItem(value: 'other', child: Text('Khối chuyên')),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'chuyen');
    await tester.pumpAndSettle();

    expect(find.textContaining('Khối chuyên'), findsOneWidget);
    expect(find.textContaining('Khối 10'), findsNothing);
  });

  testWidgets(
    '10. Gõ chuỗi không khớp thì hiện "Không tìm thấy" và không gọi onChanged',
    (tester) async {
      bool changedCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: AppSelectField<String>(
                  label: 'Môn học',
                  items: const [
                    DropdownMenuItem(value: 'toan', child: Text('Toán học')),
                    DropdownMenuItem(value: 'van', child: Text('Ngữ văn')),
                  ],
                  onChanged: (_) => changedCalled = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'khongtontai');
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy “khongtontai”'), findsOneWidget);
      expect(changedCalled, isFalse);
    },
  );

  testWidgets(
    '11. Gõ rồi bỏ focus không chọn thì ô trả lại label cũ, onChanged không bị gọi',
    (tester) async {
      bool changedCalled = false;
      final focusOutside = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 320,
                  child: AppSelectField<String>(
                    label: 'Lớp',
                    value: '10A',
                    items: const [
                      DropdownMenuItem(value: '10A', child: Text('Lớp 10A')),
                      DropdownMenuItem(value: '10B', child: Text('Lớp 10B')),
                    ],
                    onChanged: (_) => changedCalled = true,
                  ),
                ),
                TextField(
                  focusNode: focusOutside,
                  key: const ValueKey('outside'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ban đầu là Lớp 10A
      expect(find.widgetWithText(TextField, 'Lớp 10A'), findsOneWidget);

      // Tap và gõ dở "Lớp 10B"
      await tester.tap(find.widgetWithText(TextField, 'Lớp 10A'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Lớp 10A'),
        'chuaduyet',
      );
      await tester.pumpAndSettle();

      // Chuyển focus ra ngoài mà không chọn
      focusOutside.requestFocus();
      await tester.pumpAndSettle();

      // Trả lại label cũ "Lớp 10A", onChanged không bị gọi
      expect(find.widgetWithText(TextField, 'Lớp 10A'), findsOneWidget);
      expect(changedCalled, isFalse);
    },
  );

  testWidgets(
    '12. Bàn phím: gõ, ↓, Enter chọn mục; Esc đóng và giữ giá trị cũ',
    (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: AppSelectField<String>(
                  label: 'Môn',
                  value: 'van',
                  items: const [
                    DropdownMenuItem(value: 'toan', child: Text('Toán học')),
                    DropdownMenuItem(value: 'tin', child: Text('Tin học')),
                    DropdownMenuItem(value: 'van', child: Text('Ngữ văn')),
                  ],
                  onChanged: (v) => selected = v,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fieldFinder = find.widgetWithText(TextField, 'Ngữ văn');
      await tester.tap(fieldFinder);
      await tester.pumpAndSettle();

      // Gõ từ khóa tìm kiếm "tin"
      await tester.enterText(fieldFinder, 'tin');
      await tester.pumpAndSettle();

      // Nhấn Escape -> Đóng menu và hoàn tác về "Ngữ văn"
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Ngữ văn'), findsOneWidget);
      expect(selected, isNull);

      // Mở lại và chọn bằng Enter
      await tester.tap(find.widgetWithText(TextField, 'Ngữ văn'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'toan');
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(selected, 'toan');
    },
  );

  testWidgets('13. searchable: false thì không bật tìm kiếm, chỉ chọn', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: AppSelectField<String>(
                label: 'Cố định',
                value: 'A',
                searchable: false,
                items: const [
                  DropdownMenuItem(value: 'A', child: Text('Tùy chọn A')),
                  DropdownMenuItem(value: 'B', child: Text('Tùy chọn B')),
                ],
                onChanged: (v) => selected = v,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dropdownMenuFinder = find.byType(DropdownMenu<String?>);
    final dropdownMenu = tester.widget<DropdownMenu<String?>>(
      dropdownMenuFinder,
    );
    expect(dropdownMenu.enableFilter, isFalse);
    expect(dropdownMenu.enableSearch, isFalse);
    expect(dropdownMenu.requestFocusOnTap, isFalse);

    // Tap và chọn mục
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(MenuItemButton, 'Tùy chọn B'));
    await tester.pumpAndSettle();

    expect(selected, 'B');
  });

  testWidgets(
    '14. Nút xóa nhanh (×) khi đang gõ dở xóa từ khóa, không đổi giá trị',
    (tester) async {
      String? selected = 'old';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: AppSelectField<String>(
                  label: 'Trường',
                  value: selected,
                  items: const [
                    DropdownMenuItem(value: 'old', child: Text('Mục cũ')),
                    DropdownMenuItem(value: 'new', child: Text('Mục mới')),
                  ],
                  onChanged: (v) => selected = v,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'tu khoa go do');
      await tester.pumpAndSettle();

      // Nút clear xuất hiện
      final clearBtn = find.byKey(const ValueKey('app-select-clear-button'));
      expect(clearBtn, findsOneWidget);

      // Bấm nút clear
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      // Giá trị đã chọn không đổi
      expect(selected, 'old');
      // Ô nhập được xóa trống từ khóa để hiện lại đủ danh sách
      expect(
        find.byKey(const ValueKey('app-select-clear-button')),
        findsNothing,
      );
    },
  );

  testWidgets(
    '15. Ô rộng 300 trong khung 1200 với width: double.infinity: mở menu thì menu rộng ≈ 300 và căn trái theo ô',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 300,
                child: AppSelectField<String>(
                  label: 'Học kỳ',
                  value: 'hk1',
                  width: double.infinity,
                  items: const [
                    DropdownMenuItem(
                      value: 'hk1',
                      child: Text('Học kỳ 1 · 2024-2025'),
                    ),
                    DropdownMenuItem(
                      value: 'hk2',
                      child: Text('Học kỳ 2 · 2024-2025'),
                    ),
                  ],
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fieldFinder = find.byType(TextField);
      final fieldRect = tester.getRect(fieldFinder);
      expect(fieldRect.width, closeTo(300, 1.0));

      await tester.tap(fieldFinder);
      await tester.pumpAndSettle();

      final itemFinder = find.widgetWithText(
        MenuItemButton,
        'Học kỳ 1 · 2024-2025',
      );
      expect(itemFinder, findsOneWidget);

      final itemRect = tester.getRect(itemFinder);
      // Menu rộng ≈ 300 và căn trái theo ô
      expect(itemRect.width, closeTo(300, 2.0));
      expect(itemRect.left, closeTo(fieldRect.left, 2.0));
    },
  );
}
