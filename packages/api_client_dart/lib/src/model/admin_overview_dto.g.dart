// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_overview_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminOverviewDtoCWProxy {
  AdminOverviewDto kpi(AdminKpiDto kpi);

  AdminOverviewDto gradeDistribution(
    List<AdminGradeDistributionDto> gradeDistribution,
  );

  AdminOverviewDto gradeLevelProgress(
    List<AdminGradeLevelProgressDto> gradeLevelProgress,
  );

  AdminOverviewDto ocrAccuracy(AdminOcrAccuracyDto ocrAccuracy);

  AdminOverviewDto recentActivities(
    List<AdminRecentActivityDto> recentActivities,
  );

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminOverviewDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminOverviewDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminOverviewDto call({
    AdminKpiDto kpi,
    List<AdminGradeDistributionDto> gradeDistribution,
    List<AdminGradeLevelProgressDto> gradeLevelProgress,
    AdminOcrAccuracyDto ocrAccuracy,
    List<AdminRecentActivityDto> recentActivities,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminOverviewDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminOverviewDto.copyWith.fieldName(...)`
class _$AdminOverviewDtoCWProxyImpl implements _$AdminOverviewDtoCWProxy {
  const _$AdminOverviewDtoCWProxyImpl(this._value);

  final AdminOverviewDto _value;

  @override
  AdminOverviewDto kpi(AdminKpiDto kpi) => this(kpi: kpi);

  @override
  AdminOverviewDto gradeDistribution(
    List<AdminGradeDistributionDto> gradeDistribution,
  ) => this(gradeDistribution: gradeDistribution);

  @override
  AdminOverviewDto gradeLevelProgress(
    List<AdminGradeLevelProgressDto> gradeLevelProgress,
  ) => this(gradeLevelProgress: gradeLevelProgress);

  @override
  AdminOverviewDto ocrAccuracy(AdminOcrAccuracyDto ocrAccuracy) =>
      this(ocrAccuracy: ocrAccuracy);

  @override
  AdminOverviewDto recentActivities(
    List<AdminRecentActivityDto> recentActivities,
  ) => this(recentActivities: recentActivities);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminOverviewDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminOverviewDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminOverviewDto call({
    Object? kpi = const $CopyWithPlaceholder(),
    Object? gradeDistribution = const $CopyWithPlaceholder(),
    Object? gradeLevelProgress = const $CopyWithPlaceholder(),
    Object? ocrAccuracy = const $CopyWithPlaceholder(),
    Object? recentActivities = const $CopyWithPlaceholder(),
  }) {
    return AdminOverviewDto(
      kpi: kpi == const $CopyWithPlaceholder()
          ? _value.kpi
          // ignore: cast_nullable_to_non_nullable
          : kpi as AdminKpiDto,
      gradeDistribution: gradeDistribution == const $CopyWithPlaceholder()
          ? _value.gradeDistribution
          // ignore: cast_nullable_to_non_nullable
          : gradeDistribution as List<AdminGradeDistributionDto>,
      gradeLevelProgress: gradeLevelProgress == const $CopyWithPlaceholder()
          ? _value.gradeLevelProgress
          // ignore: cast_nullable_to_non_nullable
          : gradeLevelProgress as List<AdminGradeLevelProgressDto>,
      ocrAccuracy: ocrAccuracy == const $CopyWithPlaceholder()
          ? _value.ocrAccuracy
          // ignore: cast_nullable_to_non_nullable
          : ocrAccuracy as AdminOcrAccuracyDto,
      recentActivities: recentActivities == const $CopyWithPlaceholder()
          ? _value.recentActivities
          // ignore: cast_nullable_to_non_nullable
          : recentActivities as List<AdminRecentActivityDto>,
    );
  }
}

extension $AdminOverviewDtoCopyWith on AdminOverviewDto {
  /// Returns a callable class that can be used as follows: `instanceOfAdminOverviewDto.copyWith(...)` or like so:`instanceOfAdminOverviewDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminOverviewDtoCWProxy get copyWith => _$AdminOverviewDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminOverviewDto _$AdminOverviewDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminOverviewDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'kpi',
      'gradeDistribution',
      'gradeLevelProgress',
      'ocrAccuracy',
      'recentActivities',
    ],
  );
  final val = AdminOverviewDto(
    kpi: $checkedConvert(
      'kpi',
      (v) => AdminKpiDto.fromJson(v as Map<String, dynamic>),
    ),
    gradeDistribution: $checkedConvert(
      'gradeDistribution',
      (v) => (v as List<dynamic>)
          .map(
            (e) =>
                AdminGradeDistributionDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    gradeLevelProgress: $checkedConvert(
      'gradeLevelProgress',
      (v) => (v as List<dynamic>)
          .map(
            (e) =>
                AdminGradeLevelProgressDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    ocrAccuracy: $checkedConvert(
      'ocrAccuracy',
      (v) => AdminOcrAccuracyDto.fromJson(v as Map<String, dynamic>),
    ),
    recentActivities: $checkedConvert(
      'recentActivities',
      (v) => (v as List<dynamic>)
          .map(
            (e) => AdminRecentActivityDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$AdminOverviewDtoToJson(
  AdminOverviewDto instance,
) => <String, dynamic>{
  'kpi': instance.kpi.toJson(),
  'gradeDistribution': instance.gradeDistribution
      .map((e) => e.toJson())
      .toList(),
  'gradeLevelProgress': instance.gradeLevelProgress
      .map((e) => e.toJson())
      .toList(),
  'ocrAccuracy': instance.ocrAccuracy.toJson(),
  'recentActivities': instance.recentActivities.map((e) => e.toJson()).toList(),
};
