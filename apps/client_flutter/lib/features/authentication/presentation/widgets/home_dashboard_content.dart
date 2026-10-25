import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/design_tokens.dart';
import '../../../../app/widgets/empty_state.dart';
import '../../../../app/widgets/role_badge.dart';
import '../../../../app/widgets/stat_card.dart';
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
    final lockedCount = books.where((b) => b.status.value == 'DA_CHOT').length;

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
  });

  final SessionDto user;
  final String role;

  Widget _buildStudentStatistics(
    BuildContext context,
    StudentResultSummaryDto summary,
  ) {
    final average = summary.averageScore == null
        ? '—'
        : double.tryParse(summary.averageScore ?? '')?.toStringAsFixed(1) ?? '—';
    final rank = summary.classRank == null ? '—' : '${summary.classRank}';
    return StatCardGrid(
      children: [
        StatCard(
          title: 'ĐTB học kỳ',
          value: average,
          subtitle: summary.termName ?? 'Chưa có học kỳ đã chốt',
          icon: Icons.star_rounded,
        ),
        StatCard(
          title: 'Môn đã chốt',
          value: '${summary.publishedSubjects} / ${summary.totalSubjects}',
          subtitle: 'Chỉ tính bảng điểm đã chốt',
          icon: Icons.menu_book_outlined,
        ),
        StatCard(
          title: 'Xếp hạng lớp',
          value: '$rank / ${summary.classSize}',
          subtitle: 'Lớp ${summary.className}',
          icon: Icons.emoji_events_outlined,
          tone: StatTone.ok,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      children: [
        // Tiêu đề trang (pagehead): vai trò, lời chào, mô tả.
        DecoratedBox(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: t.line),
            boxShadow: t.shadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: t.priLink,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Xin chào, ${user.username}',
                              style: TextStyle(
                                fontSize: isDesktop ? 24 : 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: t.heading,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    RoleBadge(role: role),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  roleDesc,
                  style: TextStyle(fontSize: 13, color: t.ink2, height: 1.4),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Các ô chỉ số theo vai trò.
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
                  // Dưới 720: nhãn rút gọn như bản cũ.
                  final wide = constraints.maxWidth >= 720;
                  return StatCardGrid(
                    children: [
                      StatCard(
                        title: 'Bảng điểm',
                        value: bookVal,
                        subtitle: bookSub,
                        icon: Icons.table_chart_outlined,
                      ),
                      StatCard(
                        title: wide ? 'Tỷ lệ hoàn thành' : 'Tỷ lệ',
                        value: rateVal,
                        subtitle: wide ? 'Đã chốt sổ điểm' : 'Đã chốt sổ',
                        icon: Icons.trending_up_rounded,
                        tone: StatTone.ok,
                      ),
                      StatCard(
                        title: wide ? 'Đối chiếu OCR' : 'OCR',
                        value: ocrVal,
                        subtitle: wide ? 'Bảng chờ GV duyệt' : 'Chờ GV duyệt',
                        icon: Icons.document_scanner_outlined,
                        tone: StatTone.warn,
                      ),
                      StatCard(
                        title: 'Học sinh',
                        value: stuVal,
                        subtitle: stuSub,
                        icon: Icons.school_outlined,
                      ),
                    ],
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

              return StatCardGrid(
                children: [
                  StatCard(
                    title: 'Phụ trách',
                    value: classCountText,
                    subtitle: classSub,
                    icon: Icons.assignment_outlined,
                  ),
                  StatCard(
                    title: 'Tiến độ nhập',
                    value: rateText,
                    subtitle: rateSub,
                    icon: Icons.check_circle_outline,
                    tone: StatTone.ok,
                  ),
                  StatCard(
                    title: 'OCR chờ duyệt',
                    value: ocrText,
                    subtitle: ocrSub,
                    icon: Icons.document_scanner_outlined,
                    tone: StatTone.warn,
                  ),
                ],
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
                  style: TextStyle(color: t.bad),
                );
              }
              final summary = snapshot.data?.summary;
              if (summary == null) {
                return const EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'Chưa có kết quả',
                  message: 'Năm học này chưa có kết quả được công bố',
                );
              }
              return _buildStudentStatistics(context, summary);
            },
          ),

        // Biểu đồ thống kê của quản trị (web và mobile).
        if (role == 'QUAN_TRI_VIEN') ...[
          const SizedBox(height: AppSpacing.xl),
          const AdminChartsSection(),
        ],
      ],
    );
  }
}
