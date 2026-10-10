import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/session.dart';
import '../theme.dart';

final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);
final sidebarOpenGroupsProvider = StateProvider<Set<String>>(
  (ref) => {
    'grades',
    'academic_structure',
    'subjects_weights',
    'profiles_accounts',
  },
);

class AppSidebar extends ConsumerWidget {
  const AppSidebar({
    super.key,
    this.currentPath,
    this.inDrawer = false,
    this.isCollapsed,
  });

  final String? currentPath;
  final bool inDrawer;
  final bool? isCollapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final role = user?.role.value ?? 'GIAO_VIEN';
    final initial = (user?.username.isNotEmpty ?? false)
        ? user!.username[0].toUpperCase()
        : 'U';

    final bool collapsed = inDrawer
        ? false
        : (isCollapsed ?? ref.watch(sidebarCollapsedProvider));

    Widget buildNavTile({
      required IconData icon,
      required String title,
      required String route,
      String? countBadge,
      bool isSubItem = false,
    }) {
      final isActive =
          currentPath == route ||
          (route != '/' && (currentPath?.startsWith(route) ?? false));

      if (collapsed) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.navActiveBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(color: AppTheme.primarySeed.withAlpha(40))
                : null,
          ),
          child: Tooltip(
            message: title,
            preferBelow: false,
            waitDuration: const Duration(milliseconds: 200),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
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
              child: Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: isActive ? AppTheme.primarySeed : AppTheme.textMuted,
                ),
              ),
            ),
          ),
        );
      }

      return Container(
        margin: EdgeInsets.only(
          left: isSubItem ? 20 : 10,
          right: 10,
          top: 2,
          bottom: 2,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.navActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
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
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSubItem ? 10 : 12,
              vertical: isSubItem ? 7 : 9,
            ),
            child: Row(
              children: [
                if (isActive)
                  Container(
                    width: 3.5,
                    height: isSubItem ? 16 : 18,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySeed,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                Icon(
                  icon,
                  size: isSubItem ? 17 : 19,
                  color: isActive ? AppTheme.primarySeed : AppTheme.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isSubItem ? 12.5 : 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? AppTheme.primarySeed
                          : AppTheme.textMain,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (countBadge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primarySeed
                          : AppTheme.widgetBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      countBadge,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : AppTheme.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildNavGroup({
      required String groupKey,
      required IconData icon,
      required String title,
      required List<
        ({IconData icon, String title, String route, String? countBadge})
      >
      items,
    }) {
      final openGroups = ref.watch(sidebarOpenGroupsProvider);
      final isOpen = openGroups.contains(groupKey);
      final hasActiveChild = items.any(
        (item) =>
            currentPath == item.route ||
            (item.route != '/' &&
                (currentPath?.startsWith(item.route) ?? false)),
      );

      if (collapsed) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          height: 40,
          child: PopupMenuButton<String>(
            tooltip: title,
            offset: const Offset(54, 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: Colors.white,
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
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSubtle,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const PopupMenuDivider(height: 1),
              ...items.map(
                (it) => PopupMenuItem<String>(
                  value: it.route,
                  height: 38,
                  child: Row(
                    children: [
                      Icon(it.icon, size: 18, color: AppTheme.textMuted),
                      const SizedBox(width: 10),
                      Text(
                        it.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            child: Container(
              decoration: BoxDecoration(
                color: hasActiveChild
                    ? AppTheme.navActiveBg
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: hasActiveChild
                    ? Border.all(color: AppTheme.primarySeed.withAlpha(40))
                    : null,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: hasActiveChild
                      ? AppTheme.primarySeed
                      : AppTheme.textMuted,
                ),
              ),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: (hasActiveChild && !isOpen)
                  ? AppTheme.navActiveBg.withAlpha(120)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 19,
                      color: hasActiveChild
                          ? AppTheme.primarySeed
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: hasActiveChild
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: hasActiveChild
                              ? AppTheme.primarySeed
                              : AppTheme.textMain,
                          letterSpacing: 0.1,
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
                      color: AppTheme.textSubtle,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Column(
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
            ),
        ],
      );
    }

    Widget buildRoleProfileCard() {
      if (user == null) return const SizedBox.shrink();

      if (collapsed) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Center(
            child: Tooltip(
              message:
                  '${user.username} (${role == 'QUAN_TRI_VIEN' ? 'Quản trị viên' : (role == 'GIAO_VIEN' ? 'Giáo viên' : 'Học sinh')})',
              preferBelow: false,
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppTheme.primarySeed,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      if (role == 'GIAO_VIEN') {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primarySeed,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primarySeed.withAlpha(35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppTheme.primarySeed,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Giáo viên bộ môn',
                      style: TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      if (role == 'HOC_SINH') {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primarySeed.withAlpha(35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                color: AppTheme.primarySeed,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppTheme.primarySeed,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          FutureBuilder<StudentResultsDto?>(
                            future: ref
                                .read(apiProvider)
                                .getStudentResultsApi()
                                .studentResultsList()
                                .then((response) => response.data)
                                .catchError((_) => null),
                            builder: (context, snapshot) => Text(
                              snapshot.data?.summary.className != null
                                  ? 'Lớp ${snapshot.data!.summary.className} · ${snapshot.data!.summary.termName ?? 'Chưa chốt điểm'}'
                                  : 'Học sinh',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: AppTheme.primaryDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: FutureBuilder<StudentResultsDto?>(
                  future: ref
                      .read(apiProvider)
                      .getStudentResultsApi()
                      .studentResultsList()
                      .then((response) => response.data)
                      .catchError((_) => null),
                  builder: (context, snapshot) {
                    final summary = snapshot.data?.summary;
                    final avgNum = summary?.averageScore != null
                        ? double.tryParse(summary!.averageScore!)
                        : null;
                    final average = avgNum != null
                        ? avgNum.toStringAsFixed(1)
                        : '—';
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text(
                              average,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const Text(
                              'ĐTB',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 8.5,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              summary?.classRank?.toString() ?? '—',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const Text(
                              'Xếp hạng',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 8.5,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              summary?.classSize.toString() ?? '—',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const Text(
                              'Sĩ số',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 8.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }

      return const SizedBox(height: 6);
    }

    Widget buildBottomSemesterWidget() {
      if (collapsed) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Tooltip(
              message: 'Học kỳ I · 2024–2025',
              preferBelow: false,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.widgetBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  size: 18,
                  color: AppTheme.primarySeed,
                ),
              ),
            ),
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.widgetBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role == 'HOC_SINH'
                  ? 'HỌC KỲ HIỆN TẠI'
                  : (role == 'GIAO_VIEN' ? 'HẠN NỘP ĐIỂM' : 'TIẾN ĐỘ HỌC KỲ'),
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppTheme.textSubtle,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Học kỳ I · 2024–2025',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Brand Logo Header & Collapse/Expand Button
        if (collapsed)
          Container(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primarySeed,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primarySeed.withAlpha(50),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'E',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 22),
                  tooltip: 'Mở rộng sidebar',
                  color: AppTheme.primarySeed,
                  onPressed: () {
                    ref
                        .read(sidebarCollapsedProvider.notifier)
                        .update((v) => !v);
                  },
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primarySeed,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primarySeed.withAlpha(50),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'E',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EduScore',
                        style: TextStyle(
                          color: AppTheme.primaryDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'THPT BÀ ĐIỂM',
                        style: TextStyle(
                          color: AppTheme.textSubtle,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!inDrawer)
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    tooltip: 'Thu gọn sidebar',
                    color: AppTheme.textSubtle,
                    onPressed: () {
                      ref
                          .read(sidebarCollapsedProvider.notifier)
                          .update((v) => !v);
                    },
                  ),
              ],
            ),
          ),

        // Role Profile Widget
        buildRoleProfileCard(),

        const SizedBox(height: 4),

        // Scrollable Navigation List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: [
              if (!collapsed)
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 10, 18, 6),
                  child: Text(
                    'ĐIỀU HƯỚNG CHÍNH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: AppTheme.textSubtle,
                    ),
                  ),
                )
              else
                const Divider(indent: 14, endIndent: 14, height: 16),

              buildNavTile(
                icon: Icons.grid_view_outlined,
                title: 'Tổng quan',
                route: '/',
              ),

              buildNavTile(
                icon: Icons.calendar_month_outlined,
                title: role == 'QUAN_TRI_VIEN'
                    ? 'Thời khóa biểu'
                    : (role == 'GIAO_VIEN'
                          ? 'Lịch dạy của tôi'
                          : 'Thời khóa biểu của tôi'),
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
                      countBadge: '08',
                    ),
                    (
                      icon: Icons.rule_outlined,
                      title: 'Chính sách',
                      route: '/classification-policy',
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
                      icon: Icons.manage_accounts_outlined,
                      title: 'Tài khoản',
                      route: '/catalog/accounts',
                      countBadge: null,
                    ),
                  ],
                ),
              ],

              if (role == 'GIAO_VIEN')
                buildNavTile(
                  icon: Icons.table_chart_outlined,
                  title: 'Bảng điểm',
                  route: '/gradebooks',
                ),

              if (role == 'HOC_SINH')
                buildNavTile(
                  icon: Icons.fact_check_outlined,
                  title: 'Điểm của tôi',
                  route: '/my-results',
                ),

              // System Section
              if (!collapsed)
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 14, 18, 6),
                  child: Text(
                    'HỆ THỐNG',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppTheme.textSubtle,
                    ),
                  ),
                )
              else
                const Divider(indent: 14, endIndent: 14, height: 16),

              buildNavTile(
                icon: Icons.wifi_tethering_outlined,
                title: 'Trạng thái kết nối',
                route: '/connection',
              ),
            ],
          ),
        ),

        // Bottom Semester/Deadline Widget
        buildBottomSemesterWidget(),
      ],
    );
  }
}
