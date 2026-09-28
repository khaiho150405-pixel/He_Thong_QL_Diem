import 'dart:async';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../authentication/session.dart';

final reportsRepositoryProvider = Provider(
  (ref) => ReportsRepository(ref.read(apiProvider)),
);

final adminOverviewProvider =
    StateNotifierProvider.autoDispose<
      AdminOverviewNotifier,
      AsyncValue<AdminOverviewData>
    >((ref) => AdminOverviewNotifier(ref.watch(reportsRepositoryProvider)));

class AdminOverviewNotifier
    extends StateNotifier<AsyncValue<AdminOverviewData>> {
  AdminOverviewNotifier(this._repository) : super(const AsyncValue.loading()) {
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      refresh(silent: true);
    });
  }

  final ReportsRepository _repository;
  Timer? _timer;

  Future<void> refresh({bool silent = false}) async {
    if (!silent || state.value == null) {
      if (!silent) state = const AsyncValue.loading();
    }
    try {
      final data = await _repository.adminOverview();
      if (mounted) state = AsyncValue.data(data);
    } catch (e, st) {
      if (mounted && (!silent || state.value == null)) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class ReportsRepository {
  ReportsRepository(this.api);

  final ApiClientDart api;

  Future<GradebookSummaryDto> summary(num gradebookId) async =>
      (await api.getReportsApi().reportsSummary(
        gradebookId: gradebookId,
      )).data!;

  Future<Uint8List> export(num gradebookId) async =>
      (await api.getReportsApi().reportsExport(gradebookId: gradebookId)).data!;

  Future<AdminOverviewData> adminOverview() async {
    final response = await api.dio.get('/api/v1/reports/admin/overview');
    return AdminOverviewData.fromJson(response.data as Map<String, dynamic>);
  }
}

class AdminOverviewData {
  const AdminOverviewData({
    required this.kpi,
    required this.gradeDistribution,
    required this.gradeLevelProgress,
    required this.ocrAccuracy,
    required this.recentActivities,
  });

  final AdminKpiData kpi;
  final List<AdminGradeDistributionItem> gradeDistribution;
  final List<AdminGradeLevelProgressItem> gradeLevelProgress;
  final AdminOcrAccuracyData ocrAccuracy;
  final List<AdminRecentActivityItem> recentActivities;

  factory AdminOverviewData.fromJson(Map<String, dynamic> json) {
    return AdminOverviewData(
      kpi: AdminKpiData.fromJson(json['kpi'] as Map<String, dynamic>? ?? {}),
      gradeDistribution: (json['gradeDistribution'] as List<dynamic>? ?? [])
          .map(
            (e) =>
                AdminGradeDistributionItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      gradeLevelProgress: (json['gradeLevelProgress'] as List<dynamic>? ?? [])
          .map(
            (e) =>
                AdminGradeLevelProgressItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      ocrAccuracy: AdminOcrAccuracyData.fromJson(
        json['ocrAccuracy'] as Map<String, dynamic>? ?? {},
      ),
      recentActivities: (json['recentActivities'] as List<dynamic>? ?? [])
          .map(
            (e) => AdminRecentActivityItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class AdminKpiData {
  const AdminKpiData({
    required this.totalStudents,
    required this.totalClasses,
    required this.totalTeachers,
    required this.lockedGradebooks,
    required this.totalGradebooks,
    required this.completionRate,
    required this.pendingOcrTickets,
  });

  final int totalStudents;
  final int totalClasses;
  final int totalTeachers;
  final int lockedGradebooks;
  final int totalGradebooks;
  final int completionRate;
  final int pendingOcrTickets;

  factory AdminKpiData.fromJson(Map<String, dynamic> json) {
    return AdminKpiData(
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      totalClasses: (json['totalClasses'] as num?)?.toInt() ?? 0,
      totalTeachers: (json['totalTeachers'] as num?)?.toInt() ?? 0,
      lockedGradebooks: (json['lockedGradebooks'] as num?)?.toInt() ?? 0,
      totalGradebooks: (json['totalGradebooks'] as num?)?.toInt() ?? 0,
      completionRate: (json['completionRate'] as num?)?.toInt() ?? 0,
      pendingOcrTickets: (json['pendingOcrTickets'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminGradeDistributionItem {
  const AdminGradeDistributionItem({
    required this.code,
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });

  final String code;
  final String label;
  final int count;
  final int percentage;
  final String color;

  factory AdminGradeDistributionItem.fromJson(Map<String, dynamic> json) {
    return AdminGradeDistributionItem(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
      color: json['color']?.toString() ?? '#276E68',
    );
  }
}

class AdminGradeLevelProgressItem {
  const AdminGradeLevelProgressItem({
    required this.grade,
    required this.title,
    required this.lockedClasses,
    required this.totalClasses,
    required this.percentage,
  });

  final int grade;
  final String title;
  final int lockedClasses;
  final int totalClasses;
  final int percentage;

  factory AdminGradeLevelProgressItem.fromJson(Map<String, dynamic> json) {
    return AdminGradeLevelProgressItem(
      grade: (json['grade'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      lockedClasses: (json['lockedClasses'] as num?)?.toInt() ?? 0,
      totalClasses: (json['totalClasses'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminOcrAccuracyData {
  const AdminOcrAccuracyData({
    required this.totalCells,
    required this.greenCount,
    required this.yellowCount,
    required this.redCount,
    required this.accuracyRate,
  });

  final int totalCells;
  final int greenCount;
  final int yellowCount;
  final int redCount;
  final int accuracyRate;

  factory AdminOcrAccuracyData.fromJson(Map<String, dynamic> json) {
    return AdminOcrAccuracyData(
      totalCells: (json['totalCells'] as num?)?.toInt() ?? 0,
      greenCount: (json['greenCount'] as num?)?.toInt() ?? 0,
      yellowCount: (json['yellowCount'] as num?)?.toInt() ?? 0,
      redCount: (json['redCount'] as num?)?.toInt() ?? 0,
      accuracyRate: (json['accuracyRate'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminRecentActivityItem {
  const AdminRecentActivityItem({
    required this.className,
    required this.subjectName,
    required this.teacherName,
    required this.status,
    required this.updatedAt,
  });

  final String className;
  final String subjectName;
  final String teacherName;
  final String status;
  final String updatedAt;

  factory AdminRecentActivityItem.fromJson(Map<String, dynamic> json) {
    return AdminRecentActivityItem(
      className: json['className']?.toString() ?? '',
      subjectName: json['subjectName']?.toString() ?? '',
      teacherName: json['teacherName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}
