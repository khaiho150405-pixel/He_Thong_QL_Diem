// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reenroll_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReenrollInputCWProxy {
  ReenrollInput classId(num classId);

  ReenrollInput effectiveDate(String effectiveDate);

  ReenrollInput reason(String reason);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReenrollInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReenrollInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ReenrollInput call({num classId, String effectiveDate, String reason});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReenrollInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReenrollInput.copyWith.fieldName(...)`
class _$ReenrollInputCWProxyImpl implements _$ReenrollInputCWProxy {
  const _$ReenrollInputCWProxyImpl(this._value);

  final ReenrollInput _value;

  @override
  ReenrollInput classId(num classId) => this(classId: classId);

  @override
  ReenrollInput effectiveDate(String effectiveDate) =>
      this(effectiveDate: effectiveDate);

  @override
  ReenrollInput reason(String reason) => this(reason: reason);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReenrollInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReenrollInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ReenrollInput call({
    Object? classId = const $CopyWithPlaceholder(),
    Object? effectiveDate = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return ReenrollInput(
      classId: classId == const $CopyWithPlaceholder()
          ? _value.classId
          // ignore: cast_nullable_to_non_nullable
          : classId as num,
      effectiveDate: effectiveDate == const $CopyWithPlaceholder()
          ? _value.effectiveDate
          // ignore: cast_nullable_to_non_nullable
          : effectiveDate as String,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
    );
  }
}

extension $ReenrollInputCopyWith on ReenrollInput {
  /// Returns a callable class that can be used as follows: `instanceOfReenrollInput.copyWith(...)` or like so:`instanceOfReenrollInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReenrollInputCWProxy get copyWith => _$ReenrollInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReenrollInput _$ReenrollInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReenrollInput', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['classId', 'effectiveDate', 'reason'],
      );
      final val = ReenrollInput(
        classId: $checkedConvert('classId', (v) => v as num),
        effectiveDate: $checkedConvert('effectiveDate', (v) => v as String),
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ReenrollInputToJson(ReenrollInput instance) =>
    <String, dynamic>{
      'classId': instance.classId,
      'effectiveDate': instance.effectiveDate,
      'reason': instance.reason,
    };
