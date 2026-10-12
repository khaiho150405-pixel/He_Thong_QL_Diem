// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancel_ticket_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CancelTicketInputCWProxy {
  CancelTicketInput expectedVersion(num expectedVersion);

  CancelTicketInput reason(String reason);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CancelTicketInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CancelTicketInput(...).copyWith(id: 12, name: "My name")
  /// ````
  CancelTicketInput call({num expectedVersion, String reason});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCancelTicketInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCancelTicketInput.copyWith.fieldName(...)`
class _$CancelTicketInputCWProxyImpl implements _$CancelTicketInputCWProxy {
  const _$CancelTicketInputCWProxyImpl(this._value);

  final CancelTicketInput _value;

  @override
  CancelTicketInput expectedVersion(num expectedVersion) =>
      this(expectedVersion: expectedVersion);

  @override
  CancelTicketInput reason(String reason) => this(reason: reason);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CancelTicketInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CancelTicketInput(...).copyWith(id: 12, name: "My name")
  /// ````
  CancelTicketInput call({
    Object? expectedVersion = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return CancelTicketInput(
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

extension $CancelTicketInputCopyWith on CancelTicketInput {
  /// Returns a callable class that can be used as follows: `instanceOfCancelTicketInput.copyWith(...)` or like so:`instanceOfCancelTicketInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CancelTicketInputCWProxy get copyWith =>
      _$CancelTicketInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CancelTicketInput _$CancelTicketInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CancelTicketInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['expectedVersion', 'reason']);
      final val = CancelTicketInput(
        expectedVersion: $checkedConvert('expectedVersion', (v) => v as num),
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$CancelTicketInputToJson(CancelTicketInput instance) =>
    <String, dynamic>{
      'expectedVersion': instance.expectedVersion,
      'reason': instance.reason,
    };
