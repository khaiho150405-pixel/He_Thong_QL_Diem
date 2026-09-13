// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calculate_final_results_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CalculateFinalResultsInputCWProxy {
  CalculateFinalResultsInput expectedVersion(num expectedVersion);

  CalculateFinalResultsInput reason(String reason);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CalculateFinalResultsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CalculateFinalResultsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  CalculateFinalResultsInput call({num expectedVersion, String reason});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCalculateFinalResultsInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCalculateFinalResultsInput.copyWith.fieldName(...)`
class _$CalculateFinalResultsInputCWProxyImpl
    implements _$CalculateFinalResultsInputCWProxy {
  const _$CalculateFinalResultsInputCWProxyImpl(this._value);

  final CalculateFinalResultsInput _value;

  @override
  CalculateFinalResultsInput expectedVersion(num expectedVersion) =>
      this(expectedVersion: expectedVersion);

  @override
  CalculateFinalResultsInput reason(String reason) => this(reason: reason);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CalculateFinalResultsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CalculateFinalResultsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  CalculateFinalResultsInput call({
    Object? expectedVersion = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return CalculateFinalResultsInput(
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

extension $CalculateFinalResultsInputCopyWith on CalculateFinalResultsInput {
  /// Returns a callable class that can be used as follows: `instanceOfCalculateFinalResultsInput.copyWith(...)` or like so:`instanceOfCalculateFinalResultsInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CalculateFinalResultsInputCWProxy get copyWith =>
      _$CalculateFinalResultsInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalculateFinalResultsInput _$CalculateFinalResultsInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CalculateFinalResultsInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['expectedVersion', 'reason']);
  final val = CalculateFinalResultsInput(
    expectedVersion: $checkedConvert('expectedVersion', (v) => v as num),
    reason: $checkedConvert('reason', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$CalculateFinalResultsInputToJson(
  CalculateFinalResultsInput instance,
) => <String, dynamic>{
  'expectedVersion': instance.expectedVersion,
  'reason': instance.reason,
};
