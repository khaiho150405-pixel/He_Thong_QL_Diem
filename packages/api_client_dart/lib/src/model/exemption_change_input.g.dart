// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exemption_change_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ExemptionChangeInputCWProxy {
  ExemptionChangeInput cellId(String cellId);

  ExemptionChangeInput exempt(bool exempt);

  ExemptionChangeInput reason(String reason);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExemptionChangeInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExemptionChangeInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ExemptionChangeInput call({String cellId, bool exempt, String reason});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfExemptionChangeInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfExemptionChangeInput.copyWith.fieldName(...)`
class _$ExemptionChangeInputCWProxyImpl
    implements _$ExemptionChangeInputCWProxy {
  const _$ExemptionChangeInputCWProxyImpl(this._value);

  final ExemptionChangeInput _value;

  @override
  ExemptionChangeInput cellId(String cellId) => this(cellId: cellId);

  @override
  ExemptionChangeInput exempt(bool exempt) => this(exempt: exempt);

  @override
  ExemptionChangeInput reason(String reason) => this(reason: reason);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExemptionChangeInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExemptionChangeInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ExemptionChangeInput call({
    Object? cellId = const $CopyWithPlaceholder(),
    Object? exempt = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return ExemptionChangeInput(
      cellId: cellId == const $CopyWithPlaceholder()
          ? _value.cellId
          // ignore: cast_nullable_to_non_nullable
          : cellId as String,
      exempt: exempt == const $CopyWithPlaceholder()
          ? _value.exempt
          // ignore: cast_nullable_to_non_nullable
          : exempt as bool,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
    );
  }
}

extension $ExemptionChangeInputCopyWith on ExemptionChangeInput {
  /// Returns a callable class that can be used as follows: `instanceOfExemptionChangeInput.copyWith(...)` or like so:`instanceOfExemptionChangeInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ExemptionChangeInputCWProxy get copyWith =>
      _$ExemptionChangeInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExemptionChangeInput _$ExemptionChangeInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ExemptionChangeInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['cellId', 'exempt', 'reason']);
  final val = ExemptionChangeInput(
    cellId: $checkedConvert('cellId', (v) => v as String),
    exempt: $checkedConvert('exempt', (v) => v as bool),
    reason: $checkedConvert('reason', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$ExemptionChangeInputToJson(
  ExemptionChangeInput instance,
) => <String, dynamic>{
  'cellId': instance.cellId,
  'exempt': instance.exempt,
  'reason': instance.reason,
};
