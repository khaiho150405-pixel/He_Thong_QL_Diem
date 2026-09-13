// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'missing_component_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MissingComponentDtoCWProxy {
  MissingComponentDto componentId(num componentId);

  MissingComponentDto name(String name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MissingComponentDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MissingComponentDto(...).copyWith(id: 12, name: "My name")
  /// ````
  MissingComponentDto call({num componentId, String name});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMissingComponentDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMissingComponentDto.copyWith.fieldName(...)`
class _$MissingComponentDtoCWProxyImpl implements _$MissingComponentDtoCWProxy {
  const _$MissingComponentDtoCWProxyImpl(this._value);

  final MissingComponentDto _value;

  @override
  MissingComponentDto componentId(num componentId) =>
      this(componentId: componentId);

  @override
  MissingComponentDto name(String name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MissingComponentDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MissingComponentDto(...).copyWith(id: 12, name: "My name")
  /// ````
  MissingComponentDto call({
    Object? componentId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return MissingComponentDto(
      componentId: componentId == const $CopyWithPlaceholder()
          ? _value.componentId
          // ignore: cast_nullable_to_non_nullable
          : componentId as num,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $MissingComponentDtoCopyWith on MissingComponentDto {
  /// Returns a callable class that can be used as follows: `instanceOfMissingComponentDto.copyWith(...)` or like so:`instanceOfMissingComponentDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MissingComponentDtoCWProxy get copyWith =>
      _$MissingComponentDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MissingComponentDto _$MissingComponentDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MissingComponentDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['componentId', 'name']);
      final val = MissingComponentDto(
        componentId: $checkedConvert('componentId', (v) => v as num),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$MissingComponentDtoToJson(
  MissingComponentDto instance,
) => <String, dynamic>{
  'componentId': instance.componentId,
  'name': instance.name,
};
