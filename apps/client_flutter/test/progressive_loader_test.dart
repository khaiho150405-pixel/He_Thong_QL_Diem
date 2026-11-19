import 'dart:async';

import 'package:client_flutter/core/progressive_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int changes;
  late ProgressiveLoader<int, int> loader;

  setUp(() {
    changes = 0;
    loader = ProgressiveLoader(onChanged: () => changes++);
  });

  Future<LoadedChunk<int, int>> pages(int? cursor, List<List<int>> data) async {
    final index = cursor ?? 0;
    return LoadedChunk(data[index], index + 1 < data.length ? index + 1 : null);
  }

  test(
    'refresh giữ danh sách cũ cho tới khi tải xong rồi thay một lần',
    () async {
      await loader.start(
        'k',
        (c) => pages(c, [
          [1, 2],
        ]),
      );
      expect(loader.items, [1, 2]);

      final gate = Completer<void>();
      final done = loader.refresh('k', (c) async {
        await gate.future;
        return pages(c, [
          [1, 2],
          [3],
        ]);
      });
      await Future<void>.delayed(Duration.zero);
      expect(loader.items, [1, 2]);

      gate.complete();
      await done;
      expect(loader.items, [1, 2, 3]);
      expect(loader.key, 'k');
      expect(changes, greaterThan(0));
    },
  );

  test('refresh bị lỗi thì giữ nguyên danh sách đang hiện', () async {
    await loader.start(
      'k',
      (c) => pages(c, [
        [1, 2],
      ]),
    );
    await expectLater(
      loader.refresh('k', (_) async => throw StateError('mạng')),
      throwsStateError,
    );
    expect(loader.items, [1, 2]);
  });

  test('refresh mới hủy refresh cũ đang chạy dở', () async {
    await loader.start(
      'k',
      (c) => pages(c, [
        [1],
      ]),
    );
    final slow = Completer<void>();
    final first = loader.refresh('k', (c) async {
      await slow.future;
      return pages(c, [
        [9],
      ]);
    });
    await loader.refresh(
      'k',
      (c) => pages(c, [
        [1, 2],
      ]),
    );
    slow.complete();
    await first;
    expect(loader.items, [1, 2]);
  });

  test('removeWhere bỏ đúng phần tử tại chỗ và báo thay đổi', () async {
    await loader.start(
      'k',
      (c) => pages(c, [
        [1, 2, 3],
      ]),
    );
    final before = changes;
    loader.removeWhere((item) => item == 2);
    expect(loader.items, [1, 3]);
    expect(changes, before + 1);
  });
}
