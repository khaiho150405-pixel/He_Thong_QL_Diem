// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_list_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TimetableListDtoCWProxy {
  TimetableListDto items(List<TimetableItemDto> items);

  TimetableListDto total(num total);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TimetableListDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TimetableListDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TimetableListDto call({List<TimetableItemDto> items, num total});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTimetableListDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTimetableListDto.copyWith.fieldName(...)`
class _$TimetableListDtoCWProxyImpl implements _$TimetableListDtoCWProxy {
  const _$TimetableListDtoCWProxyImpl(this._value);

  final TimetableListDto _value;

  @override
  TimetableListDto items(List<TimetableItemDto> items) => this(items: items);

  @override
  TimetableListDto total(num total) => this(total: total);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TimetableListDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TimetableListDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TimetableListDto call({
    Object? items = const $CopyWithPlaceholder(),
    Object? total = const $CopyWithPlaceholder(),
  }) {
    return TimetableListDto(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<TimetableItemDto>,
      total: total == const $CopyWithPlaceholder()
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as num,
    );
  }
}

extension $TimetableListDtoCopyWith on TimetableListDto {
  /// Returns a callable class that can be used as follows: `instanceOfTimetableListDto.copyWith(...)` or like so:`instanceOfTimetableListDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TimetableListDtoCWProxy get copyWith => _$TimetableListDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimetableListDto _$TimetableListDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TimetableListDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'total']);
      final val = TimetableListDto(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => TimetableItemDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        total: $checkedConvert('total', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$TimetableListDtoToJson(TimetableListDto instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
