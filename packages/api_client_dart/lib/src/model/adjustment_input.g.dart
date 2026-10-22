// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adjustment_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdjustmentInputCWProxy {
  AdjustmentInput expectedVersion(num expectedVersion);

  AdjustmentInput reason(String reason);

  AdjustmentInput changes(List<AdjustmentChangeInput> changes);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentInput(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentInput call({
    num expectedVersion,
    String reason,
    List<AdjustmentChangeInput> changes,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdjustmentInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdjustmentInput.copyWith.fieldName(...)`
class _$AdjustmentInputCWProxyImpl implements _$AdjustmentInputCWProxy {
  const _$AdjustmentInputCWProxyImpl(this._value);

  final AdjustmentInput _value;

  @override
  AdjustmentInput expectedVersion(num expectedVersion) =>
      this(expectedVersion: expectedVersion);

  @override
  AdjustmentInput reason(String reason) => this(reason: reason);

  @override
  AdjustmentInput changes(List<AdjustmentChangeInput> changes) =>
      this(changes: changes);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentInput(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentInput call({
    Object? expectedVersion = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? changes = const $CopyWithPlaceholder(),
  }) {
    return AdjustmentInput(
      expectedVersion: expectedVersion == const $CopyWithPlaceholder()
          ? _value.expectedVersion
          // ignore: cast_nullable_to_non_nullable
          : expectedVersion as num,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      changes: changes == const $CopyWithPlaceholder()
          ? _value.changes
          // ignore: cast_nullable_to_non_nullable
          : changes as List<AdjustmentChangeInput>,
    );
  }
}

extension $AdjustmentInputCopyWith on AdjustmentInput {
  /// Returns a callable class that can be used as follows: `instanceOfAdjustmentInput.copyWith(...)` or like so:`instanceOfAdjustmentInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdjustmentInputCWProxy get copyWith => _$AdjustmentInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdjustmentInput _$AdjustmentInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdjustmentInput', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['expectedVersion', 'reason', 'changes'],
      );
      final val = AdjustmentInput(
        expectedVersion: $checkedConvert('expectedVersion', (v) => v as num),
        reason: $checkedConvert('reason', (v) => v as String),
        changes: $checkedConvert(
          'changes',
          (v) => (v as List<dynamic>)
              .map(
                (e) =>
                    AdjustmentChangeInput.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdjustmentInputToJson(AdjustmentInput instance) =>
    <String, dynamic>{
      'expectedVersion': instance.expectedVersion,
      'reason': instance.reason,
      'changes': instance.changes.map((e) => e.toJson()).toList(),
    };
