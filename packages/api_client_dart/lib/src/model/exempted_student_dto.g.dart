// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exempted_student_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ExemptedStudentDtoCWProxy {
  ExemptedStudentDto studentId(num studentId);

  ExemptedStudentDto studentName(String studentName);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExemptedStudentDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExemptedStudentDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ExemptedStudentDto call({num studentId, String studentName});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfExemptedStudentDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfExemptedStudentDto.copyWith.fieldName(...)`
class _$ExemptedStudentDtoCWProxyImpl implements _$ExemptedStudentDtoCWProxy {
  const _$ExemptedStudentDtoCWProxyImpl(this._value);

  final ExemptedStudentDto _value;

  @override
  ExemptedStudentDto studentId(num studentId) => this(studentId: studentId);

  @override
  ExemptedStudentDto studentName(String studentName) =>
      this(studentName: studentName);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExemptedStudentDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExemptedStudentDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ExemptedStudentDto call({
    Object? studentId = const $CopyWithPlaceholder(),
    Object? studentName = const $CopyWithPlaceholder(),
  }) {
    return ExemptedStudentDto(
      studentId: studentId == const $CopyWithPlaceholder()
          ? _value.studentId
          // ignore: cast_nullable_to_non_nullable
          : studentId as num,
      studentName: studentName == const $CopyWithPlaceholder()
          ? _value.studentName
          // ignore: cast_nullable_to_non_nullable
          : studentName as String,
    );
  }
}

extension $ExemptedStudentDtoCopyWith on ExemptedStudentDto {
  /// Returns a callable class that can be used as follows: `instanceOfExemptedStudentDto.copyWith(...)` or like so:`instanceOfExemptedStudentDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ExemptedStudentDtoCWProxy get copyWith =>
      _$ExemptedStudentDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExemptedStudentDto _$ExemptedStudentDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ExemptedStudentDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['studentId', 'studentName']);
      final val = ExemptedStudentDto(
        studentId: $checkedConvert('studentId', (v) => v as num),
        studentName: $checkedConvert('studentName', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ExemptedStudentDtoToJson(ExemptedStudentDto instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'studentName': instance.studentName,
    };
