// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'late_student_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LateStudentInputCWProxy {
  LateStudentInput studentId(num studentId);

  LateStudentInput reason(String reason);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LateStudentInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LateStudentInput(...).copyWith(id: 12, name: "My name")
  /// ````
  LateStudentInput call({num studentId, String reason});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLateStudentInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLateStudentInput.copyWith.fieldName(...)`
class _$LateStudentInputCWProxyImpl implements _$LateStudentInputCWProxy {
  const _$LateStudentInputCWProxyImpl(this._value);

  final LateStudentInput _value;

  @override
  LateStudentInput studentId(num studentId) => this(studentId: studentId);

  @override
  LateStudentInput reason(String reason) => this(reason: reason);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LateStudentInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LateStudentInput(...).copyWith(id: 12, name: "My name")
  /// ````
  LateStudentInput call({
    Object? studentId = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return LateStudentInput(
      studentId: studentId == const $CopyWithPlaceholder()
          ? _value.studentId
          // ignore: cast_nullable_to_non_nullable
          : studentId as num,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
    );
  }
}

extension $LateStudentInputCopyWith on LateStudentInput {
  /// Returns a callable class that can be used as follows: `instanceOfLateStudentInput.copyWith(...)` or like so:`instanceOfLateStudentInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LateStudentInputCWProxy get copyWith => _$LateStudentInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LateStudentInput _$LateStudentInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LateStudentInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['studentId', 'reason']);
      final val = LateStudentInput(
        studentId: $checkedConvert('studentId', (v) => v as num),
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$LateStudentInputToJson(LateStudentInput instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'reason': instance.reason,
    };
