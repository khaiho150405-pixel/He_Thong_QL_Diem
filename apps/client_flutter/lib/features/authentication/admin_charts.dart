import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../reports/repository.dart';

const double kAdminChartCardHeight = 310.0;

class AdminChartsSection extends ConsumerWidget {
  const AdminChartsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(adminOverviewProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.insights_rounded,
                  size: 16,
                  color: AppTheme.primarySeed,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'BIỂU ĐỒ SỐ LIỆU THỐNG KÊ TOÀN TRƯỜNG',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppTheme.textSubtle,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5EDE5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF256848).withAlpha(60),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF256848),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Trực tiếp (10s)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF256848),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  tooltip: 'Làm mới dữ liệu ngay',
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      ref.read(adminOverviewProvider.notifier).refresh(),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Số liệu thực tế từ cơ sở dữ liệu hệ thống: phổ điểm, độ chính xác AI hai kênh và tiến độ nộp điểm',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),

            overviewAsync.when(
              loading: () => const _AdminChartsLoadingSkeleton(),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.widgetBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Không thể tải thống kê thời gian thực: $err',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Thử lại'),
                      onPressed: () =>
                          ref.read(adminOverviewProvider.notifier).refresh(),
                    ),
                  ],
                ),
              ),
              data: (data) {
                if (isWide) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: kAdminChartCardHeight,
                              child: _GradeDistributionCard(
                                items: data.gradeDistribution,
                                totalStudents: data.kpi.totalStudents,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: kAdminChartCardHeight,
                              child: _OcrAccuracyCard(data: data.ocrAccuracy),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: kAdminChartCardHeight,
                              child: _GradeLevelProgressCard(
                                items: data.gradeLevelProgress,
                                lockedBooks: data.kpi.lockedGradebooks,
                                totalBooks: data.kpi.totalGradebooks,
                                completionRate: data.kpi.completionRate,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: kAdminChartCardHeight,
                              child: _RecentGradebookActivityCard(
                                activities: data.recentActivities,
                                totalTeachers: data.kpi.totalTeachers,
                                totalClasses: data.kpi.totalClasses,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      SizedBox(
                        height: kAdminChartCardHeight,
                        child: _GradeDistributionCard(
                          items: data.gradeDistribution,
                          totalStudents: data.kpi.totalStudents,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: kAdminChartCardHeight,
                        child: _OcrAccuracyCard(data: data.ocrAccuracy),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: kAdminChartCardHeight,
                        child: _GradeLevelProgressCard(
                          items: data.gradeLevelProgress,
                          lockedBooks: data.kpi.lockedGradebooks,
                          totalBooks: data.kpi.totalGradebooks,
                          completionRate: data.kpi.completionRate,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: kAdminChartCardHeight,
                        child: _RecentGradebookActivityCard(
                          activities: data.recentActivities,
                          totalTeachers: data.kpi.totalTeachers,
                          totalClasses: data.kpi.totalClasses,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// ── Shared Standard Card Header & Footer ──────────────────────────────────────
Widget _buildChartHeader({
  required String eyebrow,
  required String title,
  required String badge,
  Color? badgeBg,
  Color? badgeColor,
}) {
  return SizedBox(
    height: 38,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppTheme.textSubtle,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'serif',
                  color: AppTheme.primaryDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: badgeBg ?? AppTheme.widgetBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badgeColor ?? AppTheme.textSubtle,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildChartFooter({
  required IconData icon,
  required String text,
  Color? bg,
  Color? iconColor,
  Color? textColor,
}) {
  return Container(
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: bg ?? const Color(0xFFE8F2EC),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(icon, size: 14, color: iconColor ?? const Color(0xFF276E68)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: textColor ?? const Color(0xFF1E544F),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

// ── Chart 1: Grade Distribution ──────────────────────────────────────────────
class _GradeDistributionCard extends StatelessWidget {
  const _GradeDistributionCard({
    required this.items,
    required this.totalStudents,
  });

  final List<AdminGradeDistributionItem> items;
  final int totalStudents;

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF276E68);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRated = items.fold<int>(0, (sum, item) => sum + item.count);
    final goodCount = items
        .where((i) => i.code == 'GIOI' || i.code == 'KHA')
        .fold<int>(0, (sum, i) => sum + i.count);
    final passRate = totalRated > 0
        ? ((goodCount / totalRated) * 100).toStringAsFixed(1)
        : '100.0';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChartHeader(
              eyebrow: 'PHÂN BỐ HỌC LỰC',
              title: 'Mức điểm toàn trường',
              badge: 'DB Thực tế',
            ),
            const SizedBox(height: 8),

            // Bar Chart Visualization with Expanded
            Expanded(
              child: Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: items.map((item) {
                    final color = _parseColor(item.color);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${item.percentage}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: (item.percentage * 1.6).clamp(14.0, 78.0),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.label,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${item.count} HS',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppTheme.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),

            _buildChartFooter(
              icon: Icons.check_circle_rounded,
              text:
                  'Đã tổng kết $totalRated / $totalStudents HS · Tỷ lệ Giỏi & Khá: $passRate%',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chart 2: OCR 2-Channel Accuracy Spectrum ─────────────────────────────────
class _OcrAccuracyCard extends StatelessWidget {
  const _OcrAccuracyCard({required this.data});

  final AdminOcrAccuracyData data;

  @override
  Widget build(BuildContext context) {
    final hasCells = data.totalCells > 0;
    final greenFlex = hasCells
        ? ((data.greenCount / data.totalCells) * 100).round().clamp(1, 98)
        : 75;
    final yellowFlex = hasCells
        ? ((data.yellowCount / data.totalCells) * 100).round().clamp(1, 98)
        : 18;
    final redFlex = hasCells
        ? ((data.redCount / data.totalCells) * 100).round().clamp(1, 98)
        : 7;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChartHeader(
              eyebrow: 'NHẬN DẠNG AI (UC11–UC13)',
              title: 'Đối chiếu 2 kênh Số & Chữ',
              badge: hasCells ? '${data.accuracyRate}% Khớp' : 'Sẵn sàng',
              badgeBg: const Color(0xFFD5EDE5),
              badgeColor: const Color(0xFF256848),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Máy chỉ đề xuất — Giáo viên so sánh ô cắt cạnh kết quả và bấm Duyệt chính thức.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Stacked Horizontal Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 14,
                      child: Row(
                        children: [
                          Expanded(
                            flex: greenFlex,
                            child: Container(color: const Color(0xFF256848)),
                          ),
                          Expanded(
                            flex: yellowFlex,
                            child: Container(color: const Color(0xFFC69C3C)),
                          ),
                          Expanded(
                            flex: redFlex,
                            child: Container(color: const Color(0xFFC87858)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3 Color Breakdown Details
                  Row(
                    children: [
                      Expanded(
                        child: _buildOcrStatItem(
                          label: 'Xanh (Khớp)',
                          pct: hasCells
                              ? '${((data.greenCount / data.totalCells) * 100).round()}%'
                              : '${data.greenCount}',
                          desc: '2 kênh khớp nhau',
                          color: const Color(0xFF256848),
                          bg: const Color(0xFFD5EDE5),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildOcrStatItem(
                          label: 'Vàng (Lệch)',
                          pct: hasCells
                              ? '${((data.yellowCount / data.totalCells) * 100).round()}%'
                              : '${data.yellowCount}',
                          desc: 'GV đã chỉnh sửa',
                          color: const Color(0xFF9A7222),
                          bg: const Color(0xFFF5E8C9),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildOcrStatItem(
                          label: 'Đỏ (Ô trống)',
                          pct: hasCells
                              ? '${((data.redCount / data.totalCells) * 100).round()}%'
                              : '${data.redCount}',
                          desc: 'GV nhập tay lại',
                          color: const Color(0xFF9B4430),
                          bg: const Color(0xFFFBE4DC),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            _buildChartFooter(
              icon: Icons.verified_outlined,
              text: hasCells
                  ? 'Đã đối chiếu ${data.totalCells} ô điểm · Độ chính xác 2 kênh: ${data.accuracyRate}%'
                  : 'Hệ thống sẵn sàng tiếp nhận ảnh phiếu điểm viết tay',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOcrStatItem({
    required String label,
    required String pct,
    required String desc,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pct,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            desc,
            style: TextStyle(fontSize: 8.5, color: color.withAlpha(200)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Chart 3: Grade Level Progress ────────────────────────────────────────────
class _GradeLevelProgressCard extends StatelessWidget {
  const _GradeLevelProgressCard({
    required this.items,
    required this.lockedBooks,
    required this.totalBooks,
    required this.completionRate,
  });

  final List<AdminGradeLevelProgressItem> items;
  final int lockedBooks;
  final int totalBooks;
  final int completionRate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChartHeader(
              eyebrow: 'TIẾN ĐỘ THEO KHỐI',
              title: 'Tỷ lệ chốt sổ của giáo viên',
              badge: '$totalBooks Sổ điểm',
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: items.map((item) {
                  final percent = (item.percentage / 100.0).clamp(0.0, 1.0);
                  final color = percent >= 0.8
                      ? const Color(0xFF276E68)
                      : (percent >= 0.4
                            ? const Color(0xFF2D7D75)
                            : const Color(0xFFC69C3C));

                  return _buildProgressRow(
                    title: item.title,
                    ratio: '${item.lockedClasses} / ${item.totalClasses} lớp',
                    percent: percent,
                    color: color,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            _buildChartFooter(
              icon: Icons.task_alt_rounded,
              text:
                  'Tiến độ toàn trường: $lockedBooks / $totalBooks bảng điểm đã chốt ($completionRate%)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow({
    required String title,
    required String ratio,
    required double percent,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
              ),
            ),
            Text(
              '$ratio (${(percent * 100).toInt()}%)',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 7,
            backgroundColor: const Color(0xFFE8E5DD),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ── Chart 4: Recent Activity Table ───────────────────────────────────────────
class _RecentGradebookActivityCard extends StatelessWidget {
  const _RecentGradebookActivityCard({
    required this.activities,
    required this.totalTeachers,
    required this.totalClasses,
  });

  final List<AdminRecentActivityItem> activities;
  final int totalTeachers;
  final int totalClasses;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChartHeader(
              eyebrow: 'NHẬT KÝ HỌC VỤ',
              title: 'Hoạt động nộp điểm gần đây',
              badge: 'DB Thực tế',
            ),
            const SizedBox(height: 8),

            Expanded(
              child: activities.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có hoạt động cập nhật bảng điểm nào',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: activities.map((act) {
                        final isLocked = act.status == 'Đã chốt';
                        final color = isLocked
                            ? const Color(0xFF276E68)
                            : const Color(0xFFC69C3C);

                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8E5DD),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                act.className,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    act.subjectName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    act.teacherName,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: AppTheme.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: color.withAlpha(80)),
                              ),
                              child: Text(
                                act.status,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 8),

            _buildChartFooter(
              icon: Icons.history_rounded,
              text:
                  '$totalTeachers Giáo viên bộ môn · $totalClasses Lớp học THPT Bà Điểm',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminChartsLoadingSkeleton extends StatelessWidget {
  const _AdminChartsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.widgetBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5),
            SizedBox(height: 12),
            Text(
              'Đang tải số liệu thống kê từ cơ sở dữ liệu...',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
