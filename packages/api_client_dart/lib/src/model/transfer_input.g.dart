// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TransferInputCWProxy {
  TransferInput targetClassId(num targetClassId);

  TransferInput effectiveDate(String effectiveDate);

  TransferInput reason(String reason);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TransferInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TransferInput(...).copyWith(id: 12, name: "My name")
  /// ````
  TransferInput call({num targetClassId, String effectiveDate, String reason});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTransferInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTransferInput.copyWith.fieldName(...)`
class _$TransferInputCWProxyImpl implements _$TransferInputCWProxy {
  const _$TransferInputCWProxyImpl(this._value);

  final TransferInput _value;

  @override
  TransferInput targetClassId(num targetClassId) =>
      this(targetClassId: targetClassId);

  @override
  TransferInput effectiveDate(String effectiveDate) =>
      this(effectiveDate: effectiveDate);

  @override
  TransferInput reason(String reason) => this(reason: reason);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TransferInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TransferInput(...).copyWith(id: 12, name: "My name")
  /// ````
  TransferInput call({
    Object? targetClassId = const $CopyWithPlaceholder(),
    Object? effectiveDate = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return TransferInput(
      targetClassId: targetClassId == const $CopyWithPlaceholder()
          ? _value.targetClassId
          // ignore: cast_nullable_to_non_nullable
          : targetClassId as num,
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

extension $TransferInputCopyWith on TransferInput {
  /// Returns a callable class that can be used as follows: `instanceOfTransferInput.copyWith(...)` or like so:`instanceOfTransferInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TransferInputCWProxy get copyWith => _$TransferInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferInput _$TransferInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TransferInput', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['targetClassId', 'effectiveDate', 'reason'],
      );
      final val = TransferInput(
        targetClassId: $checkedConvert('targetClassId', (v) => v as num),
        effectiveDate: $checkedConvert('effectiveDate', (v) => v as String),
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$TransferInputToJson(TransferInput instance) =>
    <String, dynamic>{
      'targetClassId': instance.targetClassId,
      'effectiveDate': instance.effectiveDate,
      'reason': instance.reason,
    };
