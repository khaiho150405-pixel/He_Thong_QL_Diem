import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/app/widgets/app_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('toolbar controls share the standard desktop dimensions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Wrap(
            children: [
              AppFilterDropdown<int>(
                key: const ValueKey('filter'),
                label: 'Lớp học',
                icon: Icons.meeting_room_outlined,
                value: null,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tất cả lớp')),
                ],
                onChanged: (_) {},
              ),
              AppActionButton(
                key: const ValueKey('import'),
                label: 'Nhập từ file',
                icon: Icons.upload_file_outlined,
                kind: AppActionButtonKind.secondary,
                onPressed: () {},
              ),
              AppActionButton(
                key: const ValueKey('add'),
                label: 'Thêm mới',
                icon: Icons.add,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('filter'))),
      const Size(300, 48),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('import'))),
      const Size(164, 48),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('add'))),
      const Size(164, 48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('filter control shrinks without overflow on a 320px phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppFilterDropdown<int>(
            key: const ValueKey('mobile-filter'),
            label: 'Giáo viên',
            icon: Icons.badge_outlined,
            value: null,
            items: const [
              DropdownMenuItem(
                value: null,
                child: Text('Tất cả giáo viên trong trường'),
              ),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('mobile-filter'))),
      const Size(248, 48),
    );
    expect(tester.takeException(), isNull);
  });
}
