//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/admin_kpi_dto.dart';
import 'package:api_client_dart/src/model/admin_grade_level_progress_dto.dart';
import 'package:api_client_dart/src/model/admin_recent_activity_dto.dart';
import 'package:api_client_dart/src/model/admin_grade_distribution_dto.dart';
import 'package:api_client_dart/src/model/admin_ocr_accuracy_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_overview_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminOverviewDto {
  /// Returns a new [AdminOverviewDto] instance.
  AdminOverviewDto({
    required this.kpi,

    required this.gradeDistribution,

    required this.gradeLevelProgress,

    required this.ocrAccuracy,

    required this.recentActivities,
  });

  @JsonKey(name: r'kpi', required: true, includeIfNull: false)
  final AdminKpiDto kpi;

  @JsonKey(name: r'gradeDistribution', required: true, includeIfNull: false)
  final List<AdminGradeDistributionDto> gradeDistribution;

  @JsonKey(name: r'gradeLevelProgress', required: true, includeIfNull: false)
  final List<AdminGradeLevelProgressDto> gradeLevelProgress;

  @JsonKey(name: r'ocrAccuracy', required: true, includeIfNull: false)
  final AdminOcrAccuracyDto ocrAccuracy;

  @JsonKey(name: r'recentActivities', required: true, includeIfNull: false)
  final List<AdminRecentActivityDto> recentActivities;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminOverviewDto &&
          other.kpi == kpi &&
          other.gradeDistribution == gradeDistribution &&
          other.gradeLevelProgress == gradeLevelProgress &&
          other.ocrAccuracy == ocrAccuracy &&
          other.recentActivities == recentActivities;

  @override
  int get hashCode =>
      kpi.hashCode +
      gradeDistribution.hashCode +
      gradeLevelProgress.hashCode +
      ocrAccuracy.hashCode +
      recentActivities.hashCode;

  factory AdminOverviewDto.fromJson(Map<String, dynamic> json) =>
      _$AdminOverviewDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AdminOverviewDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
