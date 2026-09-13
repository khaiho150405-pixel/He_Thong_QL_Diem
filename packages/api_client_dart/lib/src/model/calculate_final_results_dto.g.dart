// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calculate_final_results_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CalculateFinalResultsDtoCWProxy {
  CalculateFinalResultsDto gradebookId(num gradebookId);

  CalculateFinalResultsDto gradebookVersion(num gradebookVersion);

  CalculateFinalResultsDto weightVersion(String weightVersion);

  CalculateFinalResultsDto policyVersion(String policyVersion);

  CalculateFinalResultsDto calculatedStudents(num calculatedStudents);

  CalculateFinalResultsDto skippedStudents(num skippedStudents);

  CalculateFinalResultsDto results(List<FinalResultDto> results);

  CalculateFinalResultsDto skipped(List<SkippedStudentDto> skipped);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CalculateFinalResultsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CalculateFinalResultsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  CalculateFinalResultsDto call({
    num gradebookId,
    num gradebookVersion,
    String weightVersion,
    String policyVersion,
    num calculatedStudents,
    num skippedStudents,
    List<FinalResultDto> results,
    List<SkippedStudentDto> skipped,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCalculateFinalResultsDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCalculateFinalResultsDto.copyWith.fieldName(...)`
class _$CalculateFinalResultsDtoCWProxyImpl
    implements _$CalculateFinalResultsDtoCWProxy {
  const _$CalculateFinalResultsDtoCWProxyImpl(this._value);

  final CalculateFinalResultsDto _value;

  @override
  CalculateFinalResultsDto gradebookId(num gradebookId) =>
      this(gradebookId: gradebookId);

  @override
  CalculateFinalResultsDto gradebookVersion(num gradebookVersion) =>
      this(gradebookVersion: gradebookVersion);

  @override
  CalculateFinalResultsDto weightVersion(String weightVersion) =>
      this(weightVersion: weightVersion);

  @override
  CalculateFinalResultsDto policyVersion(String policyVersion) =>
      this(policyVersion: policyVersion);

  @override
  CalculateFinalResultsDto calculatedStudents(num calculatedStudents) =>
      this(calculatedStudents: calculatedStudents);

  @override
  CalculateFinalResultsDto skippedStudents(num skippedStudents) =>
      this(skippedStudents: skippedStudents);

  @override
  CalculateFinalResultsDto results(List<FinalResultDto> results) =>
      this(results: results);

  @override
  CalculateFinalResultsDto skipped(List<SkippedStudentDto> skipped) =>
      this(skipped: skipped);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CalculateFinalResultsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CalculateFinalResultsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  CalculateFinalResultsDto call({
    Object? gradebookId = const $CopyWithPlaceholder(),
    Object? gradebookVersion = const $CopyWithPlaceholder(),
    Object? weightVersion = const $CopyWithPlaceholder(),
    Object? policyVersion = const $CopyWithPlaceholder(),
    Object? calculatedStudents = const $CopyWithPlaceholder(),
    Object? skippedStudents = const $CopyWithPlaceholder(),
    Object? results = const $CopyWithPlaceholder(),
    Object? skipped = const $CopyWithPlaceholder(),
  }) {
    return CalculateFinalResultsDto(
      gradebookId: gradebookId == const $CopyWithPlaceholder()
          ? _value.gradebookId
          // ignore: cast_nullable_to_non_nullable
          : gradebookId as num,
      gradebookVersion: gradebookVersion == const $CopyWithPlaceholder()
          ? _value.gradebookVersion
          // ignore: cast_nullable_to_non_nullable
          : gradebookVersion as num,
      weightVersion: weightVersion == const $CopyWithPlaceholder()
          ? _value.weightVersion
          // ignore: cast_nullable_to_non_nullable
          : weightVersion as String,
      policyVersion: policyVersion == const $CopyWithPlaceholder()
          ? _value.policyVersion
          // ignore: cast_nullable_to_non_nullable
          : policyVersion as String,
      calculatedStudents: calculatedStudents == const $CopyWithPlaceholder()
          ? _value.calculatedStudents
          // ignore: cast_nullable_to_non_nullable
          : calculatedStudents as num,
      skippedStudents: skippedStudents == const $CopyWithPlaceholder()
          ? _value.skippedStudents
          // ignore: cast_nullable_to_non_nullable
          : skippedStudents as num,
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<FinalResultDto>,
      skipped: skipped == const $CopyWithPlaceholder()
          ? _value.skipped
          // ignore: cast_nullable_to_non_nullable
          : skipped as List<SkippedStudentDto>,
    );
  }
}

extension $CalculateFinalResultsDtoCopyWith on CalculateFinalResultsDto {
  /// Returns a callable class that can be used as follows: `instanceOfCalculateFinalResultsDto.copyWith(...)` or like so:`instanceOfCalculateFinalResultsDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CalculateFinalResultsDtoCWProxy get copyWith =>
      _$CalculateFinalResultsDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalculateFinalResultsDto _$CalculateFinalResultsDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CalculateFinalResultsDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'gradebookId',
      'gradebookVersion',
      'weightVersion',
      'policyVersion',
      'calculatedStudents',
      'skippedStudents',
      'results',
      'skipped',
    ],
  );
  final val = CalculateFinalResultsDto(
    gradebookId: $checkedConvert('gradebookId', (v) => v as num),
    gradebookVersion: $checkedConvert('gradebookVersion', (v) => v as num),
    weightVersion: $checkedConvert('weightVersion', (v) => v as String),
    policyVersion: $checkedConvert('policyVersion', (v) => v as String),
    calculatedStudents: $checkedConvert('calculatedStudents', (v) => v as num),
    skippedStudents: $checkedConvert('skippedStudents', (v) => v as num),
    results: $checkedConvert(
      'results',
      (v) => (v as List<dynamic>)
          .map((e) => FinalResultDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    skipped: $checkedConvert(
      'skipped',
      (v) => (v as List<dynamic>)
          .map((e) => SkippedStudentDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$CalculateFinalResultsDtoToJson(
  CalculateFinalResultsDto instance,
) => <String, dynamic>{
  'gradebookId': instance.gradebookId,
  'gradebookVersion': instance.gradebookVersion,
  'weightVersion': instance.weightVersion,
  'policyVersion': instance.policyVersion,
  'calculatedStudents': instance.calculatedStudents,
  'skippedStudents': instance.skippedStudents,
  'results': instance.results.map((e) => e.toJson()).toList(),
  'skipped': instance.skipped.map((e) => e.toJson()).toList(),
};
