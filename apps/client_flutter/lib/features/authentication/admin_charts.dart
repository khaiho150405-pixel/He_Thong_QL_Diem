import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_charts.dart';
import '../../app/widgets/app_progress.dart';
import '../reports/repository.dart';

const double kAdminChartCardHeight = 310.0;

class AdminChartsSection extends ConsumerWidget {
  const AdminChartsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final overviewAsync = ref.watch(adminOverviewProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, size: 16, color: t.priLink),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'BIỂU ĐỒ SỐ LIỆU THỐNG KÊ TOÀN TRƯỜNG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: t.ink3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const AppBadge.ok('Trực tiếp (10s)'),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Số liệu thực tế từ cơ sở dữ liệu hệ thống: phổ điểm, độ chính xác AI hai kênh và tiến độ nộp điểm',
              style: TextStyle(fontSize: 12, color: t.ink2),
            ),
            const SizedBox(height: AppSpacing.md),

            overviewAsync.when(
              loading: () => const _AdminChartsLoadingSkeleton(),
              error: (err, _) => DecoratedBox(
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: t.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: t.warn, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Không thể tải thống kê thời gian thực: $err',
                          style: TextStyle(fontSize: 12, color: t.ink2),
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
              ),
              data: (data) {
                final distribution = _GradeDistributionCard(
                  items: data.gradeDistribution,
                  totalStudents: data.kpi.totalStudents,
                );
                final ocr = _OcrAccuracyCard(data: data.ocrAccuracy);
                final progress = _GradeLevelProgressCard(
                  items: data.gradeLevelProgress,
                  lockedBooks: data.kpi.lockedGradebooks,
                  totalBooks: data.kpi.totalGradebooks,
                  completionRate: data.kpi.completionRate,
                );
                final activity = _RecentGradebookActivityCard(
                  activities: data.recentActivities,
                  totalTeachers: data.kpi.totalTeachers,
                  totalClasses: data.kpi.totalClasses,
                );
                Widget sized(Widget card) =>
                    SizedBox(height: kAdminChartCardHeight, child: card);
                if (isWide) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: sized(distribution)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: sized(ocr)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: sized(progress)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: sized(activity)),
                        ],
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    sized(distribution),
                    const SizedBox(height: AppSpacing.md),
                    sized(ocr),
                    const SizedBox(height: AppSpacing.md),
                    sized(progress),
                    const SizedBox(height: AppSpacing.md),
                    sized(activity),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ── Khung thẻ biểu đồ dùng chung ─────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.eyebrow,
    required this.title,
    required this.badge,
    required this.body,
    required this.footerIcon,
    required this.footerText,
  });

  final String eyebrow;
  final String title;
  final Widget badge;
  final Widget body;
  final IconData footerIcon;
  final String footerText;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
        boxShadow: t.shadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 38,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          eyebrow,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: t.ink3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: t.heading,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  badge,
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: body),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 34),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.subtle,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: t.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(footerIcon, size: 14, color: t.ok),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          footerText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: t.ink2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Biểu đồ 1: phân bố học lực ───────────────────────────────────────────────
class _GradeDistributionCard extends StatelessWidget {
  const _GradeDistributionCard({
    required this.items,
    required this.totalStudents,
  });

  final List<AdminGradeDistributionItem> items;
  final int totalStudents;

  /// Màu cột theo mã xếp loại, lấy từ token thay cho mã hex backend trả về:
  /// Giỏi `pri`, Khá xanh nhạt hơn, Đạt `neu`, Chưa đạt `bad`.
  static Color colorOf(AppTokens t, String code) {
    switch (code) {
      case 'GIOI':
        return t.pri;
      case 'KHA':
        return t.brightness == Brightness.dark
            ? t.priLink
            : Color.lerp(t.pri, t.priLine, 0.45)!;
      case 'CHUA_DAT':
      case 'YEU':
        return t.bad;
      case 'DAT':
      default:
        return t.neu;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final totalRated = items.fold<int>(0, (sum, item) => sum + item.count);
    final goodCount = items
        .where((i) => i.code == 'GIOI' || i.code == 'KHA')
        .fold<int>(0, (sum, i) => sum + i.count);
    final passRate = totalRated > 0
        ? ((goodCount / totalRated) * 100).toStringAsFixed(1)
        : '100.0';

    return _ChartCard(
      eyebrow: 'PHÂN BỐ HỌC LỰC',
      title: 'Mức điểm toàn trường',
      badge: const AppBadge('DB Thực tế', dot: false),
      body: Center(
        child: SingleChildScrollView(
          child: AppHBars(
            labelWidth: 64,
            valueWidth: 96,
            items: [
              for (final item in items)
                AppHBarItem(
                  label: item.label,
                  value: item.count.toDouble(),
                  valueText: '${item.count} HS · ${item.percentage}%',
                  color: colorOf(t, item.code),
                ),
            ],
          ),
        ),
      ),
      footerIcon: Icons.check_circle_rounded,
      footerText:
          'Đã tổng kết $totalRated / $totalStudents HS · Tỷ lệ Giỏi & Khá: $passRate%',
    );
  }
}

// ── Biểu đồ 2: độ chính xác OCR hai kênh ─────────────────────────────────────
class _OcrAccuracyCard extends StatelessWidget {
  const _OcrAccuracyCard({required this.data});

  final AdminOcrAccuracyData data;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasCells = data.totalCells > 0;
    String pct(int count) =>
        hasCells ? '${((count / data.totalCells) * 100).round()}%' : '$count';
    double ratio(int count) => hasCells ? count / data.totalCells : 0;

    return _ChartCard(
      eyebrow: 'NHẬN DẠNG AI (UC11–UC13)',
      title: 'Đối chiếu 2 kênh Số & Chữ',
      badge: hasCells
          ? AppBadge.ok('${data.accuracyRate}% Khớp')
          : const AppBadge.ok('Sẵn sàng'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Máy chỉ đề xuất — Giáo viên so sánh ô cắt cạnh kết quả và bấm Duyệt chính thức.',
              style: TextStyle(fontSize: 12, color: t.ink2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
            _OcrRow(
              badge: const AppBadge.ok('Xanh (Khớp)'),
              desc: '2 kênh khớp nhau',
              pct: pct(data.greenCount),
              value: ratio(data.greenCount),
              tone: AppProgressTone.ok,
            ),
            const SizedBox(height: AppSpacing.sm),
            _OcrRow(
              badge: const AppBadge.warn('Vàng (Lệch)'),
              desc: 'GV đã chỉnh sửa',
              pct: pct(data.yellowCount),
              value: ratio(data.yellowCount),
              tone: AppProgressTone.warn,
            ),
            const SizedBox(height: AppSpacing.sm),
            _OcrRow(
              badge: const AppBadge.bad('Đỏ (Ô trống)'),
              desc: 'GV nhập tay lại',
              pct: pct(data.redCount),
              value: ratio(data.redCount),
              tone: AppProgressTone.bad,
            ),
          ],
        ),
      ),
      footerIcon: Icons.verified_outlined,
      footerText: hasCells
          ? 'Đã đối chiếu ${data.totalCells} ô điểm · Độ chính xác 2 kênh: ${data.accuracyRate}%'
          : 'Hệ thống sẵn sàng tiếp nhận ảnh phiếu điểm viết tay',
    );
  }
}

/// Một dòng Xanh/Vàng/Đỏ: nhãn, mô tả, phần trăm và thanh [AppProgress].
class _OcrRow extends StatelessWidget {
  const _OcrRow({
    required this.badge,
    required this.desc,
    required this.pct,
    required this.value,
    required this.tone,
  });

  final AppBadge badge;
  final String desc;
  final String pct;
  final double value;
  final AppProgressTone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            badge,
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                desc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: t.ink3),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              pct,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: t.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        AppProgress(value: value, tone: tone, minWidth: 0),
      ],
    );
  }
}

// ── Biểu đồ 3: tiến độ theo khối ─────────────────────────────────────────────
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
    final t = context.tokens;
    return _ChartCard(
      eyebrow: 'TIẾN ĐỘ THEO KHỐI',
      title: 'Tỷ lệ chốt sổ của giáo viên',
      badge: AppBadge('$totalBooks Sổ điểm', dot: false),
      body: Center(
        child: SingleChildScrollView(
          child: AppHBars(
            max: 1,
            labelWidth: 64,
            valueWidth: 118,
            items: [
              for (final item in items)
                () {
                  final percent = (item.percentage / 100.0).clamp(0.0, 1.0);
                  return AppHBarItem(
                    label: item.title,
                    value: percent,
                    valueText:
                        '${item.lockedClasses} / ${item.totalClasses} lớp (${(percent * 100).toInt()}%)',
                    color: percent >= 0.8
                        ? t.ok
                        : (percent >= 0.4 ? t.pri : t.acc),
                  );
                }(),
            ],
          ),
        ),
      ),
      footerIcon: Icons.task_alt_rounded,
      footerText:
          'Tiến độ toàn trường: $lockedBooks / $totalBooks bảng điểm đã chốt ($completionRate%)',
    );
  }
}

// ── Biểu đồ 4: hoạt động nộp điểm gần đây ────────────────────────────────────
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
    final t = context.tokens;
    return _ChartCard(
      eyebrow: 'NHẬT KÝ HỌC VỤ',
      title: 'Hoạt động nộp điểm gần đây',
      badge: const AppBadge('DB Thực tế', dot: false),
      body: activities.isEmpty
          ? Center(
              child: Text(
                'Chưa có hoạt động cập nhật bảng điểm nào',
                style: TextStyle(fontSize: 12, color: t.ink2),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: activities.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, index) {
                final act = activities[index];
                final isLocked = act.status == 'Đã chốt';
                return Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.hover,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        child: Text(
                          act.className,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: t.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            act.subjectName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: t.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            act.teacherName,
                            style: TextStyle(fontSize: 11, color: t.ink3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    isLocked
                        ? AppBadge.ok(act.status)
                        : AppBadge.info(act.status),
                  ],
                );
              },
            ),
      footerIcon: Icons.history_rounded,
      footerText:
          '$totalTeachers Giáo viên bộ môn · $totalClasses Lớp học THPT Bà Điểm',
    );
  }
}

class _AdminChartsLoadingSkeleton extends StatelessWidget {
  const _AdminChartsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 2.5),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Đang tải số liệu thống kê từ cơ sở dữ liệu...',
              style: TextStyle(fontSize: 12, color: t.ink2),
            ),
          ],
        ),
      ),
    );
  }
}
