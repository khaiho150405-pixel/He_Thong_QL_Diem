// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adjustment_page_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdjustmentPageDtoCWProxy {
  AdjustmentPageDto items(List<AdjustmentDto> items);

  AdjustmentPageDto nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentPageDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentPageDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentPageDto call({List<AdjustmentDto> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdjustmentPageDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdjustmentPageDto.copyWith.fieldName(...)`
class _$AdjustmentPageDtoCWProxyImpl implements _$AdjustmentPageDtoCWProxy {
  const _$AdjustmentPageDtoCWProxyImpl(this._value);

  final AdjustmentPageDto _value;

  @override
  AdjustmentPageDto items(List<AdjustmentDto> items) => this(items: items);

  @override
  AdjustmentPageDto nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentPageDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentPageDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentPageDto call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return AdjustmentPageDto(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdjustmentDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $AdjustmentPageDtoCopyWith on AdjustmentPageDto {
  /// Returns a callable class that can be used as follows: `instanceOfAdjustmentPageDto.copyWith(...)` or like so:`instanceOfAdjustmentPageDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdjustmentPageDtoCWProxy get copyWith =>
      _$AdjustmentPageDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdjustmentPageDto _$AdjustmentPageDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdjustmentPageDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = AdjustmentPageDto(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => AdjustmentDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$AdjustmentPageDtoToJson(AdjustmentPageDto instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
