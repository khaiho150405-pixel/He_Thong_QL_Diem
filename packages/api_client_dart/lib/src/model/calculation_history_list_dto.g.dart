// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calculation_history_list_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CalculationHistoryListDtoCWProxy {
  CalculationHistoryListDto items(List<CalculationHistoryDto> items);

  CalculationHistoryListDto nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CalculationHistoryListDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CalculationHistoryListDto(...).copyWith(id: 12, name: "My name")
  /// ````
  CalculationHistoryListDto call({
    List<CalculationHistoryDto> items,
    String? nextCursor,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCalculationHistoryListDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCalculationHistoryListDto.copyWith.fieldName(...)`
class _$CalculationHistoryListDtoCWProxyImpl
    implements _$CalculationHistoryListDtoCWProxy {
  const _$CalculationHistoryListDtoCWProxyImpl(this._value);

  final CalculationHistoryListDto _value;

  @override
  CalculationHistoryListDto items(List<CalculationHistoryDto> items) =>
      this(items: items);

  @override
  CalculationHistoryListDto nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CalculationHistoryListDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CalculationHistoryListDto(...).copyWith(id: 12, name: "My name")
  /// ````
  CalculationHistoryListDto call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return CalculationHistoryListDto(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<CalculationHistoryDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $CalculationHistoryListDtoCopyWith on CalculationHistoryListDto {
  /// Returns a callable class that can be used as follows: `instanceOfCalculationHistoryListDto.copyWith(...)` or like so:`instanceOfCalculationHistoryListDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CalculationHistoryListDtoCWProxy get copyWith =>
      _$CalculationHistoryListDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalculationHistoryListDto _$CalculationHistoryListDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CalculationHistoryListDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
  final val = CalculationHistoryListDto(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => CalculationHistoryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$CalculationHistoryListDtoToJson(
  CalculationHistoryListDto instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': instance.nextCursor,
};
