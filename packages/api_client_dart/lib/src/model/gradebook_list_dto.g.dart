// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gradebook_list_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GradebookListDtoCWProxy {
  GradebookListDto items(List<GradebookDto> items);

  GradebookListDto nextCursor(num? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradebookListDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradebookListDto(...).copyWith(id: 12, name: "My name")
  /// ````
  GradebookListDto call({List<GradebookDto> items, num? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGradebookListDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGradebookListDto.copyWith.fieldName(...)`
class _$GradebookListDtoCWProxyImpl implements _$GradebookListDtoCWProxy {
  const _$GradebookListDtoCWProxyImpl(this._value);

  final GradebookListDto _value;

  @override
  GradebookListDto items(List<GradebookDto> items) => this(items: items);

  @override
  GradebookListDto nextCursor(num? nextCursor) => this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradebookListDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradebookListDto(...).copyWith(id: 12, name: "My name")
  /// ````
  GradebookListDto call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return GradebookListDto(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GradebookDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as num?,
    );
  }
}

extension $GradebookListDtoCopyWith on GradebookListDto {
  /// Returns a callable class that can be used as follows: `instanceOfGradebookListDto.copyWith(...)` or like so:`instanceOfGradebookListDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GradebookListDtoCWProxy get copyWith => _$GradebookListDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GradebookListDto _$GradebookListDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GradebookListDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = GradebookListDto(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => GradebookDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as num?),
      );
      return val;
    });

Map<String, dynamic> _$GradebookListDtoToJson(GradebookListDto instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
