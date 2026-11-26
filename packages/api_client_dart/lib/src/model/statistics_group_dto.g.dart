// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_group_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StatisticsGroupDtoCWProxy {
  StatisticsGroupDto key(num key);

  StatisticsGroupDto label(String label);

  StatisticsGroupDto students(num students);

  StatisticsGroupDto average(String? average);

  StatisticsGroupDto fromEight(num fromEight);

  StatisticsGroupDto fromSixHalf(num fromSixHalf);

  StatisticsGroupDto fromFive(num fromFive);

  StatisticsGroupDto belowFive(num belowFive);

  StatisticsGroupDto passed(num passed);

  StatisticsGroupDto failed(num failed);

  StatisticsGroupDto missing(num missing);

  StatisticsGroupDto levels(LevelCountsDto? levels);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StatisticsGroupDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StatisticsGroupDto(...).copyWith(id: 12, name: "My name")
  /// ````
  StatisticsGroupDto call({
    num key,
    String label,
    num students,
    String? average,
    num fromEight,
    num fromSixHalf,
    num fromFive,
    num belowFive,
    num passed,
    num failed,
    num missing,
    LevelCountsDto? levels,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStatisticsGroupDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStatisticsGroupDto.copyWith.fieldName(...)`
class _$StatisticsGroupDtoCWProxyImpl implements _$StatisticsGroupDtoCWProxy {
  const _$StatisticsGroupDtoCWProxyImpl(this._value);

  final StatisticsGroupDto _value;

  @override
  StatisticsGroupDto key(num key) => this(key: key);

  @override
  StatisticsGroupDto label(String label) => this(label: label);

  @override
  StatisticsGroupDto students(num students) => this(students: students);

  @override
  StatisticsGroupDto average(String? average) => this(average: average);

  @override
  StatisticsGroupDto fromEight(num fromEight) => this(fromEight: fromEight);

  @override
  StatisticsGroupDto fromSixHalf(num fromSixHalf) =>
      this(fromSixHalf: fromSixHalf);

  @override
  StatisticsGroupDto fromFive(num fromFive) => this(fromFive: fromFive);

  @override
  StatisticsGroupDto belowFive(num belowFive) => this(belowFive: belowFive);

  @override
  StatisticsGroupDto passed(num passed) => this(passed: passed);

  @override
  StatisticsGroupDto failed(num failed) => this(failed: failed);

  @override
  StatisticsGroupDto missing(num missing) => this(missing: missing);

  @override
  StatisticsGroupDto levels(LevelCountsDto? levels) => this(levels: levels);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StatisticsGroupDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StatisticsGroupDto(...).copyWith(id: 12, name: "My name")
  /// ````
  StatisticsGroupDto call({
    Object? key = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? students = const $CopyWithPlaceholder(),
    Object? average = const $CopyWithPlaceholder(),
    Object? fromEight = const $CopyWithPlaceholder(),
    Object? fromSixHalf = const $CopyWithPlaceholder(),
    Object? fromFive = const $CopyWithPlaceholder(),
    Object? belowFive = const $CopyWithPlaceholder(),
    Object? passed = const $CopyWithPlaceholder(),
    Object? failed = const $CopyWithPlaceholder(),
    Object? missing = const $CopyWithPlaceholder(),
    Object? levels = const $CopyWithPlaceholder(),
  }) {
    return StatisticsGroupDto(
      key: key == const $CopyWithPlaceholder()
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as num,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      students: students == const $CopyWithPlaceholder()
          ? _value.students
          // ignore: cast_nullable_to_non_nullable
          : students as num,
      average: average == const $CopyWithPlaceholder()
          ? _value.average
          // ignore: cast_nullable_to_non_nullable
          : average as String?,
      fromEight: fromEight == const $CopyWithPlaceholder()
          ? _value.fromEight
          // ignore: cast_nullable_to_non_nullable
          : fromEight as num,
      fromSixHalf: fromSixHalf == const $CopyWithPlaceholder()
          ? _value.fromSixHalf
          // ignore: cast_nullable_to_non_nullable
          : fromSixHalf as num,
      fromFive: fromFive == const $CopyWithPlaceholder()
          ? _value.fromFive
          // ignore: cast_nullable_to_non_nullable
          : fromFive as num,
      belowFive: belowFive == const $CopyWithPlaceholder()
          ? _value.belowFive
          // ignore: cast_nullable_to_non_nullable
          : belowFive as num,
      passed: passed == const $CopyWithPlaceholder()
          ? _value.passed
          // ignore: cast_nullable_to_non_nullable
          : passed as num,
      failed: failed == const $CopyWithPlaceholder()
          ? _value.failed
          // ignore: cast_nullable_to_non_nullable
          : failed as num,
      missing: missing == const $CopyWithPlaceholder()
          ? _value.missing
          // ignore: cast_nullable_to_non_nullable
          : missing as num,
      levels: levels == const $CopyWithPlaceholder()
          ? _value.levels
          // ignore: cast_nullable_to_non_nullable
          : levels as LevelCountsDto?,
    );
  }
}

extension $StatisticsGroupDtoCopyWith on StatisticsGroupDto {
  /// Returns a callable class that can be used as follows: `instanceOfStatisticsGroupDto.copyWith(...)` or like so:`instanceOfStatisticsGroupDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StatisticsGroupDtoCWProxy get copyWith =>
      _$StatisticsGroupDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatisticsGroupDto _$StatisticsGroupDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StatisticsGroupDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'key',
          'label',
          'students',
          'average',
          'fromEight',
          'fromSixHalf',
          'fromFive',
          'belowFive',
          'passed',
          'failed',
          'missing',
          'levels',
        ],
      );
      final val = StatisticsGroupDto(
        key: $checkedConvert('key', (v) => v as num),
        label: $checkedConvert('label', (v) => v as String),
        students: $checkedConvert('students', (v) => v as num),
        average: $checkedConvert('average', (v) => v as String?),
        fromEight: $checkedConvert('fromEight', (v) => v as num),
        fromSixHalf: $checkedConvert('fromSixHalf', (v) => v as num),
        fromFive: $checkedConvert('fromFive', (v) => v as num),
        belowFive: $checkedConvert('belowFive', (v) => v as num),
        passed: $checkedConvert('passed', (v) => v as num),
        failed: $checkedConvert('failed', (v) => v as num),
        missing: $checkedConvert('missing', (v) => v as num),
        levels: $checkedConvert(
          'levels',
          (v) => v == null
              ? null
              : LevelCountsDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$StatisticsGroupDtoToJson(StatisticsGroupDto instance) =>
    <String, dynamic>{
      'key': instance.key,
      'label': instance.label,
      'students': instance.students,
      'average': instance.average,
      'fromEight': instance.fromEight,
      'fromSixHalf': instance.fromSixHalf,
      'fromFive': instance.fromFive,
      'belowFive': instance.belowFive,
      'passed': instance.passed,
      'failed': instance.failed,
      'missing': instance.missing,
      'levels': instance.levels?.toJson(),
    };
