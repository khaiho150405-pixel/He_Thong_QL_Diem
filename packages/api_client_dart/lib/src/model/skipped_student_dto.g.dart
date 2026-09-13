// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skipped_student_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SkippedStudentDtoCWProxy {
  SkippedStudentDto studentId(num studentId);

  SkippedStudentDto studentName(String studentName);

  SkippedStudentDto missingComponents(
    List<MissingComponentDto> missingComponents,
  );

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SkippedStudentDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SkippedStudentDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SkippedStudentDto call({
    num studentId,
    String studentName,
    List<MissingComponentDto> missingComponents,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSkippedStudentDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSkippedStudentDto.copyWith.fieldName(...)`
class _$SkippedStudentDtoCWProxyImpl implements _$SkippedStudentDtoCWProxy {
  const _$SkippedStudentDtoCWProxyImpl(this._value);

  final SkippedStudentDto _value;

  @override
  SkippedStudentDto studentId(num studentId) => this(studentId: studentId);

  @override
  SkippedStudentDto studentName(String studentName) =>
      this(studentName: studentName);

  @override
  SkippedStudentDto missingComponents(
    List<MissingComponentDto> missingComponents,
  ) => this(missingComponents: missingComponents);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SkippedStudentDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SkippedStudentDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SkippedStudentDto call({
    Object? studentId = const $CopyWithPlaceholder(),
    Object? studentName = const $CopyWithPlaceholder(),
    Object? missingComponents = const $CopyWithPlaceholder(),
  }) {
    return SkippedStudentDto(
      studentId: studentId == const $CopyWithPlaceholder()
          ? _value.studentId
          // ignore: cast_nullable_to_non_nullable
          : studentId as num,
      studentName: studentName == const $CopyWithPlaceholder()
          ? _value.studentName
          // ignore: cast_nullable_to_non_nullable
          : studentName as String,
      missingComponents: missingComponents == const $CopyWithPlaceholder()
          ? _value.missingComponents
          // ignore: cast_nullable_to_non_nullable
          : missingComponents as List<MissingComponentDto>,
    );
  }
}

extension $SkippedStudentDtoCopyWith on SkippedStudentDto {
  /// Returns a callable class that can be used as follows: `instanceOfSkippedStudentDto.copyWith(...)` or like so:`instanceOfSkippedStudentDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SkippedStudentDtoCWProxy get copyWith =>
      _$SkippedStudentDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkippedStudentDto _$SkippedStudentDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SkippedStudentDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['studentId', 'studentName', 'missingComponents'],
      );
      final val = SkippedStudentDto(
        studentId: $checkedConvert('studentId', (v) => v as num),
        studentName: $checkedConvert('studentName', (v) => v as String),
        missingComponents: $checkedConvert(
          'missingComponents',
          (v) => (v as List<dynamic>)
              .map(
                (e) => MissingComponentDto.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SkippedStudentDtoToJson(SkippedStudentDto instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'studentName': instance.studentName,
      'missingComponents': instance.missingComponents
          .map((e) => e.toJson())
          .toList(),
    };
