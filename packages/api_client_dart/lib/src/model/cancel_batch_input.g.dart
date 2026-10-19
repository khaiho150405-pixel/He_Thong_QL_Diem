// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancel_batch_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CancelBatchInputCWProxy {
  CancelBatchInput reason(String reason);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CancelBatchInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CancelBatchInput(...).copyWith(id: 12, name: "My name")
  /// ````
  CancelBatchInput call({String reason});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCancelBatchInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCancelBatchInput.copyWith.fieldName(...)`
class _$CancelBatchInputCWProxyImpl implements _$CancelBatchInputCWProxy {
  const _$CancelBatchInputCWProxyImpl(this._value);

  final CancelBatchInput _value;

  @override
  CancelBatchInput reason(String reason) => this(reason: reason);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CancelBatchInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CancelBatchInput(...).copyWith(id: 12, name: "My name")
  /// ````
  CancelBatchInput call({Object? reason = const $CopyWithPlaceholder()}) {
    return CancelBatchInput(
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
    );
  }
}

extension $CancelBatchInputCopyWith on CancelBatchInput {
  /// Returns a callable class that can be used as follows: `instanceOfCancelBatchInput.copyWith(...)` or like so:`instanceOfCancelBatchInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CancelBatchInputCWProxy get copyWith => _$CancelBatchInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CancelBatchInput _$CancelBatchInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CancelBatchInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason']);
      final val = CancelBatchInput(
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$CancelBatchInputToJson(CancelBatchInput instance) =>
    <String, dynamic>{'reason': instance.reason};
