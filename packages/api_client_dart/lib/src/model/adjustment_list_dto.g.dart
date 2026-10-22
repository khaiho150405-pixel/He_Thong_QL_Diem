// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adjustment_list_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdjustmentListDtoCWProxy {
  AdjustmentListDto items(List<AdjustmentDto> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentListDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentListDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentListDto call({List<AdjustmentDto> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdjustmentListDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdjustmentListDto.copyWith.fieldName(...)`
class _$AdjustmentListDtoCWProxyImpl implements _$AdjustmentListDtoCWProxy {
  const _$AdjustmentListDtoCWProxyImpl(this._value);

  final AdjustmentListDto _value;

  @override
  AdjustmentListDto items(List<AdjustmentDto> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentListDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentListDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentListDto call({Object? items = const $CopyWithPlaceholder()}) {
    return AdjustmentListDto(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdjustmentDto>,
    );
  }
}

extension $AdjustmentListDtoCopyWith on AdjustmentListDto {
  /// Returns a callable class that can be used as follows: `instanceOfAdjustmentListDto.copyWith(...)` or like so:`instanceOfAdjustmentListDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdjustmentListDtoCWProxy get copyWith =>
      _$AdjustmentListDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdjustmentListDto _$AdjustmentListDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdjustmentListDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = AdjustmentListDto(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => AdjustmentDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdjustmentListDtoToJson(AdjustmentListDto instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
