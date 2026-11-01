import 'package:flutter/material.dart';

import '../design_tokens.dart';
import 'app_pager.dart';

/// Các cỡ trang cho phép chọn ở mọi danh sách/bảng.
const appPageSizes = <int>[10, 30, 50];

/// Cỡ trang mặc định.
const appDefaultPageSize = 10;

/// Cắt [rows] theo trang hiện tại; `page` tính từ 1 và được ép vào khoảng hợp lệ.
List<T> pageSlice<T>(List<T> rows, int page, int pageSize) {
  final pages = appPageCount(rows.length, pageSize);
  final current = page.clamp(1, pages);
  final start = (current - 1) * pageSize;
  return rows.skip(start).take(pageSize).toList();
}

/// Số trang (tối thiểu 1).
int appPageCount(int total, int pageSize) =>
    total <= 0 ? 1 : (total / pageSize).ceil();

/// Chân danh sách dùng chung: chọn số dòng mỗi trang (10 / 30 / 50), tổng số
/// mục và thanh phân trang. Mọi màn hình danh sách/bảng dùng widget này để
/// giao diện phân trang giống nhau.
class AppListFooter extends StatelessWidget {
  const AppListFooter({
    super.key,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    this.loadingMore = false,
    this.itemLabel = 'mục',
  });

  /// Tổng số mục sau khi lọc.
  final int total;

  /// Trang hiện tại, tính từ 1.
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  /// Đang tải tiếp dữ liệu dưới nền: tổng số mục có thể còn tăng.
  final bool loadingMore;
  final String itemLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = TextStyle(color: t.ink2, fontSize: 13);
    final pages = appPageCount(total, pageSize);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Hiển thị', style: style),
              _PageSizeMenu(
                value: pageSize,
                onChanged: onPageSizeChanged,
                tokens: t,
              ),
              Text('/ trang · $total $itemLabel', style: style),
              if (loadingMore)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      key: const ValueKey('app-list-footer-loading'),
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: t.ink3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Đang tải thêm…', style: style),
                  ],
                ),
            ],
          ),
          AppPager(
            page: page.clamp(1, pages),
            pageCount: pages,
            onChanged: onPageChanged,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _PageSizeMenu extends StatelessWidget {
  const _PageSizeMenu({
    required this.value,
    required this.onChanged,
    required this.tokens,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: t.line),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            key: const ValueKey('app-page-size'),
            value: value,
            isDense: true,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            style: TextStyle(
              color: t.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            icon: Icon(Icons.arrow_drop_down, color: t.ink3),
            items: [
              for (final size in appPageSizes)
                DropdownMenuItem(value: size, child: Text('$size')),
            ],
            onChanged: (next) {
              if (next != null && next != value) onChanged(next);
            },
          ),
        ),
      ),
    );
  }
}
