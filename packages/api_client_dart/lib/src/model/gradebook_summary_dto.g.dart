// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gradebook_summary_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GradebookSummaryDtoCWProxy {
  GradebookSummaryDto gradebookId(num gradebookId);

  GradebookSummaryDto students(num students);

  GradebookSummaryDto average(String? average);

  GradebookSummaryDto highest(String? highest);

  GradebookSummaryDto lowest(String? lowest);

  GradebookSummaryDto passed(num passed);

  GradebookSummaryDto failed(num failed);

  GradebookSummaryDto distribution(List<DistributionItemDto> distribution);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradebookSummaryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradebookSummaryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  GradebookSummaryDto call({
    num gradebookId,
    num students,
    String? average,
    String? highest,
    String? lowest,
    num passed,
    num failed,
    List<DistributionItemDto> distribution,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGradebookSummaryDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGradebookSummaryDto.copyWith.fieldName(...)`
class _$GradebookSummaryDtoCWProxyImpl implements _$GradebookSummaryDtoCWProxy {
  const _$GradebookSummaryDtoCWProxyImpl(this._value);

  final GradebookSummaryDto _value;

  @override
  GradebookSummaryDto gradebookId(num gradebookId) =>
      this(gradebookId: gradebookId);

  @override
  GradebookSummaryDto students(num students) => this(students: students);

  @override
  GradebookSummaryDto average(String? average) => this(average: average);

  @override
  GradebookSummaryDto highest(String? highest) => this(highest: highest);

  @override
  GradebookSummaryDto lowest(String? lowest) => this(lowest: lowest);

  @override
  GradebookSummaryDto passed(num passed) => this(passed: passed);

  @override
  GradebookSummaryDto failed(num failed) => this(failed: failed);

  @override
  GradebookSummaryDto distribution(List<DistributionItemDto> distribution) =>
      this(distribution: distribution);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradebookSummaryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradebookSummaryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  GradebookSummaryDto call({
    Object? gradebookId = const $CopyWithPlaceholder(),
    Object? students = const $CopyWithPlaceholder(),
    Object? average = const $CopyWithPlaceholder(),
    Object? highest = const $CopyWithPlaceholder(),
    Object? lowest = const $CopyWithPlaceholder(),
    Object? passed = const $CopyWithPlaceholder(),
    Object? failed = const $CopyWithPlaceholder(),
    Object? distribution = const $CopyWithPlaceholder(),
  }) {
    return GradebookSummaryDto(
      gradebookId: gradebookId == const $CopyWithPlaceholder()
          ? _value.gradebookId
          // ignore: cast_nullable_to_non_nullable
          : gradebookId as num,
      students: students == const $CopyWithPlaceholder()
          ? _value.students
          // ignore: cast_nullable_to_non_nullable
          : students as num,
      average: average == const $CopyWithPlaceholder()
          ? _value.average
          // ignore: cast_nullable_to_non_nullable
          : average as String?,
      highest: highest == const $CopyWithPlaceholder()
          ? _value.highest
          // ignore: cast_nullable_to_non_nullable
          : highest as String?,
      lowest: lowest == const $CopyWithPlaceholder()
          ? _value.lowest
          // ignore: cast_nullable_to_non_nullable
          : lowest as String?,
      passed: passed == const $CopyWithPlaceholder()
          ? _value.passed
          // ignore: cast_nullable_to_non_nullable
          : passed as num,
      failed: failed == const $CopyWithPlaceholder()
          ? _value.failed
          // ignore: cast_nullable_to_non_nullable
          : failed as num,
      distribution: distribution == const $CopyWithPlaceholder()
          ? _value.distribution
          // ignore: cast_nullable_to_non_nullable
          : distribution as List<DistributionItemDto>,
    );
  }
}

extension $GradebookSummaryDtoCopyWith on GradebookSummaryDto {
  /// Returns a callable class that can be used as follows: `instanceOfGradebookSummaryDto.copyWith(...)` or like so:`instanceOfGradebookSummaryDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GradebookSummaryDtoCWProxy get copyWith =>
      _$GradebookSummaryDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GradebookSummaryDto _$GradebookSummaryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GradebookSummaryDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'gradebookId',
          'students',
          'average',
          'highest',
          'lowest',
          'passed',
          'failed',
          'distribution',
        ],
      );
      final val = GradebookSummaryDto(
        gradebookId: $checkedConvert('gradebookId', (v) => v as num),
        students: $checkedConvert('students', (v) => v as num),
        average: $checkedConvert('average', (v) => v as String?),
        highest: $checkedConvert('highest', (v) => v as String?),
        lowest: $checkedConvert('lowest', (v) => v as String?),
        passed: $checkedConvert('passed', (v) => v as num),
        failed: $checkedConvert('failed', (v) => v as num),
        distribution: $checkedConvert(
          'distribution',
          (v) => (v as List<dynamic>)
              .map(
                (e) => DistributionItemDto.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GradebookSummaryDtoToJson(
  GradebookSummaryDto instance,
) => <String, dynamic>{
  'gradebookId': instance.gradebookId,
  'students': instance.students,
  'average': instance.average,
  'highest': instance.highest,
  'lowest': instance.lowest,
  'passed': instance.passed,
  'failed': instance.failed,
  'distribution': instance.distribution.map((e) => e.toJson()).toList(),
};
