// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adjustment_person_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdjustmentPersonDtoCWProxy {
  AdjustmentPersonDto id(num id);

  AdjustmentPersonDto name(String name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentPersonDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentPersonDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentPersonDto call({num id, String name});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdjustmentPersonDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdjustmentPersonDto.copyWith.fieldName(...)`
class _$AdjustmentPersonDtoCWProxyImpl implements _$AdjustmentPersonDtoCWProxy {
  const _$AdjustmentPersonDtoCWProxyImpl(this._value);

  final AdjustmentPersonDto _value;

  @override
  AdjustmentPersonDto id(num id) => this(id: id);

  @override
  AdjustmentPersonDto name(String name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentPersonDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentPersonDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentPersonDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return AdjustmentPersonDto(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as num,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $AdjustmentPersonDtoCopyWith on AdjustmentPersonDto {
  /// Returns a callable class that can be used as follows: `instanceOfAdjustmentPersonDto.copyWith(...)` or like so:`instanceOfAdjustmentPersonDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdjustmentPersonDtoCWProxy get copyWith =>
      _$AdjustmentPersonDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdjustmentPersonDto _$AdjustmentPersonDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdjustmentPersonDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'name']);
      final val = AdjustmentPersonDto(
        id: $checkedConvert('id', (v) => v as num),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AdjustmentPersonDtoToJson(
  AdjustmentPersonDto instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};
