// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mapping_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MappingDtoCWProxy {
  MappingDto gradebookId(num gradebookId);

  MappingDto templateId(num templateId);

  MappingDto items(List<MappingItemDto> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MappingDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MappingDto(...).copyWith(id: 12, name: "My name")
  /// ````
  MappingDto call({
    num gradebookId,
    num templateId,
    List<MappingItemDto> items,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMappingDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMappingDto.copyWith.fieldName(...)`
class _$MappingDtoCWProxyImpl implements _$MappingDtoCWProxy {
  const _$MappingDtoCWProxyImpl(this._value);

  final MappingDto _value;

  @override
  MappingDto gradebookId(num gradebookId) => this(gradebookId: gradebookId);

  @override
  MappingDto templateId(num templateId) => this(templateId: templateId);

  @override
  MappingDto items(List<MappingItemDto> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MappingDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MappingDto(...).copyWith(id: 12, name: "My name")
  /// ````
  MappingDto call({
    Object? gradebookId = const $CopyWithPlaceholder(),
    Object? templateId = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return MappingDto(
      gradebookId: gradebookId == const $CopyWithPlaceholder()
          ? _value.gradebookId
          // ignore: cast_nullable_to_non_nullable
          : gradebookId as num,
      templateId: templateId == const $CopyWithPlaceholder()
          ? _value.templateId
          // ignore: cast_nullable_to_non_nullable
          : templateId as num,
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<MappingItemDto>,
    );
  }
}

extension $MappingDtoCopyWith on MappingDto {
  /// Returns a callable class that can be used as follows: `instanceOfMappingDto.copyWith(...)` or like so:`instanceOfMappingDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MappingDtoCWProxy get copyWith => _$MappingDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MappingDto _$MappingDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MappingDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['gradebookId', 'templateId', 'items'],
      );
      final val = MappingDto(
        gradebookId: $checkedConvert('gradebookId', (v) => v as num),
        templateId: $checkedConvert('templateId', (v) => v as num),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => MappingItemDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$MappingDtoToJson(MappingDto instance) =>
    <String, dynamic>{
      'gradebookId': instance.gradebookId,
      'templateId': instance.templateId,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };
