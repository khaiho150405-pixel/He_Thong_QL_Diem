// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adjustment_change_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdjustmentChangeInputCWProxy {
  AdjustmentChangeInput cellId(String cellId);

  AdjustmentChangeInput value(String? value);

  AdjustmentChangeInput exempt(bool exempt);

  AdjustmentChangeInput note(String? note);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentChangeInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentChangeInput(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentChangeInput call({
    String cellId,
    String? value,
    bool exempt,
    String? note,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdjustmentChangeInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdjustmentChangeInput.copyWith.fieldName(...)`
class _$AdjustmentChangeInputCWProxyImpl
    implements _$AdjustmentChangeInputCWProxy {
  const _$AdjustmentChangeInputCWProxyImpl(this._value);

  final AdjustmentChangeInput _value;

  @override
  AdjustmentChangeInput cellId(String cellId) => this(cellId: cellId);

  @override
  AdjustmentChangeInput value(String? value) => this(value: value);

  @override
  AdjustmentChangeInput exempt(bool exempt) => this(exempt: exempt);

  @override
  AdjustmentChangeInput note(String? note) => this(note: note);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentChangeInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentChangeInput(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentChangeInput call({
    Object? cellId = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
    Object? exempt = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return AdjustmentChangeInput(
      cellId: cellId == const $CopyWithPlaceholder()
          ? _value.cellId
          // ignore: cast_nullable_to_non_nullable
          : cellId as String,
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String?,
      exempt: exempt == const $CopyWithPlaceholder()
          ? _value.exempt
          // ignore: cast_nullable_to_non_nullable
          : exempt as bool,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $AdjustmentChangeInputCopyWith on AdjustmentChangeInput {
  /// Returns a callable class that can be used as follows: `instanceOfAdjustmentChangeInput.copyWith(...)` or like so:`instanceOfAdjustmentChangeInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdjustmentChangeInputCWProxy get copyWith =>
      _$AdjustmentChangeInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdjustmentChangeInput _$AdjustmentChangeInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdjustmentChangeInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['cellId', 'value', 'exempt', 'note']);
  final val = AdjustmentChangeInput(
    cellId: $checkedConvert('cellId', (v) => v as String),
    value: $checkedConvert('value', (v) => v as String?),
    exempt: $checkedConvert('exempt', (v) => v as bool),
    note: $checkedConvert('note', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$AdjustmentChangeInputToJson(
  AdjustmentChangeInput instance,
) => <String, dynamic>{
  'cellId': instance.cellId,
  'value': instance.value,
  'exempt': instance.exempt,
  'note': instance.note,
};
