// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adjustment_version_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdjustmentVersionInputCWProxy {
  AdjustmentVersionInput expectedVersion(num expectedVersion);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentVersionInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentVersionInput(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentVersionInput call({num expectedVersion});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdjustmentVersionInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdjustmentVersionInput.copyWith.fieldName(...)`
class _$AdjustmentVersionInputCWProxyImpl
    implements _$AdjustmentVersionInputCWProxy {
  const _$AdjustmentVersionInputCWProxyImpl(this._value);

  final AdjustmentVersionInput _value;

  @override
  AdjustmentVersionInput expectedVersion(num expectedVersion) =>
      this(expectedVersion: expectedVersion);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentVersionInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentVersionInput(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentVersionInput call({
    Object? expectedVersion = const $CopyWithPlaceholder(),
  }) {
    return AdjustmentVersionInput(
      expectedVersion: expectedVersion == const $CopyWithPlaceholder()
          ? _value.expectedVersion
          // ignore: cast_nullable_to_non_nullable
          : expectedVersion as num,
    );
  }
}

extension $AdjustmentVersionInputCopyWith on AdjustmentVersionInput {
  /// Returns a callable class that can be used as follows: `instanceOfAdjustmentVersionInput.copyWith(...)` or like so:`instanceOfAdjustmentVersionInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdjustmentVersionInputCWProxy get copyWith =>
      _$AdjustmentVersionInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdjustmentVersionInput _$AdjustmentVersionInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdjustmentVersionInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['expectedVersion']);
  final val = AdjustmentVersionInput(
    expectedVersion: $checkedConvert('expectedVersion', (v) => v as num),
  );
  return val;
});

Map<String, dynamic> _$AdjustmentVersionInputToJson(
  AdjustmentVersionInput instance,
) => <String, dynamic>{'expectedVersion': instance.expectedVersion};
