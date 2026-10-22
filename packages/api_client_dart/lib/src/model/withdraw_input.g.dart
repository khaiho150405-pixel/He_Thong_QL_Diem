// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdraw_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WithdrawInputCWProxy {
  WithdrawInput effectiveDate(String effectiveDate);

  WithdrawInput reason(String reason);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `WithdrawInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// WithdrawInput(...).copyWith(id: 12, name: "My name")
  /// ````
  WithdrawInput call({String effectiveDate, String reason});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfWithdrawInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfWithdrawInput.copyWith.fieldName(...)`
class _$WithdrawInputCWProxyImpl implements _$WithdrawInputCWProxy {
  const _$WithdrawInputCWProxyImpl(this._value);

  final WithdrawInput _value;

  @override
  WithdrawInput effectiveDate(String effectiveDate) =>
      this(effectiveDate: effectiveDate);

  @override
  WithdrawInput reason(String reason) => this(reason: reason);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `WithdrawInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// WithdrawInput(...).copyWith(id: 12, name: "My name")
  /// ````
  WithdrawInput call({
    Object? effectiveDate = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return WithdrawInput(
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

extension $WithdrawInputCopyWith on WithdrawInput {
  /// Returns a callable class that can be used as follows: `instanceOfWithdrawInput.copyWith(...)` or like so:`instanceOfWithdrawInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WithdrawInputCWProxy get copyWith => _$WithdrawInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WithdrawInput _$WithdrawInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WithdrawInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['effectiveDate', 'reason']);
      final val = WithdrawInput(
        effectiveDate: $checkedConvert('effectiveDate', (v) => v as String),
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$WithdrawInputToJson(WithdrawInput instance) =>
    <String, dynamic>{
      'effectiveDate': instance.effectiveDate,
      'reason': instance.reason,
    };
