import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/academic_catalog/fields.dart';
import '../../features/authentication/profile_dialog.dart';
import '../../features/authentication/session.dart';
import '../theme.dart';
import 'app_edge_scrollbar.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.currentPath,
    this.showBackButton = false,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final String? currentPath;
  final bool showBackButton;

  IconData _iconForResource(String key) {
    switch (key) {
      case 'years':
        return Icons.calendar_month_outlined;
      case 'semesters':
        return Icons.date_range_outlined;
      case 'classes':
        return Icons.meeting_room_outlined;
      case 'students':
        return Icons.people_alt_outlined;
      case 'subjects':
        return Icons.menu_book_outlined;
      case 'components':
        return Icons.percent_outlined;
      case 'teachers':
        return Icons.badge_outlined;
      case 'assignments':
        return Icons.assignment_ind_outlined;
      case 'accounts':
        return Icons.manage_accounts_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final current = TextEditingController(), next = TextEditingController();
    String? error;
    bool busy = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới',
                  helperText:
                      'Ít nhất 12 ký tự. Cần đăng nhập lại sau khi đổi.',
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (next.text.length < 12) {
                        setState(
                          () => error = 'Mật khẩu mới cần ít nhất 12 ký tự.',
                        );
                        return;
                      }
                      setState(() => busy = true);
                      try {
                        await ref
                            .read(apiProvider)
                            .getIdentityApi()
                            .identityPassword(
                              passwordInput: PasswordInput(
                                currentPassword: current.text,
                                newPassword: next.text,
                              ),
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                        ref.read(sessionProvider.notifier).clear();
                      } catch (e) {
                        if (ctx.mounted) {
                          setState(() {
                            error = errorMessage(e);
                            busy = false;
                          });
                        }
                      }
                    },
              child: const Text('Đổi mật khẩu'),
            ),
          ],
        ),
      ),
    );
    current.dispose();
    next.dispose();
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(sessionProvider.notifier).logout();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage(e))));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 960;

    if (user == null) {
      return Scaffold(body: body);
    }

    final role = user.role.value;
    final visibleResources = resources
        .where(
          (r) =>
              role == 'QUAN_TRI_VIEN' ||
              (role == 'GIAO_VIEN' && r.key != 'accounts') ||
              (role == 'HOC_SINH' && r.key == 'students'),
        )
        .toList();

    // Reusable Nav Item
    Widget buildNavTile({
      required IconData icon,
      required String title,
      required String route,
      String? countBadge,
      String? tagBadge,
      bool selected = false,
      VoidCallback? onTap,
    }) {
      final isSelected =
          selected || (currentPath != null && currentPath == route);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1.5),
        child: Material(
          color: isSelected ? AppTheme.navActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap:
                onTap ??
                () {
                  if (!isDesktop) Navigator.of(context).maybePop();
                  context.go(route);
                },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9.5,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? const Border(
                        left: BorderSide(
                          color: AppTheme.primarySeed,
                          width: 3.5,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? const Color(0xFF17706C)
                        : const Color(0xFF74817D),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? AppTheme.primarySeed
                            : const Color(0xFF606966),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (countBadge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBE6DC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        countBadge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF746F64),
                        ),
                      ),
                    ),
                  if (tagBadge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8C96D),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tagBadge,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5B4A18),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Role-specific profile card
    Widget buildRoleProfileCard() {
      final initial = user.username.isNotEmpty
          ? user.username[0].toUpperCase()
          : 'U';

      if (role == 'GIAO_VIEN') {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primarySeed,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primarySeed.withAlpha(40),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withAlpha(50),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 4,
                children: ['10A1', '10A2', '11A1']
                    .map(
                      (c) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          c,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      }

      if (role == 'HOC_SINH') {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                      backgroundColor: AppTheme.goldBright,
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
                          FutureBuilder<StudentResultsDto>(
                            future: ref
                                .read(apiProvider)
                                .getStudentResultsApi()
                                .studentResultsList()
                                .then((response) => response.data!),
                            builder: (context, snapshot) => Text(
                              snapshot.hasData
                                  ? 'Lớp ${snapshot.data!.summary.className} · ${snapshot.data!.summary.termName ?? 'Chưa chốt điểm'}'
                                  : 'Đang tải thông tin lớp…',
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
                color: const Color(0xFF1B4A4E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: FutureBuilder<StudentResultsDto>(
                  future: ref
                      .read(apiProvider)
                      .getStudentResultsApi()
                      .studentResultsList()
                      .then((response) => response.data!),
                  builder: (context, snapshot) {
                    final summary = snapshot.data?.summary;
                    final average = summary?.averageScore == null
                        ? '—'
                        : double.parse(
                            summary!.averageScore!,
                          ).toStringAsFixed(1);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text(
                              average,
                              style: const TextStyle(
                                color: AppTheme.goldBright,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            Text(
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
                            Text(
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
                            Text(
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

      // Admin simple info
      return const SizedBox(height: 6);
    }

    // Role-specific bottom widget
    Widget buildBottomSemesterWidget() {
      if (role == 'GIAO_VIEN') {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.widgetBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDDD8CE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HẠN NỘP ĐIỂM',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF6B6860),
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                '30 / 11 / 2024',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF23484A),
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.68,
                  minHeight: 5,
                  backgroundColor: Color(0xFFD7D4CC),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.goldAccent,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.widgetBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDD8CE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role == 'HOC_SINH' ? 'HỌC KỲ HIỆN TẠI' : 'TIẾN ĐỘ HỌC KỲ',
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF6B6860),
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Học kỳ I, 2024–2025',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF23484A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              role == 'HOC_SINH'
                  ? 'Đã hoàn thành 68% học kỳ'
                  : 'Còn 18 ngày hoàn tất điểm số',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF77776F)),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.68,
                minHeight: 5,
                backgroundColor: Color(0xFFD7D4CC),
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldAccent),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildSidebarContent({required bool inDrawer}) {
      return Column(
        children: [
          // Brand Logo Header matching UI/src/App.tsx
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primarySeed,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primarySeed.withAlpha(50),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'E',
                      style: TextStyle(
                        color: Color(0xFFF2D775),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EduScore',
                        style: TextStyle(
                          color: AppTheme.primaryDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          fontFamily: 'serif',
                        ),
                      ),
                      Text(
                        'THPT BÀ ĐIỂM',
                        style: TextStyle(
                          color: Color(0xFF8B8578),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Role Profile Widget
          buildRoleProfileCard(),

          // Section Title
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                role == 'QUAN_TRI_VIEN' ? 'ĐIỀU HÀNH' : 'MENU',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: Color(0xFF9B9588),
                ),
              ),
            ),
          ),

          // Navigation List
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                buildNavTile(
                  icon: Icons.grid_view_rounded,
                  title: 'Tổng quan',
                  route: '/',
                ),

                if (role != 'HOC_SINH')
                  buildNavTile(
                    icon: Icons.table_chart_outlined,
                    title: role == 'GIAO_VIEN'
                        ? 'Bảng điểm của tôi'
                        : 'Quản lý bảng điểm',
                    route: '/gradebooks',
                    countBadge: role == 'QUAN_TRI_VIEN' ? '08' : null,
                  ),

                if (role == 'HOC_SINH')
                  buildNavTile(
                    icon: Icons.fact_check_outlined,
                    title: 'Điểm của tôi',
                    route: '/my-results',
                  ),

                if (role == 'QUAN_TRI_VIEN')
                  buildNavTile(
                    icon: Icons.rule_outlined,
                    title: 'Chính sách xếp loại',
                    route: '/classification-policy',
                  ),

                // Catalog Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                  child: Text(
                    role == 'HOC_SINH' ? 'TRA CỨU' : 'DANH MỤC HỌC VỤ',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Color(0xFF9B9588),
                    ),
                  ),
                ),

                for (final r in visibleResources)
                  buildNavTile(
                    icon: _iconForResource(r.key),
                    title: r.label,
                    route: '/catalog/${r.key}',
                  ),

                // System Section
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 14, 18, 6),
                  child: Text(
                    'HỆ THỐNG',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Color(0xFF9B9588),
                    ),
                  ),
                ),

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

          // Bottom Account Actions
          const Divider(indent: 12, endIndent: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              children: [
                if (role != 'QUAN_TRI_VIEN')
                  buildNavTile(
                    icon: Icons.badge_outlined,
                    title: 'Hồ sơ cá nhân',
                    route: '#',
                    onTap: () {
                      if (!isDesktop) Navigator.of(context).maybePop();
                      showDialog<void>(
                        context: context,
                        builder: (_) => const ProfileDialog(),
                      );
                    },
                  ),
                buildNavTile(
                  icon: Icons.lock_reset_outlined,
                  title: 'Đổi mật khẩu',
                  route: '#',
                  onTap: () {
                    if (!isDesktop) Navigator.of(context).maybePop();
                    _changePassword(context, ref);
                  },
                ),
                buildNavTile(
                  icon: Icons.logout_rounded,
                  title: 'Đăng xuất',
                  route: '#',
                  onTap: () {
                    if (!isDesktop) Navigator.of(context).maybePop();
                    _logout(context, ref);
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Sidebar with exact width matching UI/src/App.tsx
            SizedBox(
              width: role == 'QUAN_TRI_VIEN'
                  ? 258
                  : (role == 'GIAO_VIEN' ? 242 : 236),
              child: Material(
                color: AppTheme.sidebarBg,
                elevation: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: AppTheme.borderSidebar,
                        width: 1,
                      ),
                    ),
                  ),
                  child: buildSidebarContent(inDrawer: false),
                ),
              ),
            ),

            // Main Content Screen
            Expanded(
              child: Scaffold(
                backgroundColor: AppTheme.warmIvoryBg,
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(64),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.sidebarBg,
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.borderSidebar,
                          width: 1,
                        ),
                      ),
                    ),
                    child: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: showBackButton
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else {
                                  context.go('/');
                                }
                              },
                            )
                          : null,
                      title: Text(title),
                      actions: [
                        ...?actions,
                        IconButton(
                          tooltip: 'Đăng xuất',
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          onPressed: () => _logout(context, ref),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                body: AppEdgeScrollbar(child: body),
                floatingActionButton: floatingActionButton,
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Tablet layout
    return Scaffold(
      backgroundColor: AppTheme.warmIvoryBg,
      appBar: AppBar(
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    context.go('/');
                  }
                },
              )
            : null,
        title: Text(title),
        actions: [
          ...?actions,
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _logout(context, ref),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(child: buildSidebarContent(inDrawer: true)),
      ),
      body: AppEdgeScrollbar(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
