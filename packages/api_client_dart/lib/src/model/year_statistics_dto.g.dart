// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'year_statistics_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$YearStatisticsDtoCWProxy {
  YearStatisticsDto yearId(num yearId);

  YearStatisticsDto yearName(String yearName);

  YearStatisticsDto source_(String source_);

  YearStatisticsDto snapshotVersion(num? snapshotVersion);

  YearStatisticsDto snapshotAt(String? snapshotAt);

  YearStatisticsDto total(StatisticsGroupDto? total);

  YearStatisticsDto grades(List<StatisticsGroupDto> grades);

  YearStatisticsDto classes(List<StatisticsGroupDto> classes);

  YearStatisticsDto subjects(List<StatisticsGroupDto> subjects);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearStatisticsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearStatisticsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  YearStatisticsDto call({
    num yearId,
    String yearName,
    String source_,
    num? snapshotVersion,
    String? snapshotAt,
    StatisticsGroupDto? total,
    List<StatisticsGroupDto> grades,
    List<StatisticsGroupDto> classes,
    List<StatisticsGroupDto> subjects,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfYearStatisticsDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfYearStatisticsDto.copyWith.fieldName(...)`
class _$YearStatisticsDtoCWProxyImpl implements _$YearStatisticsDtoCWProxy {
  const _$YearStatisticsDtoCWProxyImpl(this._value);

  final YearStatisticsDto _value;

  @override
  YearStatisticsDto yearId(num yearId) => this(yearId: yearId);

  @override
  YearStatisticsDto yearName(String yearName) => this(yearName: yearName);

  @override
  YearStatisticsDto source_(String source_) => this(source_: source_);

  @override
  YearStatisticsDto snapshotVersion(num? snapshotVersion) =>
      this(snapshotVersion: snapshotVersion);

  @override
  YearStatisticsDto snapshotAt(String? snapshotAt) =>
      this(snapshotAt: snapshotAt);

  @override
  YearStatisticsDto total(StatisticsGroupDto? total) => this(total: total);

  @override
  YearStatisticsDto grades(List<StatisticsGroupDto> grades) =>
      this(grades: grades);

  @override
  YearStatisticsDto classes(List<StatisticsGroupDto> classes) =>
      this(classes: classes);

  @override
  YearStatisticsDto subjects(List<StatisticsGroupDto> subjects) =>
      this(subjects: subjects);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearStatisticsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearStatisticsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  YearStatisticsDto call({
    Object? yearId = const $CopyWithPlaceholder(),
    Object? yearName = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? snapshotVersion = const $CopyWithPlaceholder(),
    Object? snapshotAt = const $CopyWithPlaceholder(),
    Object? total = const $CopyWithPlaceholder(),
    Object? grades = const $CopyWithPlaceholder(),
    Object? classes = const $CopyWithPlaceholder(),
    Object? subjects = const $CopyWithPlaceholder(),
  }) {
    return YearStatisticsDto(
      yearId: yearId == const $CopyWithPlaceholder()
          ? _value.yearId
          // ignore: cast_nullable_to_non_nullable
          : yearId as num,
      yearName: yearName == const $CopyWithPlaceholder()
          ? _value.yearName
          // ignore: cast_nullable_to_non_nullable
          : yearName as String,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as String,
      snapshotVersion: snapshotVersion == const $CopyWithPlaceholder()
          ? _value.snapshotVersion
          // ignore: cast_nullable_to_non_nullable
          : snapshotVersion as num?,
      snapshotAt: snapshotAt == const $CopyWithPlaceholder()
          ? _value.snapshotAt
          // ignore: cast_nullable_to_non_nullable
          : snapshotAt as String?,
      total: total == const $CopyWithPlaceholder()
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as StatisticsGroupDto?,
      grades: grades == const $CopyWithPlaceholder()
          ? _value.grades
          // ignore: cast_nullable_to_non_nullable
          : grades as List<StatisticsGroupDto>,
      classes: classes == const $CopyWithPlaceholder()
          ? _value.classes
          // ignore: cast_nullable_to_non_nullable
          : classes as List<StatisticsGroupDto>,
      subjects: subjects == const $CopyWithPlaceholder()
          ? _value.subjects
          // ignore: cast_nullable_to_non_nullable
          : subjects as List<StatisticsGroupDto>,
    );
  }
}

extension $YearStatisticsDtoCopyWith on YearStatisticsDto {
  /// Returns a callable class that can be used as follows: `instanceOfYearStatisticsDto.copyWith(...)` or like so:`instanceOfYearStatisticsDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$YearStatisticsDtoCWProxy get copyWith =>
      _$YearStatisticsDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YearStatisticsDto _$YearStatisticsDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('YearStatisticsDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'yearId',
      'yearName',
      'source',
      'snapshotVersion',
      'snapshotAt',
      'total',
      'grades',
      'classes',
      'subjects',
    ],
  );
  final val = YearStatisticsDto(
    yearId: $checkedConvert('yearId', (v) => v as num),
    yearName: $checkedConvert('yearName', (v) => v as String),
    source_: $checkedConvert('source', (v) => v as String),
    snapshotVersion: $checkedConvert('snapshotVersion', (v) => v as num?),
    snapshotAt: $checkedConvert('snapshotAt', (v) => v as String?),
    total: $checkedConvert(
      'total',
      (v) => v == null
          ? null
          : StatisticsGroupDto.fromJson(v as Map<String, dynamic>),
    ),
    grades: $checkedConvert(
      'grades',
      (v) => (v as List<dynamic>)
          .map((e) => StatisticsGroupDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    classes: $checkedConvert(
      'classes',
      (v) => (v as List<dynamic>)
          .map((e) => StatisticsGroupDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    subjects: $checkedConvert(
      'subjects',
      (v) => (v as List<dynamic>)
          .map((e) => StatisticsGroupDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$YearStatisticsDtoToJson(YearStatisticsDto instance) =>
    <String, dynamic>{
      'yearId': instance.yearId,
      'yearName': instance.yearName,
      'source': instance.source_,
      'snapshotVersion': instance.snapshotVersion,
      'snapshotAt': instance.snapshotAt,
      'total': instance.total?.toJson(),
      'grades': instance.grades.map((e) => e.toJson()).toList(),
      'classes': instance.classes.map((e) => e.toJson()).toList(),
      'subjects': instance.subjects.map((e) => e.toJson()).toList(),
    };
