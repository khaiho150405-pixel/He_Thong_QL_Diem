import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../app/widgets/role_badge.dart';
import '../../../academic_catalog/fields.dart';
import '../../../reports/repository.dart';
import '../../admin_charts.dart';
import '../../session.dart';

class TeacherOverviewData {
  const TeacherOverviewData({
    required this.totalGradebooks,
    required this.lockedGradebooks,
    required this.classNames,
    required this.pendingOcrCount,
  });

  final int totalGradebooks;
  final int lockedGradebooks;
  final List<String> classNames;
  final int pendingOcrCount;

  int get completionRate => totalGradebooks > 0
      ? (lockedGradebooks * 100 / totalGradebooks).round()
      : 0;
}

final teacherOverviewProvider = FutureProvider.autoDispose<TeacherOverviewData>(
  (ref) async {
    final api = ref.watch(apiProvider);
    final gradebooksRes = await api.getGradebooksApi().gradebooksList();
    final books = gradebooksRes.data?.items ?? [];
    final classNames = books.map((b) => b.className).toSet().toList()..sort();
    final lockedCount =
        books.where((b) => b.status.value == 'DA_CHOT').length;

    int pendingOcr = 0;
    try {
      final ticketFutures = books.map(
        (b) => api
            .getRecognitionApi()
            .recognitionList(gradebookId: b.id)
            .then((r) => r.data ?? <RecognitionTicketDto>[])
            .catchError((_) => <RecognitionTicketDto>[]),
      );
      final ticketLists = await Future.wait(ticketFutures);
      for (final list in ticketLists) {
        pendingOcr += list
            .where((t) => t.status.value == 'CHO_DOI_CHIEU')
            .length;
      }
    } catch (_) {}

    return TeacherOverviewData(
      totalGradebooks: books.length,
      lockedGradebooks: lockedCount,
      classNames: classNames,
      pendingOcrCount: pendingOcr,
    );
  },
);

class HomeDashboardContent extends ConsumerWidget {
  const HomeDashboardContent({
    super.key,
    required this.user,
    required this.role,
    this.isDesktop = false,
  });

  final SessionDto user;
  final String role;
  final bool isDesktop;

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

    return ListView(
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

        // Role-Specific Stat Cards
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
              final rateVal = kpi != null ? '${kpi.completionRate}%' : '—';
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
                    final w = (constraints.maxWidth - (cols - 1) * 10) / cols;
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
          Consumer(
            builder: (context, ref, _) {
              final overviewAsync = ref.watch(teacherOverviewProvider);
              final overview = overviewAsync.asData?.value;
              final isLoading = overviewAsync.isLoading;
              final classCountText = overview != null
                  ? '${overview.classNames.length} lớp'
                  : (isLoading ? '...' : '0 lớp');
              final classSub = overview != null
                  ? (overview.classNames.isEmpty
                        ? 'Chưa có phân công'
                        : overview.classNames.join(', '))
                  : (isLoading ? 'Đang tải danh sách' : 'Chưa có phân công');
              final rateText = overview != null
                  ? '${overview.completionRate}%'
                  : (isLoading ? '...' : '0%');
              final rateSub = overview != null
                  ? '${overview.lockedGradebooks} / ${overview.totalGradebooks} bảng đã chốt'
                  : (isLoading ? 'Đang cập nhật' : 'Chưa có bảng điểm');
              final ocrText = overview != null
                  ? '${overview.pendingOcrCount.toString().padLeft(2, '0')} phiếu'
                  : (isLoading ? '...' : '00 phiếu');
              final ocrSub = overview != null && overview.pendingOcrCount > 0
                  ? 'Cần xác nhận kết quả'
                  : 'Đã duyệt toàn bộ';

              return LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  final cards = [
                    _buildStatCard(
                      context: context,
                      label: 'Phụ trách',
                      value: classCountText,
                      subtitle: classSub,
                      icon: Icons.assignment_outlined,
                    ),
                    _buildStatCard(
                      context: context,
                      label: 'Tiến độ nhập',
                      value: rateText,
                      subtitle: rateSub,
                      accentColor: const Color(0xFF276E68),
                      icon: Icons.check_circle_outline,
                    ),
                    _buildStatCard(
                      context: context,
                      label: 'OCR chờ duyệt',
                      value: ocrText,
                      subtitle: ocrSub,
                      accentColor: AppTheme.goldAccent,
                      icon: Icons.document_scanner_outlined,
                    ),
                  ];

                  if (wide) {
                    return Row(
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          Expanded(child: cards[i]),
                          if (i < cards.length - 1) const SizedBox(width: 10),
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
                          SizedBox(width: 150, child: cards[index]),
                    ),
                  );
                },
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
              return _buildStudentStatistics(context, snapshot.data!.summary);
            },
          ),

        // Admin Statistical Charts (Shown on both Web and Mobile)
        if (role == 'QUAN_TRI_VIEN') ...[
          const SizedBox(height: 20),
          const AdminChartsSection(),
        ],

        // Native app mobile catalog fallback (hidden on responsive Web and desktop)
        if (!isDesktop && !kIsWeb && role == 'QUAN_TRI_VIEN') ...[
          const SizedBox(height: 16),
          for (final r in resources)
            Card(
              child: ListTile(
                title: Text(r.label),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go('/catalog/${r.key}'),
              ),
            ),
        ],
      ],
    );
  }
}
