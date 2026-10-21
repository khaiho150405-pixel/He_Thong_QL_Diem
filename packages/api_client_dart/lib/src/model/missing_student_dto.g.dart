// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'missing_student_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MissingStudentDtoCWProxy {
  MissingStudentDto studentId(num studentId);

  MissingStudentDto studentName(String studentName);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MissingStudentDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MissingStudentDto(...).copyWith(id: 12, name: "My name")
  /// ````
  MissingStudentDto call({num studentId, String studentName});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMissingStudentDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMissingStudentDto.copyWith.fieldName(...)`
class _$MissingStudentDtoCWProxyImpl implements _$MissingStudentDtoCWProxy {
  const _$MissingStudentDtoCWProxyImpl(this._value);

  final MissingStudentDto _value;

  @override
  MissingStudentDto studentId(num studentId) => this(studentId: studentId);

  @override
  MissingStudentDto studentName(String studentName) =>
      this(studentName: studentName);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MissingStudentDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MissingStudentDto(...).copyWith(id: 12, name: "My name")
  /// ````
  MissingStudentDto call({
    Object? studentId = const $CopyWithPlaceholder(),
    Object? studentName = const $CopyWithPlaceholder(),
  }) {
    return MissingStudentDto(
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

extension $MissingStudentDtoCopyWith on MissingStudentDto {
  /// Returns a callable class that can be used as follows: `instanceOfMissingStudentDto.copyWith(...)` or like so:`instanceOfMissingStudentDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MissingStudentDtoCWProxy get copyWith =>
      _$MissingStudentDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MissingStudentDto _$MissingStudentDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MissingStudentDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['studentId', 'studentName']);
      final val = MissingStudentDto(
        studentId: $checkedConvert('studentId', (v) => v as num),
        studentName: $checkedConvert('studentName', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$MissingStudentDtoToJson(MissingStudentDto instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'studentName': instance.studentName,
    };
