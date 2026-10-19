// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mapping_item_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MappingItemDtoCWProxy {
  MappingItemDto templateColumnIndex(num templateColumnIndex);

  MappingItemDto key(String key);

  MappingItemDto group(MappingItemDtoGroupEnum group);

  MappingItemDto order(num order);

  MappingItemDto channels(MappingItemDtoChannelsEnum channels);

  MappingItemDto componentId(num? componentId);

  MappingItemDto componentName(String? componentName);

  MappingItemDto locked(bool locked);

  MappingItemDto pending(bool pending);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MappingItemDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MappingItemDto(...).copyWith(id: 12, name: "My name")
  /// ````
  MappingItemDto call({
    num templateColumnIndex,
    String key,
    MappingItemDtoGroupEnum group,
    num order,
    MappingItemDtoChannelsEnum channels,
    num? componentId,
    String? componentName,
    bool locked,
    bool pending,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMappingItemDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMappingItemDto.copyWith.fieldName(...)`
class _$MappingItemDtoCWProxyImpl implements _$MappingItemDtoCWProxy {
  const _$MappingItemDtoCWProxyImpl(this._value);

  final MappingItemDto _value;

  @override
  MappingItemDto templateColumnIndex(num templateColumnIndex) =>
      this(templateColumnIndex: templateColumnIndex);

  @override
  MappingItemDto key(String key) => this(key: key);

  @override
  MappingItemDto group(MappingItemDtoGroupEnum group) => this(group: group);

  @override
  MappingItemDto order(num order) => this(order: order);

  @override
  MappingItemDto channels(MappingItemDtoChannelsEnum channels) =>
      this(channels: channels);

  @override
  MappingItemDto componentId(num? componentId) =>
      this(componentId: componentId);

  @override
  MappingItemDto componentName(String? componentName) =>
      this(componentName: componentName);

  @override
  MappingItemDto locked(bool locked) => this(locked: locked);

  @override
  MappingItemDto pending(bool pending) => this(pending: pending);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MappingItemDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MappingItemDto(...).copyWith(id: 12, name: "My name")
  /// ````
  MappingItemDto call({
    Object? templateColumnIndex = const $CopyWithPlaceholder(),
    Object? key = const $CopyWithPlaceholder(),
    Object? group = const $CopyWithPlaceholder(),
    Object? order = const $CopyWithPlaceholder(),
    Object? channels = const $CopyWithPlaceholder(),
    Object? componentId = const $CopyWithPlaceholder(),
    Object? componentName = const $CopyWithPlaceholder(),
    Object? locked = const $CopyWithPlaceholder(),
    Object? pending = const $CopyWithPlaceholder(),
  }) {
    return MappingItemDto(
      templateColumnIndex: templateColumnIndex == const $CopyWithPlaceholder()
          ? _value.templateColumnIndex
          // ignore: cast_nullable_to_non_nullable
          : templateColumnIndex as num,
      key: key == const $CopyWithPlaceholder()
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
      group: group == const $CopyWithPlaceholder()
          ? _value.group
          // ignore: cast_nullable_to_non_nullable
          : group as MappingItemDtoGroupEnum,
      order: order == const $CopyWithPlaceholder()
          ? _value.order
          // ignore: cast_nullable_to_non_nullable
          : order as num,
      channels: channels == const $CopyWithPlaceholder()
          ? _value.channels
          // ignore: cast_nullable_to_non_nullable
          : channels as MappingItemDtoChannelsEnum,
      componentId: componentId == const $CopyWithPlaceholder()
          ? _value.componentId
          // ignore: cast_nullable_to_non_nullable
          : componentId as num?,
      componentName: componentName == const $CopyWithPlaceholder()
          ? _value.componentName
          // ignore: cast_nullable_to_non_nullable
          : componentName as String?,
      locked: locked == const $CopyWithPlaceholder()
          ? _value.locked
          // ignore: cast_nullable_to_non_nullable
          : locked as bool,
      pending: pending == const $CopyWithPlaceholder()
          ? _value.pending
          // ignore: cast_nullable_to_non_nullable
          : pending as bool,
    );
  }
}

extension $MappingItemDtoCopyWith on MappingItemDto {
  /// Returns a callable class that can be used as follows: `instanceOfMappingItemDto.copyWith(...)` or like so:`instanceOfMappingItemDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MappingItemDtoCWProxy get copyWith => _$MappingItemDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MappingItemDto _$MappingItemDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MappingItemDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'templateColumnIndex',
          'key',
          'group',
          'order',
          'channels',
          'componentId',
          'componentName',
          'locked',
          'pending',
        ],
      );
      final val = MappingItemDto(
        templateColumnIndex: $checkedConvert(
          'templateColumnIndex',
          (v) => v as num,
        ),
        key: $checkedConvert('key', (v) => v as String),
        group: $checkedConvert(
          'group',
          (v) => $enumDecode(_$MappingItemDtoGroupEnumEnumMap, v),
        ),
        order: $checkedConvert('order', (v) => v as num),
        channels: $checkedConvert(
          'channels',
          (v) => $enumDecode(_$MappingItemDtoChannelsEnumEnumMap, v),
        ),
        componentId: $checkedConvert('componentId', (v) => v as num?),
        componentName: $checkedConvert('componentName', (v) => v as String?),
        locked: $checkedConvert('locked', (v) => v as bool),
        pending: $checkedConvert('pending', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$MappingItemDtoToJson(MappingItemDto instance) =>
    <String, dynamic>{
      'templateColumnIndex': instance.templateColumnIndex,
      'key': instance.key,
      'group': _$MappingItemDtoGroupEnumEnumMap[instance.group]!,
      'order': instance.order,
      'channels': _$MappingItemDtoChannelsEnumEnumMap[instance.channels]!,
      'componentId': instance.componentId,
      'componentName': instance.componentName,
      'locked': instance.locked,
      'pending': instance.pending,
    };

const _$MappingItemDtoGroupEnumEnumMap = {
  MappingItemDtoGroupEnum.TX: 'TX',
  MappingItemDtoGroupEnum.GK: 'GK',
  MappingItemDtoGroupEnum.CK: 'CK',
};

const _$MappingItemDtoChannelsEnumEnumMap = {
  MappingItemDtoChannelsEnum.SO: 'SO',
  MappingItemDtoChannelsEnum.SO_CHU: 'SO_CHU',
};
