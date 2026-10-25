import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/session.dart';
import '../design_tokens.dart';
import 'app_avatar.dart';

final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);
final sidebarOpenGroupsProvider = StateProvider<Set<String>>(
  (ref) => {
    'grades',
    'academic_structure',
    'subjects_weights',
    'profiles_accounts',
  },
);

/// Mục con trong một nhóm gập của sidebar.
typedef _SidebarItem = ({
  IconData icon,
  String title,
  String route,
  String? countBadge,
});

/// Thanh điều hướng bên (`.side` của prototype): nền navy, mục cao 44, mục
/// đang chọn có nền mờ và vạch vàng 3px bên trái, cuối thanh là avatar, tên,
/// vai trò và nút đăng xuất.
///
/// [onLogout] do màn hình cha cấp (kèm hộp thoại xác nhận); khi để trống thì
/// đăng xuất ngay như trang chủ.
class AppSidebar extends ConsumerWidget {
  const AppSidebar({
    super.key,
    this.currentPath,
    this.inDrawer = false,
    this.isCollapsed,
    this.onBeforeNavigate,
    this.onLogout,
  });

  final String? currentPath;
  final bool inDrawer;
  final bool? isCollapsed;
  final Future<bool> Function()? onBeforeNavigate;
  final Future<void> Function()? onLogout;

  bool _isRouteActive(String route) =>
      currentPath == route ||
      (route != '/' && (currentPath?.startsWith(route) ?? false));

  static String _roleLabel(String role) => switch (role) {
    'QUAN_TRI_VIEN' => 'Quản trị viên',
    'GIAO_VIEN' => 'Giáo viên',
    _ => 'Học sinh',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final user = ref.watch(sessionProvider);
    final role = user?.role.value ?? 'GIAO_VIEN';

    final bool collapsed = inDrawer
        ? false
        : (isCollapsed ?? ref.watch(sidebarCollapsedProvider));

    // Nền mờ trên navy: trắng 7% khi rê chuột, 14% khi đang chọn.
    final hoverBg = t.onPri.withAlpha(18);
    final activeBg = t.onPri.withAlpha(36);
    final itemRadius = BorderRadius.circular(AppRadius.sm);

    Future<void> navigate(String route) async {
      if (onBeforeNavigate != null) {
        final allow = await onBeforeNavigate!();
        if (!allow) return;
      }
      if (!context.mounted) return;
      if (inDrawer && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      try {
        context.go(route);
      } catch (_) {
        if (context.mounted) {
          Navigator.of(context).pushNamed(route);
        }
      }
    }

    Future<void> logout() async {
      final notifier = ref.read(sessionProvider.notifier);
      final messenger = ScaffoldMessenger.of(context);
      if (inDrawer && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (onLogout != null) {
        await onLogout!();
        return;
      }
      try {
        await notifier.logout();
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(errorMessage(e))));
      }
    }

    Widget activeBar({double inset = 11}) => Positioned(
      left: 0,
      top: inset,
      bottom: inset,
      width: 3,
      child: DecoratedBox(
        key: const ValueKey('sidebar-active-bar'),
        decoration: BoxDecoration(
          color: t.acc,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );

    Widget countPill(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: t.acc,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          height: 18 / 12,
          fontWeight: FontWeight.w600,
          color: t.onAcc,
        ),
      ),
    );

    /// Khung một mục: nền (đang chọn), hiệu ứng rê chuột, vạch vàng.
    Widget itemShell({
      required bool active,
      required bool tinted,
      required VoidCallback onTap,
      required Widget child,
      double height = 44,
      double barInset = 11,
      EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 1),
    }) {
      return Padding(
        padding: margin,
        child: SizedBox(
          height: height,
          child: Material(
            color: active
                ? activeBg
                : (tinted ? t.onPri.withAlpha(24) : Colors.transparent),
            borderRadius: itemRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              hoverColor: hoverBg,
              splashColor: hoverBg,
              highlightColor: hoverBg,
              child: Stack(
                children: [
                  Positioned.fill(child: child),
                  if (active) activeBar(inset: barInset),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget buildNavTile({
      required IconData icon,
      required String title,
      required String route,
      String? countBadge,
      bool isSubItem = false,
    }) {
      final isActive = _isRouteActive(route);
      final fg = isActive ? t.onPri : t.onNavy;
      final height = isSubItem ? 40.0 : 44.0;

      if (collapsed) {
        return Tooltip(
          message: title,
          preferBelow: false,
          waitDuration: const Duration(milliseconds: 200),
          child: itemShell(
            active: isActive,
            tinted: false,
            height: height,
            barInset: isSubItem ? 9 : 11,
            onTap: () => navigate(route),
            child: Center(child: Icon(icon, size: 20, color: fg)),
          ),
        );
      }

      return itemShell(
        active: isActive,
        tinted: false,
        height: height,
        barInset: isSubItem ? 9 : 11,
        margin: EdgeInsets.fromLTRB(isSubItem ? 12 : 0, 1, 0, 1),
        onTap: () => navigate(route),
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 12),
          child: Row(
            children: [
              Icon(icon, size: isSubItem ? 18 : 20, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isSubItem ? 13.5 : 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: fg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (countBadge != null) countPill(countBadge),
            ],
          ),
        ),
      );
    }

    Widget buildNavGroup({
      required String groupKey,
      required IconData icon,
      required String title,
      required List<_SidebarItem> items,
    }) {
      final openGroups = ref.watch(sidebarOpenGroupsProvider);
      final isOpen = openGroups.contains(groupKey);
      final hasActiveChild = items.any((item) => _isRouteActive(item.route));
      final fg = hasActiveChild ? t.onPri : t.onNavy;

      if (collapsed) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: SizedBox(
            height: 44,
            child: Material(
              color: hasActiveChild ? activeBg : Colors.transparent,
              borderRadius: itemRadius,
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PopupMenuButton<String>(
                      tooltip: title,
                      offset: const Offset(54, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: BorderSide(color: t.line),
                      ),
                      color: t.surface,
                      elevation: 4,
                      onSelected: (route) {
                        if (inDrawer && Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        if (currentPath != route) {
                          try {
                            context.go(route);
                          } catch (_) {
                            Navigator.of(context).pushNamed(route);
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem<String>(
                          enabled: false,
                          height: 32,
                          child: Text(
                            title.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: t.ink3,
                              letterSpacing: 0.88,
                            ),
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        ...items.map(
                          (it) => PopupMenuItem<String>(
                            value: it.route,
                            height: 40,
                            child: Row(
                              children: [
                                Icon(it.icon, size: 18, color: t.ink2),
                                const SizedBox(width: 10),
                                Text(
                                  it.title,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: t.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      child: Center(child: Icon(icon, size: 20, color: fg)),
                    ),
                  ),
                  if (hasActiveChild) activeBar(),
                ],
              ),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          itemShell(
            active: false,
            tinted: hasActiveChild && !isOpen,
            onTap: () {
              final current = Set<String>.from(
                ref.read(sidebarOpenGroupsProvider),
              );
              if (current.contains(groupKey)) {
                current.remove(groupKey);
              } else {
                current.add(groupKey);
              }
              ref.read(sidebarOpenGroupsProvider.notifier).state = current;
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 14, right: 12),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: hasActiveChild
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: fg,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isOpen
                        ? Icons.expand_more_rounded
                        : Icons.chevron_right_rounded,
                    size: 18,
                    color: t.onNavy,
                  ),
                ],
              ),
            ),
          ),
          if (isOpen)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items.map((item) {
                return buildNavTile(
                  icon: item.icon,
                  title: item.title,
                  route: item.route,
                  countBadge: item.countBadge,
                  isSubItem: true,
                );
              }).toList(),
            ),
        ],
      );
    }

    Widget sectionLabel(String text, {double top = 14}) {
      if (collapsed) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Divider(height: 1, thickness: 1, color: t.navyLine),
        );
      }
      return Padding(
        padding: EdgeInsets.fromLTRB(12, top, 12, 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.88,
            color: t.onNavy.withAlpha(191),
          ),
        ),
      );
    }

    Widget logo() => Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: t.onPri.withAlpha(36),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(Icons.school_outlined, size: 20, color: t.onPri),
    );

    Widget buildBrandHeader() {
      if (collapsed) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 0),
          child: Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.navyLine)),
            ),
            child: Column(
              children: [
                logo(),
                const SizedBox(height: 6),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 22),
                  tooltip: 'Mở rộng sidebar',
                  color: t.onNavy,
                  onPressed: () {
                    ref
                        .read(sidebarCollapsedProvider.notifier)
                        .update((v) => !v);
                  },
                ),
              ],
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 2, 0, 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.navyLine)),
          ),
          child: Row(
            children: [
              logo(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EduScore',
                      style: TextStyle(
                        color: t.onPri,
                        fontSize: 16,
                        height: 19 / 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'THPT BÀ ĐIỂM',
                      style: TextStyle(
                        color: t.onNavy,
                        fontSize: 11,
                        height: 14 / 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.88,
                      ),
                    ),
                  ],
                ),
              ),
              if (!inDrawer)
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 22),
                  tooltip: 'Thu gọn sidebar',
                  color: t.onNavy,
                  onPressed: () {
                    ref
                        .read(sidebarCollapsedProvider.notifier)
                        .update((v) => !v);
                  },
                ),
            ],
          ),
        ),
      );
    }

    Widget logoutButton() => IconButton(
      tooltip: 'Đăng xuất',
      icon: const Icon(Icons.logout_rounded, size: 20),
      color: t.onNavy,
      hoverColor: hoverBg,
      onPressed: logout,
    );

    Widget buildUserFooter() {
      if (user == null) return const SizedBox(height: 12);

      if (collapsed) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.navyLine)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: '${user.username} (${_roleLabel(role)})',
                  preferBelow: false,
                  child: AppAvatar(name: user.username, size: AppAvatarSize.sm),
                ),
                const SizedBox(height: 4),
                logoutButton(),
              ],
            ),
          ),
        );
      }

      Widget userRow(String subtitle) => Row(
        children: [
          AppAvatar(name: user.username, size: AppAvatarSize.sm),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.username,
                  style: TextStyle(
                    color: t.onPri,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 18 / 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: t.onNavy, fontSize: 12, height: 1.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          logoutButton(),
        ],
      );

      Widget footer(Widget content) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 6, 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 10, 0, 0),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: t.navyLine)),
          ),
          child: content,
        ),
      );

      if (role == 'GIAO_VIEN') {
        return footer(userRow('Giáo viên bộ môn'));
      }
      if (role == 'HOC_SINH') {
        // Dữ liệu thật từ studentResultsList (giữ nguyên nguồn như bản cũ).
        return _StudentSummaryBuilder(
          builder: (context, data) {
            final summary = data?.summary;
            final subtitle = summary?.className != null
                ? 'Lớp ${summary!.className} · ${summary.termName ?? 'Chưa chốt điểm'}'
                : 'Học sinh';
            final avgNum = summary?.averageScore != null
                ? double.tryParse(summary!.averageScore!)
                : null;
            final average = avgNum != null ? avgNum.toStringAsFixed(1) : '—';
            Widget stat(String value, String label) => Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: t.onPri,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(label, style: TextStyle(color: t.onNavy, fontSize: 11)),
                ],
              ),
            );
            return footer(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 10, right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: t.onPri.withAlpha(18),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: t.navyLine),
                    ),
                    child: Row(
                      children: [
                        stat(average, 'ĐTB'),
                        stat(summary?.classRank?.toString() ?? '—', 'Xếp hạng'),
                        stat(summary?.classSize.toString() ?? '—', 'Sĩ số'),
                      ],
                    ),
                  ),
                  userRow(subtitle),
                ],
              ),
            );
          },
        );
      }
      return footer(userRow(_roleLabel(role)));
    }

    final timetableTitle = role == 'QUAN_TRI_VIEN'
        ? 'Thời khóa biểu'
        : (role == 'GIAO_VIEN' ? 'Lịch dạy của tôi' : 'Thời khóa biểu của tôi');

    return Material(
      key: const ValueKey('app-sidebar'),
      color: t.navy,
      child: Column(
        children: [
          buildBrandHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                sectionLabel('ĐIỀU HƯỚNG CHÍNH', top: 10),
                buildNavTile(
                  icon: Icons.grid_view_outlined,
                  title: 'Tổng quan',
                  route: '/',
                ),
                buildNavTile(
                  icon: Icons.calendar_month_outlined,
                  title: timetableTitle,
                  route: '/timetable',
                ),
                if (role == 'QUAN_TRI_VIEN') ...[
                  buildNavGroup(
                    groupKey: 'grades',
                    icon: Icons.table_chart_outlined,
                    title: 'Điểm & Đánh giá',
                    items: [
                      (
                        icon: Icons.table_chart_outlined,
                        title: 'Bảng điểm',
                        route: '/gradebooks',
                        countBadge: null,
                      ),
                      (
                        icon: Icons.fact_check_outlined,
                        title: 'Duyệt điều chỉnh điểm',
                        route: '/adjustments',
                        countBadge: null,
                      ),
                      (
                        icon: Icons.rule_outlined,
                        title: 'Chính sách',
                        route: '/classification-policy',
                        countBadge: null,
                      ),
                      (
                        icon: Icons.workspace_premium_outlined,
                        title: 'Tổng kết & xếp loại',
                        route: '/final-results',
                        countBadge: null,
                      ),
                      (
                        icon: Icons.grid_on_outlined,
                        title: 'Mẫu bảng điểm',
                        route: '/admin/form-templates',
                        countBadge: null,
                      ),
                    ],
                  ),
                  buildNavGroup(
                    groupKey: 'academic_structure',
                    icon: Icons.school_outlined,
                    title: 'Khung năm học & Lớp',
                    items: [
                      (
                        icon: Icons.calendar_month_outlined,
                        title: 'Năm học',
                        route: '/catalog/years',
                        countBadge: null,
                      ),
                      (
                        icon: Icons.date_range_outlined,
                        title: 'Học kỳ',
                        route: '/catalog/semesters',
                        countBadge: null,
                      ),
                      (
                        icon: Icons.event_available_outlined,
                        title: 'Lịch nhập điểm học kỳ',
                        route: '/admin/semester-deadlines',
                        countBadge: null,
                      ),
                      (
                        icon: Icons.meeting_room_outlined,
                        title: 'Lớp học',
                        route: '/catalog/classes',
                        countBadge: null,
                      ),
                    ],
                  ),
                  buildNavGroup(
                    groupKey: 'subjects_weights',
                    icon: Icons.menu_book_outlined,
                    title: 'Môn học & Hệ số',
                    items: [
                      (
                        icon: Icons.menu_book_outlined,
                        title: 'Môn học',
                        route: '/catalog/subjects',
                        countBadge: null,
                      ),
                      (
                        icon: Icons.percent_outlined,
                        title: 'Hệ số học kỳ',
                        route: '/catalog/semester-weights',
                        countBadge: null,
                      ),
                      (
                        icon: Icons.tune_outlined,
                        title: 'Thành phần điểm',
                        route: '/catalog/components',
                        countBadge: null,
                      ),
                      (
                        icon: Icons.account_tree_outlined,
                        title: 'Môn học & hệ số',
                        route: '/admin/subjects-weights',
                        countBadge: null,
                      ),
                    ],
                  ),
                  buildNavGroup(
                    groupKey: 'profiles_accounts',
                    icon: Icons.people_alt_outlined,
                    title: 'Hồ sơ & Tài khoản',
                    items: [
                      (
                        icon: Icons.people_alt_outlined,
                        title: 'Học sinh',
                        route: '/catalog/students',
                        countBadge: null,
                      ),
                      (
                        icon: Icons.badge_outlined,
                        title: 'Giáo viên',
                        route: '/catalog/teachers',
                        countBadge: null,
                      ),
                      (
                        icon: Icons.assignment_ind_outlined,
                        title: 'Phân công',
                        route: '/catalog/assignments',
                        countBadge: null,
                      ),
                      (
                        icon: Icons.groups_outlined,
                        title: 'Giáo viên & phân công',
                        route: '/admin/teaching-assignments',
                        countBadge: null,
                      ),
                      (
                        icon: Icons.manage_accounts_outlined,
                        title: 'Tài khoản',
                        route: '/catalog/accounts',
                        countBadge: null,
                      ),
                    ],
                  ),
                ],
                if (role == 'GIAO_VIEN') ...[
                  buildNavTile(
                    icon: Icons.table_chart_outlined,
                    title: 'Bảng điểm',
                    route: '/gradebooks',
                  ),
                  buildNavTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Tổng kết & xếp loại',
                    route: '/final-results',
                  ),
                ],
                if (role == 'HOC_SINH')
                  buildNavTile(
                    icon: Icons.fact_check_outlined,
                    title: 'Điểm của tôi',
                    route: '/my-results',
                  ),
              ],
            ),
          ),
          buildUserFooter(),
        ],
      ),
    );
  }
}

/// Tải một lần `studentResultsList` cho phần cuối sidebar của học sinh
/// (lớp, học kỳ, ĐTB, xếp hạng, sĩ số); lỗi thì hiển thị như chưa có dữ liệu.
class _StudentSummaryBuilder extends ConsumerStatefulWidget {
  const _StudentSummaryBuilder({required this.builder});

  final Widget Function(BuildContext context, StudentResultsDto? data) builder;

  @override
  ConsumerState<_StudentSummaryBuilder> createState() =>
      _StudentSummaryBuilderState();
}

class _StudentSummaryBuilderState
    extends ConsumerState<_StudentSummaryBuilder> {
  late final Future<StudentResultsDto?> _future = ref
      .read(apiProvider)
      .getStudentResultsApi()
      .studentResultsList()
      .then((response) => response.data)
      .catchError((_) => null);

  @override
  Widget build(BuildContext context) => FutureBuilder<StudentResultsDto?>(
    future: _future,
    builder: (context, snapshot) => widget.builder(context, snapshot.data),
  );
}
