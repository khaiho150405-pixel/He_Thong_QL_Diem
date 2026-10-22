// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adjustment_reject_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdjustmentRejectInputCWProxy {
  AdjustmentRejectInput expectedVersion(num expectedVersion);

  AdjustmentRejectInput reason(String reason);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentRejectInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentRejectInput(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentRejectInput call({num expectedVersion, String reason});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdjustmentRejectInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdjustmentRejectInput.copyWith.fieldName(...)`
class _$AdjustmentRejectInputCWProxyImpl
    implements _$AdjustmentRejectInputCWProxy {
  const _$AdjustmentRejectInputCWProxyImpl(this._value);

  final AdjustmentRejectInput _value;

  @override
  AdjustmentRejectInput expectedVersion(num expectedVersion) =>
      this(expectedVersion: expectedVersion);

  @override
  AdjustmentRejectInput reason(String reason) => this(reason: reason);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentRejectInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentRejectInput(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentRejectInput call({
    Object? expectedVersion = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return AdjustmentRejectInput(
      expectedVersion: expectedVersion == const $CopyWithPlaceholder()
          ? _value.expectedVersion
          // ignore: cast_nullable_to_non_nullable
          : expectedVersion as num,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
    );
  }
}

extension $AdjustmentRejectInputCopyWith on AdjustmentRejectInput {
  /// Returns a callable class that can be used as follows: `instanceOfAdjustmentRejectInput.copyWith(...)` or like so:`instanceOfAdjustmentRejectInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdjustmentRejectInputCWProxy get copyWith =>
      _$AdjustmentRejectInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdjustmentRejectInput _$AdjustmentRejectInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdjustmentRejectInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['expectedVersion', 'reason']);
  final val = AdjustmentRejectInput(
    expectedVersion: $checkedConvert('expectedVersion', (v) => v as num),
    reason: $checkedConvert('reason', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$AdjustmentRejectInputToJson(
  AdjustmentRejectInput instance,
) => <String, dynamic>{
  'expectedVersion': instance.expectedVersion,
  'reason': instance.reason,
};
