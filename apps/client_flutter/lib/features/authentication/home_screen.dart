import '../../app/widgets/app_edge_scrollbar.dart';
import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../app/widgets/role_badge.dart';
import '../academic_catalog/fields.dart';
import '../reports/repository.dart';
import 'admin_charts.dart';
import 'profile_dialog.dart';
import 'session.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> changePassword(BuildContext context, WidgetRef ref) async {
    final current = TextEditingController(), next = TextEditingController();
    String? error;
    bool busy = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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

  String _subtitleForResource(String key) {
    switch (key) {
      case 'years':
        return 'Thiết lập niên khóa và năm hiện hành';
      case 'semesters':
        return 'Học kỳ I, học kỳ II và thứ tự';
      case 'classes':
        return 'Danh sách lớp và giáo viên chủ nhiệm';
      case 'students':
        return 'Hồ sơ học sinh và thông tin lớp';
      case 'subjects':
        return 'Môn học và số tiết mỗi tuần';
      case 'components':
        return 'Thành phần điểm, hệ số và thứ tự';
      case 'teachers':
        return 'Hồ sơ giáo viên và tổ chuyên môn';
      case 'assignments':
        return 'Phân công dạy lớp - môn - học kỳ';
      case 'accounts':
        return 'Tài khoản người dùng và vai trò';
      default:
        return 'Xem và quản lý danh mục';
    }
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required String value,
    required String subtitle,
    Color? accentColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppTheme.textSubtle,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(
                  icon,
                  size: 14,
                  color: accentColor ?? AppTheme.primarySeed,
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'serif',
              letterSpacing: -0.4,
              color: accentColor ?? AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentStatistics(
    BuildContext context,
    StudentResultSummaryDto summary,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final width = wide ? (constraints.maxWidth - 20) / 3 : 150.0;
        final average = summary.averageScore == null
            ? '—'
            : double.parse(summary.averageScore!).toStringAsFixed(1);
        final rank = summary.classRank == null ? '—' : '${summary.classRank}';
        final cards = [
          _buildStatCard(
            context: context,
            label: 'ĐTB học kỳ',
            value: average,
            subtitle: summary.termName ?? 'Chưa có học kỳ đã chốt',
            accentColor: AppTheme.goldAccent,
            icon: Icons.star_rounded,
          ),
          _buildStatCard(
            context: context,
            label: 'Môn đã chốt',
            value: '${summary.publishedSubjects} / ${summary.totalSubjects}',
            subtitle: 'Chỉ tính bảng điểm đã chốt',
            icon: Icons.menu_book_outlined,
          ),
          _buildStatCard(
            context: context,
            label: 'Xếp hạng lớp',
            value: '$rank / ${summary.classSize}',
            subtitle: 'Lớp ${summary.className}',
            accentColor: const Color(0xFF276E68),
            icon: Icons.emoji_events_outlined,
          ),
        ];
        if (wide) {
          return Row(
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                Expanded(child: cards[index]),
                if (index < cards.length - 1) const SizedBox(width: 10),
              ],
            ],
          );
        }
        return SizedBox(
          height: 105,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) =>
                SizedBox(width: width, child: cards[index]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    if (user == null) return const SizedBox.shrink();

    final role = user.role.value;

    final visible = role == 'QUAN_TRI_VIEN' ? resources : <ResourceSpec>[];

    String roleEyebrow;
    String roleDesc;
    if (role == 'QUAN_TRI_VIEN') {
      roleEyebrow =
          'HỌC KỲ I, 2024–2025 · THPT BÀ ĐIỂM · BẢNG ĐIỀU HÀNH THỐNG KÊ';
      roleDesc =
          'Giám sát số liệu thống kê toàn trường, phân tích phổ điểm, quản lý danh mục và chính sách xếp loại.';
    } else if (role == 'GIAO_VIEN') {
      roleEyebrow = 'HỌC KỲ I, 2024–2025 · THPT BÀ ĐIỂM · BỘ MÔN GIẢNG DẠY';
      roleDesc =
          'Quản lý bảng điểm lớp phân công, upload ảnh nhận diện 2 kênh (Số/Chữ), so sánh đối chiếu ô cắt và duyệt điểm chính thức.';
    } else {
      roleEyebrow = 'HỌC KỲ I, 2024–2025 · THPT BÀ ĐIỂM · SỔ LIÊN LẠC ĐIỆN TỬ';
      roleDesc =
          'Tra cứu điểm thành phần, điểm tổng kết và xếp loại học lực của chính mình.';
    }

    return Scaffold(
      backgroundColor: AppTheme.warmIvoryBg,
      appBar: AppBar(
        title: const Text('EduScore · THPT Bà Điểm'),
        actions: [
          if (role != 'QUAN_TRI_VIEN')
            IconButton(
              tooltip: 'Hồ sơ cá nhân',
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const ProfileDialog(),
              ),
              icon: const Icon(Icons.person_outline),
            ),
          if (role != 'HOC_SINH')
            IconButton(
              tooltip: 'Đổi mật khẩu',
              onPressed: () => changePassword(context, ref),
              icon: const Icon(Icons.password),
            ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () async {
              try {
                await ref.read(sessionProvider.notifier).logout();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(errorMessage(e))));
                }
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AppEdgeScrollbar(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1140),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Hero Banner matching UI/src/App.tsx PageHeader
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  roleEyebrow,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: AppTheme.goldAccent,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Xin chào, ${user.username}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'serif',
                                    letterSpacing: -0.5,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RoleBadge(role: role),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roleDesc,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── ROLE-SPECIFIC STAT CARDS ──────────────────────────────────
                if (role == 'QUAN_TRI_VIEN')
                  Builder(
                    builder: (context) {
                      final overview = ref.watch(adminOverviewProvider);
                      final kpi = overview.asData?.value.kpi;
                      final unavailableSubtitle = overview.isLoading
                          ? 'Đang tải dữ liệu'
                          : 'Chưa tải được dữ liệu';
                      final bookVal = kpi != null
                          ? '${kpi.lockedGradebooks} / ${kpi.totalGradebooks}'
                          : '—';
                      final bookSub = kpi != null
                          ? '${kpi.totalClasses} lớp · 3 khối'
                          : unavailableSubtitle;
                      final rateVal = kpi != null
                          ? '${kpi.completionRate}%'
                          : '—';
                      final ocrVal = kpi != null
                          ? kpi.pendingOcrTickets.toString().padLeft(2, '0')
                          : '—';
                      final stuVal = kpi != null ? '${kpi.totalStudents}' : '—';
                      final stuSub = kpi != null && kpi.totalClasses > 0
                          ? '${(kpi.totalStudents / kpi.totalClasses).round()} HS / lớp'
                          : unavailableSubtitle;

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 720) {
                            const cols = 4;
                            final w =
                                (constraints.maxWidth - (cols - 1) * 10) / cols;
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                SizedBox(
                                  width: w,
                                  height: 96,
                                  child: _buildStatCard(
                                    context: context,
                                    label: 'Bảng điểm',
                                    value: bookVal,
                                    subtitle: bookSub,
                                    icon: Icons.table_chart_outlined,
                                  ),
                                ),
                                SizedBox(
                                  width: w,
                                  height: 96,
                                  child: _buildStatCard(
                                    context: context,
                                    label: 'Tỷ lệ hoàn thành',
                                    value: rateVal,
                                    subtitle: 'Đã chốt sổ điểm',
                                    accentColor: const Color(0xFF276E68),
                                    icon: Icons.trending_up_rounded,
                                  ),
                                ),
                                SizedBox(
                                  width: w,
                                  height: 96,
                                  child: _buildStatCard(
                                    context: context,
                                    label: 'Đối chiếu OCR',
                                    value: ocrVal,
                                    subtitle: 'Bảng chờ GV duyệt',
                                    accentColor: AppTheme.goldAccent,
                                    icon: Icons.document_scanner_outlined,
                                  ),
                                ),
                                SizedBox(
                                  width: w,
                                  height: 96,
                                  child: _buildStatCard(
                                    context: context,
                                    label: 'Học sinh',
                                    value: stuVal,
                                    subtitle: stuSub,
                                    icon: Icons.school_outlined,
                                  ),
                                ),
                              ],
                            );
                          }
                          return SizedBox(
                            height: 105,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: _buildStatCard(
                                    context: context,
                                    label: 'Bảng điểm',
                                    value: bookVal,
                                    subtitle: bookSub,
                                    icon: Icons.table_chart_outlined,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 140,
                                  child: _buildStatCard(
                                    context: context,
                                    label: 'Tỷ lệ',
                                    value: rateVal,
                                    subtitle: 'Đã chốt sổ',
                                    accentColor: const Color(0xFF276E68),
                                    icon: Icons.trending_up_rounded,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 140,
                                  child: _buildStatCard(
                                    context: context,
                                    label: 'OCR',
                                    value: ocrVal,
                                    subtitle: 'Chờ GV duyệt',
                                    accentColor: AppTheme.goldAccent,
                                    icon: Icons.document_scanner_outlined,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 140,
                                  child: _buildStatCard(
                                    context: context,
                                    label: 'Học sinh',
                                    value: stuVal,
                                    subtitle: stuSub,
                                    icon: Icons.school_outlined,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                if (role == 'GIAO_VIEN')
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 720) {
                        const cols = 3;
                        final w =
                            (constraints.maxWidth - (cols - 1) * 10) / cols;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: w,
                              child: _buildStatCard(
                                context: context,
                                label: 'Phụ trách',
                                value: '4 lớp',
                                subtitle: '10A1, 10A2, 11A1, 12A1',
                                icon: Icons.assignment_outlined,
                              ),
                            ),
                            SizedBox(
                              width: w,
                              child: _buildStatCard(
                                context: context,
                                label: 'Tiến độ nhập',
                                value: '85%',
                                subtitle: 'Hạn chốt 30/11/2024',
                                accentColor: const Color(0xFF276E68),
                                icon: Icons.check_circle_outline,
                              ),
                            ),
                            SizedBox(
                              width: w,
                              child: _buildStatCard(
                                context: context,
                                label: 'OCR chờ duyệt',
                                value: '02 phiếu',
                                subtitle: 'Cần xác nhận kết quả',
                                accentColor: AppTheme.goldAccent,
                                icon: Icons.document_scanner_outlined,
                              ),
                            ),
                          ],
                        );
                      }
                      return SizedBox(
                        height: 105,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            SizedBox(
                              width: 150,
                              child: _buildStatCard(
                                context: context,
                                label: 'Phụ trách',
                                value: '4 lớp',
                                subtitle: 'Bộ môn',
                                icon: Icons.assignment_outlined,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 150,
                              child: _buildStatCard(
                                context: context,
                                label: 'Tiến độ nhập',
                                value: '85%',
                                subtitle: 'Hạn 30/11/2024',
                                accentColor: const Color(0xFF276E68),
                                icon: Icons.check_circle_outline,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 150,
                              child: _buildStatCard(
                                context: context,
                                label: 'OCR chờ duyệt',
                                value: '02 phiếu',
                                subtitle: 'Cần xác nhận',
                                accentColor: AppTheme.goldAccent,
                                icon: Icons.document_scanner_outlined,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                if (role == 'HOC_SINH')
                  FutureBuilder<StudentResultsDto>(
                    future: ref
                        .read(apiProvider)
                        .getStudentResultsApi()
                        .studentResultsList()
                        .then((response) => response.data!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const LinearProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text(
                          'Không tải được thống kê: ${errorMessage(snapshot.error!)}',
                        );
                      }
                      return _buildStudentStatistics(
                        context,
                        snapshot.data!.summary,
                      );
                    },
                  ),

                const SizedBox(height: 14),

                // Priority Functional Actions Section
                Text(
                  role == 'HOC_SINH'
                      ? 'SỔ ĐIỂM CÁ NHÂN'
                      : 'NGHIỆP VỤ BẢNG ĐIỂM',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppTheme.textSubtle,
                  ),
                ),
                const SizedBox(height: 6),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 720;
                    final cardWidth = isWide
                        ? (constraints.maxWidth - 10) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (role == 'GIAO_VIEN') ...[
                          SizedBox(
                            width: cardWidth,
                            child: Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => context.go('/gradebooks'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: AppTheme.navActiveBg,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.table_chart_rounded,
                                          size: 20,
                                          color: AppTheme.primarySeed,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Bảng điểm',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primaryDark,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Quản lý bảng điểm các lớp phụ trách, nhập điểm tay',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 13,
                                        color: Color(0xFF9A9590),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            width: cardWidth,
                            child: Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => context.go('/timetable'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: AppTheme.navActiveBg,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.schedule_rounded,
                                          size: 20,
                                          color: AppTheme.primarySeed,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Lịch dạy của tôi',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primaryDark,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Xem lịch các tiết giảng dạy trong tuần theo lớp, phòng học',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 13,
                                        color: Color(0xFF9A9590),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else if (role == 'QUAN_TRI_VIEN') ...[
                          SizedBox(
                            width: cardWidth,
                            child: Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => context.go('/gradebooks'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: AppTheme.navActiveBg,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.table_chart_rounded,
                                          size: 20,
                                          color: AppTheme.primarySeed,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Bảng điểm toàn trường',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primaryDark,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Theo dõi toàn bộ bảng điểm trong trường',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 13,
                                        color: Color(0xFF9A9590),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () =>
                                    context.go('/classification-policy'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: AppTheme.navActiveBg,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.rule_rounded,
                                          size: 20,
                                          color: AppTheme.primarySeed,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Chính sách xếp loại',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primaryDark,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Cấu hình ngưỡng điểm Giỏi, Khá, TB, Yếu',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 13,
                                        color: Color(0xFF9A9590),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => context.go('/timetable'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: AppTheme.navActiveBg,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.calendar_month_rounded,
                                          size: 20,
                                          color: AppTheme.primarySeed,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Thời khóa biểu toàn trường',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primaryDark,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Tra cứu lịch học các lớp và tiết dạy giáo viên toàn trường',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 13,
                                        color: Color(0xFF9A9590),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: cardWidth,
                            child: Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => context.go('/my-results'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: AppTheme.navActiveBg,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.fact_check_rounded,
                                          size: 20,
                                          color: AppTheme.primarySeed,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Điểm của tôi',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primaryDark,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Xem điểm thành phần, tổng kết và xếp loại',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 13,
                                        color: Color(0xFF9A9590),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => context.go('/timetable'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: AppTheme.navActiveBg,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 20,
                                          color: AppTheme.primarySeed,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Thời khóa biểu của tôi',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primaryDark,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Xem lịch học các môn trong tuần của lớp mình',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 13,
                                        color: Color(0xFF9A9590),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                if (role == 'QUAN_TRI_VIEN') ...[
                  // Academic Catalog Section
                  Text(
                    role == 'HOC_SINH'
                        ? 'DANH MỤC TRA CỨU'
                        : 'HỒ SƠ & DANH MỤC HỌC VỤ',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppTheme.textSubtle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role == 'HOC_SINH'
                        ? 'Danh mục thông tin phục vụ tra cứu học tập'
                        : 'Quản lý hồ sơ học sinh, giáo viên, lớp học và phân công giảng dạy',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      int columns = 1;
                      if (constraints.maxWidth >= 900) {
                        columns = 3;
                      } else if (constraints.maxWidth >= 600) {
                        columns = 2;
                      }
                      final spacing = 10.0;
                      final width =
                          (constraints.maxWidth - (columns - 1) * spacing) /
                          columns;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final r in visible)
                            SizedBox(
                              width: width,
                              child: Card(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => context.go('/catalog/${r.key}'),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.widgetBg,
                                            borderRadius: BorderRadius.circular(
                                              9,
                                            ),
                                          ),
                                          child: Icon(
                                            _iconForResource(r.key),
                                            size: 19,
                                            color: AppTheme.primarySeed,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                r.label,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.primaryDark,
                                                ),
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                _subtitleForResource(r.key),
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  color: AppTheme.textMuted,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          size: 18,
                                          color: Color(0xFFB7B0A2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  // Admin Statistical Charts
                  if (role == 'QUAN_TRI_VIEN') ...[
                    const SizedBox(height: 20),
                    const AdminChartsSection(),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
