// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grade_change_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GradeChangeInputCWProxy {
  GradeChangeInput cellId(String cellId);

  GradeChangeInput value(String? value);

  GradeChangeInput reason(String reason);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradeChangeInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradeChangeInput(...).copyWith(id: 12, name: "My name")
  /// ````
  GradeChangeInput call({String cellId, String? value, String reason});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGradeChangeInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGradeChangeInput.copyWith.fieldName(...)`
class _$GradeChangeInputCWProxyImpl implements _$GradeChangeInputCWProxy {
  const _$GradeChangeInputCWProxyImpl(this._value);

  final GradeChangeInput _value;

  @override
  GradeChangeInput cellId(String cellId) => this(cellId: cellId);

  @override
  GradeChangeInput value(String? value) => this(value: value);

  @override
  GradeChangeInput reason(String reason) => this(reason: reason);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradeChangeInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradeChangeInput(...).copyWith(id: 12, name: "My name")
  /// ````
  GradeChangeInput call({
    Object? cellId = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return GradeChangeInput(
      cellId: cellId == const $CopyWithPlaceholder()
          ? _value.cellId
          // ignore: cast_nullable_to_non_nullable
          : cellId as String,
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String?,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
    );
  }
}

extension $GradeChangeInputCopyWith on GradeChangeInput {
  /// Returns a callable class that can be used as follows: `instanceOfGradeChangeInput.copyWith(...)` or like so:`instanceOfGradeChangeInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GradeChangeInputCWProxy get copyWith => _$GradeChangeInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GradeChangeInput _$GradeChangeInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GradeChangeInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['cellId', 'value', 'reason']);
      final val = GradeChangeInput(
        cellId: $checkedConvert('cellId', (v) => v as String),
        value: $checkedConvert('value', (v) => v as String?),
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$GradeChangeInputToJson(GradeChangeInput instance) =>
    <String, dynamic>{
      'cellId': instance.cellId,
      'value': instance.value,
      'reason': instance.reason,
    };
