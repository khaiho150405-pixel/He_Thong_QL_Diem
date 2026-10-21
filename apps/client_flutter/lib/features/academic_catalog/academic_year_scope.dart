import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_controls.dart';
import 'repository.dart';

/// Đại diện cho năm học đang xem trong phiên làm việc.
class ViewingYear {
  const ViewingYear({
    this.id,
    required this.name,
    this.isCurrent = false,
    this.raw,
  });

  final num? id;
  final String name;
  final bool isCurrent;
  final Json? raw;

  bool get isAll => id == null;

  static const all = ViewingYear(
    id: null,
    name: 'Tất cả các năm',
    isCurrent: false,
  );

  factory ViewingYear.fromRow(Json row) => ViewingYear(
    id: row['ma_nam_hoc'] as num?,
    name: (row['ten'] ?? row['label'] ?? 'Năm ${row['ma_nam_hoc']}').toString(),
    isCurrent: row['hien_hanh'] == true,
    raw: row,
  );

  dynamic operator [](String key) {
    if (key == 'ma_nam_hoc') return id;
    if (key == 'ten') return name;
    if (key == 'hien_hanh') return isCurrent;
    return raw?[key];
  }

  Json toJson() =>
      raw ??
      {if (id != null) 'ma_nam_hoc': id, 'ten': name, 'hien_hanh': isCurrent};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewingYear &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ViewingYear(id: $id, name: $name, isCurrent: $isCurrent)';
}

/// Tải danh sách tất cả năm học (có cache, làm mới khi tạo/sửa/xóa năm).
final academicYearsProvider = FutureProvider<List<Json>>((ref) async {
  try {
    final repo = ref.watch(catalogRepositoryProvider);
    final items = <Json>[];
    String? cursor;
    final seen = <String>{};
    do {
      final page = await repo.list('years', cursor: cursor);
      items.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor != null && !seen.add(cursor)) break;
    } while (cursor != null);
    return items;
  } catch (_) {
    return const [];
  }
});

/// Lấy năm hiện hành từ danh sách năm học.
final currentYearProvider = FutureProvider<ViewingYear?>((ref) async {
  final years = await ref.watch(academicYearsProvider.future);
  for (final y in years) {
    if (y['hien_hanh'] == true) {
      return ViewingYear.fromRow(y);
    }
  }
  return null;
});

/// Quản lý năm học đang xem trong phiên làm việc. Mặc định là năm hiện hành.
class ViewingYearNotifier extends StateNotifier<ViewingYear?> {
  ViewingYearNotifier(this.ref) : super(null) {
    _sub = ref.listen<AsyncValue<ViewingYear?>>(currentYearProvider, (
      prev,
      next,
    ) {
      if (!_hasExplicitSelection && next.hasValue && next.value != null) {
        state = next.value;
      }
    }, fireImmediately: true);
  }

  final Ref ref;
  ProviderSubscription? _sub;
  bool _hasExplicitSelection = false;

  void selectYear(ViewingYear? year) {
    _hasExplicitSelection = true;
    state = year ?? ViewingYear.all;
  }

  void setYear(ViewingYear year) {
    _hasExplicitSelection = true;
    state = year;
  }

  void setYearFromRow(Json row) {
    _hasExplicitSelection = true;
    state = ViewingYear.fromRow(row);
  }

  void resetToCurrent() {
    _hasExplicitSelection = false;
    final curr = ref.read(currentYearProvider).valueOrNull;
    state = curr;
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }
}

final viewingYearProvider =
    StateNotifierProvider<ViewingYearNotifier, ViewingYear?>((ref) {
      return ViewingYearNotifier(ref);
    });

/// Dropdown lọc theo năm học dùng chung cho các màn hình danh mục và bảng điểm.
class AcademicYearFilterControl extends ConsumerWidget {
  const AcademicYearFilterControl({
    super.key,
    required this.years,
    required this.onChanged,
    this.width,
    this.allowAll = true,
  });

  final List<Json> years;
  final VoidCallback onChanged;
  final double? width;
  final bool allowAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewingYear = ref.watch(viewingYearProvider);
    final num? effectiveValue;
    if (!allowAll && (viewingYear == null || viewingYear.isAll)) {
      Json? current;
      for (final y in years) {
        if (y['hien_hanh'] == true) {
          current = y;
          break;
        }
      }
      current ??= years.firstOrNull;
      effectiveValue = current?['ma_nam_hoc'] as num?;
    } else {
      effectiveValue = viewingYear?.id;
    }

    final isArchive =
        viewingYear != null && !viewingYear.isAll && !viewingYear.isCurrent;

    final dropdown = AppFilterDropdown<num?>(
      label: 'Năm học',
      icon: Icons.calendar_month_outlined,
      value: effectiveValue,
      width: width,
      items: [
        if (allowAll)
          const DropdownMenuItem<num?>(
            value: null,
            child: Text('Tất cả các năm'),
          ),
        for (final y in years)
          DropdownMenuItem<num?>(
            value: y['ma_nam_hoc'] as num?,
            child: Text(
              y['hien_hanh'] == true
                  ? '${y['ten']} (hiện hành)'
                  : '${y['ten']}',
            ),
          ),
      ],
      onChanged: (newId) {
        if (newId == null) {
          ref.read(viewingYearProvider.notifier).selectYear(ViewingYear.all);
        } else {
          final found = years.firstWhere(
            (y) => y['ma_nam_hoc'] == newId,
            orElse: () => {'ma_nam_hoc': newId, 'ten': 'Năm $newId'},
          );
          ref
              .read(viewingYearProvider.notifier)
              .selectYear(ViewingYear.fromRow(found));
        }
        onChanged();
      },
    );

    if (!isArchive) return dropdown;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        dropdown,
        const AppBadge('Năm lưu trữ', tone: AppBadgeTone.neutral, dot: false),
      ],
    );
  }
}
