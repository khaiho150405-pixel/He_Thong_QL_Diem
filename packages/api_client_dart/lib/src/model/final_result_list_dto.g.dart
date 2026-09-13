// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'final_result_list_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FinalResultListDtoCWProxy {
  FinalResultListDto items(List<FinalResultDto> items);

  FinalResultListDto nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FinalResultListDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FinalResultListDto(...).copyWith(id: 12, name: "My name")
  /// ````
  FinalResultListDto call({List<FinalResultDto> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFinalResultListDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFinalResultListDto.copyWith.fieldName(...)`
class _$FinalResultListDtoCWProxyImpl implements _$FinalResultListDtoCWProxy {
  const _$FinalResultListDtoCWProxyImpl(this._value);

  final FinalResultListDto _value;

  @override
  FinalResultListDto items(List<FinalResultDto> items) => this(items: items);

  @override
  FinalResultListDto nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FinalResultListDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FinalResultListDto(...).copyWith(id: 12, name: "My name")
  /// ````
  FinalResultListDto call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return FinalResultListDto(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<FinalResultDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $FinalResultListDtoCopyWith on FinalResultListDto {
  /// Returns a callable class that can be used as follows: `instanceOfFinalResultListDto.copyWith(...)` or like so:`instanceOfFinalResultListDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FinalResultListDtoCWProxy get copyWith =>
      _$FinalResultListDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FinalResultListDto _$FinalResultListDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FinalResultListDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = FinalResultListDto(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => FinalResultDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$FinalResultListDtoToJson(FinalResultListDto instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
