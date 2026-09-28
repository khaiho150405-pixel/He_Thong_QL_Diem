import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/shimmer_loading.dart';
import '../authentication/session.dart';

class StudentResultsScreen extends ConsumerStatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  ConsumerState<StudentResultsScreen> createState() =>
      _StudentResultsScreenState();
}

class _StudentResultsScreenState extends ConsumerState<StudentResultsScreen> {
  late Future<List<StudentSubjectResultDto>> data;
  String _viewMode =
      'cards'; // 'cards' (Thẻ chi tiết) hoặc 'table' (Bảng tổng hợp)

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    data = ref
        .read(apiProvider)
        .getStudentResultsApi()
        .studentResultsList()
        .then((response) => response.data!.items);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final session = ref.watch(sessionProvider);
    final studentName = session?.username ?? 'Học sinh';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm của tôi'),
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: () => setState(reload),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: FutureBuilder<List<StudentSubjectResultDto>>(
            future: data,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: ShimmerLoading(itemCount: 4, itemHeight: 96),
                );
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.error_outline,
                  title: 'Lỗi tải kết quả',
                  message: errorMessage(snapshot.error!),
                  actionLabel: 'Thử lại',
                  onAction: () => setState(reload),
                );
              }
              final items = snapshot.data!;
              if (items.isEmpty) {
                return const Center(child: Text('Bạn chưa có điểm đã duyệt.'));
              }

              // Tính toán trạng thái tổng kết học kỳ
              final totalSubjects = items.length;
              final lockedSubjects = items
                  .where((i) => i.finalScore != null)
                  .length;
              final allLocked =
                  totalSubjects > 0 && lockedSubjects == totalSubjects;

              double? gpa;
              if (allLocked) {
                final scores = items.map(
                  (i) => double.tryParse(i.finalScore ?? '') ?? 0.0,
                );
                gpa = scores.reduce((a, b) => a + b) / totalSubjects;
              }

              // Danh sách các cột điểm thành phần duy nhất (ĐĐGtx 1, ĐĐGtx 2, ĐĐGgk, ĐĐGck...)
              final componentNames = <String>[];
              for (final item in items) {
                for (final comp in item.components) {
                  if (!componentNames.contains(comp.componentName)) {
                    componentNames.add(comp.componentName);
                  }
                }
              }

              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                children: [
                  // Banner Thông tin Học sinh & Trường học
                  _buildStudentHeaderBanner(
                    colorScheme: colorScheme,
                    theme: theme,
                    studentName: studentName,
                    termName: items.first.termName,
                    totalSubjects: totalSubjects,
                    lockedSubjects: lockedSubjects,
                    allLocked: allLocked,
                    gpa: gpa,
                  ),

                  const SizedBox(height: 16),

                  // Thanh chuyển đổi View (Bảng tổng hợp vs Thẻ chi tiết)
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Kết quả học tập các môn',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'cards',
                            icon: Icon(Icons.view_agenda_rounded, size: 16),
                            label: Text('Thẻ theo môn'),
                          ),
                          ButtonSegment(
                            value: 'table',
                            icon: Icon(Icons.table_chart_rounded, size: 16),
                            label: Text('Bảng tổng hợp'),
                          ),
                        ],
                        selected: {_viewMode},
                        onSelectionChanged: (val) =>
                            setState(() => _viewMode = val.first),
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Nội dung hiển thị theo chế độ
                  if (_viewMode == 'table')
                    _buildUnifiedGradeTable(
                      colorScheme: colorScheme,
                      theme: theme,
                      items: items,
                      componentNames: componentNames,
                      allLocked: allLocked,
                      gpa: gpa,
                    )
                  else
                    _buildSubjectCards(
                      colorScheme: colorScheme,
                      theme: theme,
                      items: items,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStudentHeaderBanner({
    required ColorScheme colorScheme,
    required ThemeData theme,
    required String studentName,
    required String termName,
    required int totalSubjects,
    required int lockedSubjects,
    required bool allLocked,
    required double? gpa,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withAlpha(200),
            colorScheme.surfaceContainerHigh.withAlpha(150),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withAlpha(220),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withAlpha(80),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'THPT Bà Điểm · $termName',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: allLocked
                      ? const Color(0xFFD5EDE5)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: allLocked
                        ? const Color(0xFF256848).withAlpha(60)
                        : Colors.orange.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      allLocked
                          ? Icons.verified_rounded
                          : Icons.pending_actions_rounded,
                      size: 13,
                      color: allLocked
                          ? const Color(0xFF256848)
                          : Colors.orange.shade900,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      allLocked
                          ? 'Đã công bố ĐTB'
                          : 'Đang cập nhật ($lockedSubjects/$totalSubjects)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: allLocked
                            ? const Color(0xFF256848)
                            : Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primary,
                    child: const Text(
                      'HS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 190),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bảng điểm cá nhân',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Điểm đã được giáo viên duyệt',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (allLocked && gpa != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ĐTB HỌC KỲ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            gpa.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bảng tổng hợp điểm các môn (DataTable chuẩn)
  Widget _buildUnifiedGradeTable({
    required ColorScheme colorScheme,
    required ThemeData theme,
    required List<StudentSubjectResultDto> items,
    required List<String> componentNames,
    required bool allLocked,
    required double? gpa,
  }) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              colorScheme.surfaceContainerHighest.withAlpha(120),
            ),
            columnSpacing: 24,
            horizontalMargin: 20,
            columns: [
              const DataColumn(
                label: Text(
                  'Môn học',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              for (final cName in componentNames)
                DataColumn(
                  label: Text(
                    cName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              const DataColumn(
                label: Text(
                  'ĐTB Môn',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const DataColumn(
                label: Text(
                  'Xếp loại',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
            rows: [
              for (final item in items)
                DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.subjectName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    for (final cName in componentNames)
                      DataCell(
                        Builder(
                          builder: (_) {
                            final comp = item.components
                                .cast<StudentApprovedComponentDto?>()
                                .firstWhere(
                                  (c) => c?.componentName == cName,
                                  orElse: () => null,
                                );
                            if (comp == null || comp.value.isEmpty) {
                              return const Text(
                                '—',
                                style: TextStyle(color: Colors.grey),
                              );
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withAlpha(90),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                comp.value,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    DataCell(
                      item.finalScore != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.finalScore!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Chờ chốt',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                    DataCell(
                      item.classification != null
                          ? _buildClassificationBadge(item.classification!)
                          : const Text(
                              '—',
                              style: TextStyle(color: Colors.grey),
                            ),
                    ),
                  ],
                ),

              // Hàng Tổng kết Học kỳ
              DataRow(
                color: WidgetStateProperty.all(colorScheme.surfaceContainerLow),
                cells: [
                  const DataCell(
                    Text(
                      'ĐIỂM TRUNG BÌNH CHUNG',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  for (var i = 0; i < componentNames.length; i++)
                    const DataCell(Text('')),
                  DataCell(
                    allLocked && gpa != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              gpa.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Chờ công bố',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  DataCell(
                    allLocked && gpa != null
                        ? _buildClassificationBadge(
                            gpa >= 8.0
                                ? 'GIOI'
                                : gpa >= 6.5
                                ? 'KHA'
                                : 'DAT',
                          )
                        : Text(
                            'Chờ công bố',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassificationBadge(String code) {
    Color bg;
    Color fg;
    String label;

    switch (code.toUpperCase()) {
      case 'GIOI':
      case 'GIỎI':
        bg = const Color(0xFFD5EDE5);
        fg = const Color(0xFF256848);
        label = 'Giỏi';
        break;
      case 'KHA':
      case 'KHÁ':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        label = 'Khá';
        break;
      case 'DAT':
      case 'ĐẠT':
      case 'TRUNG_BINH':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'Đạt';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
        label = code;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  /// Dạng thẻ theo môn (Cards View)
  Widget _buildSubjectCards({
    required ColorScheme colorScheme,
    required ThemeData theme,
    required List<StudentSubjectResultDto> items,
  }) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Card(
            margin: EdgeInsets.only(bottom: i < items.length - 1 ? 12 : 0),
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
            ),
            child: ExpansionTile(
              initiallyExpanded: i == 0,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.school_outlined,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              title: Text(
                items[i].subjectName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                items[i].termName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: items[i].finalScore != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${items[i].finalScore} · ${items[i].classification ?? "—"}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 12.5,
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Chờ chốt ĐTB',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          for (final comp in items[i].components)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withAlpha(80),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withAlpha(
                                    60,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comp.componentName,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        comp.value,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(hs ${comp.coefficient})',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (items[i].calculatedAt != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Đã chốt & tính ĐTB lúc ${items[i].calculatedAt!.toLocal()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
