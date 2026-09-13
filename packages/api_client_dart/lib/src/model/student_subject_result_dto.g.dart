// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_subject_result_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StudentSubjectResultDtoCWProxy {
  StudentSubjectResultDto gradebookId(num gradebookId);

  StudentSubjectResultDto subjectId(num subjectId);

  StudentSubjectResultDto subjectName(String subjectName);

  StudentSubjectResultDto termId(num termId);

  StudentSubjectResultDto termName(String termName);

  StudentSubjectResultDto components(
    List<StudentApprovedComponentDto> components,
  );

  StudentSubjectResultDto finalScore(String? finalScore);

  StudentSubjectResultDto classification(String? classification);

  StudentSubjectResultDto calculatedAt(DateTime? calculatedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentSubjectResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentSubjectResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentSubjectResultDto call({
    num gradebookId,
    num subjectId,
    String subjectName,
    num termId,
    String termName,
    List<StudentApprovedComponentDto> components,
    String? finalScore,
    String? classification,
    DateTime? calculatedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStudentSubjectResultDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStudentSubjectResultDto.copyWith.fieldName(...)`
class _$StudentSubjectResultDtoCWProxyImpl
    implements _$StudentSubjectResultDtoCWProxy {
  const _$StudentSubjectResultDtoCWProxyImpl(this._value);

  final StudentSubjectResultDto _value;

  @override
  StudentSubjectResultDto gradebookId(num gradebookId) =>
      this(gradebookId: gradebookId);

  @override
  StudentSubjectResultDto subjectId(num subjectId) =>
      this(subjectId: subjectId);

  @override
  StudentSubjectResultDto subjectName(String subjectName) =>
      this(subjectName: subjectName);

  @override
  StudentSubjectResultDto termId(num termId) => this(termId: termId);

  @override
  StudentSubjectResultDto termName(String termName) => this(termName: termName);

  @override
  StudentSubjectResultDto components(
    List<StudentApprovedComponentDto> components,
  ) => this(components: components);

  @override
  StudentSubjectResultDto finalScore(String? finalScore) =>
      this(finalScore: finalScore);

  @override
  StudentSubjectResultDto classification(String? classification) =>
      this(classification: classification);

  @override
  StudentSubjectResultDto calculatedAt(DateTime? calculatedAt) =>
      this(calculatedAt: calculatedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentSubjectResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentSubjectResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentSubjectResultDto call({
    Object? gradebookId = const $CopyWithPlaceholder(),
    Object? subjectId = const $CopyWithPlaceholder(),
    Object? subjectName = const $CopyWithPlaceholder(),
    Object? termId = const $CopyWithPlaceholder(),
    Object? termName = const $CopyWithPlaceholder(),
    Object? components = const $CopyWithPlaceholder(),
    Object? finalScore = const $CopyWithPlaceholder(),
    Object? classification = const $CopyWithPlaceholder(),
    Object? calculatedAt = const $CopyWithPlaceholder(),
  }) {
    return StudentSubjectResultDto(
      gradebookId: gradebookId == const $CopyWithPlaceholder()
          ? _value.gradebookId
          // ignore: cast_nullable_to_non_nullable
          : gradebookId as num,
      subjectId: subjectId == const $CopyWithPlaceholder()
          ? _value.subjectId
          // ignore: cast_nullable_to_non_nullable
          : subjectId as num,
      subjectName: subjectName == const $CopyWithPlaceholder()
          ? _value.subjectName
          // ignore: cast_nullable_to_non_nullable
          : subjectName as String,
      termId: termId == const $CopyWithPlaceholder()
          ? _value.termId
          // ignore: cast_nullable_to_non_nullable
          : termId as num,
      termName: termName == const $CopyWithPlaceholder()
          ? _value.termName
          // ignore: cast_nullable_to_non_nullable
          : termName as String,
      components: components == const $CopyWithPlaceholder()
          ? _value.components
          // ignore: cast_nullable_to_non_nullable
          : components as List<StudentApprovedComponentDto>,
      finalScore: finalScore == const $CopyWithPlaceholder()
          ? _value.finalScore
          // ignore: cast_nullable_to_non_nullable
          : finalScore as String?,
      classification: classification == const $CopyWithPlaceholder()
          ? _value.classification
          // ignore: cast_nullable_to_non_nullable
          : classification as String?,
      calculatedAt: calculatedAt == const $CopyWithPlaceholder()
          ? _value.calculatedAt
          // ignore: cast_nullable_to_non_nullable
          : calculatedAt as DateTime?,
    );
  }
}

extension $StudentSubjectResultDtoCopyWith on StudentSubjectResultDto {
  /// Returns a callable class that can be used as follows: `instanceOfStudentSubjectResultDto.copyWith(...)` or like so:`instanceOfStudentSubjectResultDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StudentSubjectResultDtoCWProxy get copyWith =>
      _$StudentSubjectResultDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentSubjectResultDto _$StudentSubjectResultDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StudentSubjectResultDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'gradebookId',
      'subjectId',
      'subjectName',
      'termId',
      'termName',
      'components',
      'finalScore',
      'classification',
      'calculatedAt',
    ],
  );
  final val = StudentSubjectResultDto(
    gradebookId: $checkedConvert('gradebookId', (v) => v as num),
    subjectId: $checkedConvert('subjectId', (v) => v as num),
    subjectName: $checkedConvert('subjectName', (v) => v as String),
    termId: $checkedConvert('termId', (v) => v as num),
    termName: $checkedConvert('termName', (v) => v as String),
    components: $checkedConvert(
      'components',
      (v) => (v as List<dynamic>)
          .map(
            (e) =>
                StudentApprovedComponentDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    finalScore: $checkedConvert('finalScore', (v) => v as String?),
    classification: $checkedConvert('classification', (v) => v as String?),
    calculatedAt: $checkedConvert(
      'calculatedAt',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
  );
  return val;
});

Map<String, dynamic> _$StudentSubjectResultDtoToJson(
  StudentSubjectResultDto instance,
) => <String, dynamic>{
  'gradebookId': instance.gradebookId,
  'subjectId': instance.subjectId,
  'subjectName': instance.subjectName,
  'termId': instance.termId,
  'termName': instance.termName,
  'components': instance.components.map((e) => e.toJson()).toList(),
  'finalScore': instance.finalScore,
  'classification': instance.classification,
  'calculatedAt': instance.calculatedAt?.toIso8601String(),
};
