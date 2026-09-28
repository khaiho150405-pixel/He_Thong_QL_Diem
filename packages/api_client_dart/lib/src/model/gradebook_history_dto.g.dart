// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gradebook_history_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GradebookHistoryDtoCWProxy {
  GradebookHistoryDto items(List<GradebookHistoryEntryDto> items);

  GradebookHistoryDto nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradebookHistoryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradebookHistoryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  GradebookHistoryDto call({
    List<GradebookHistoryEntryDto> items,
    String? nextCursor,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGradebookHistoryDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGradebookHistoryDto.copyWith.fieldName(...)`
class _$GradebookHistoryDtoCWProxyImpl implements _$GradebookHistoryDtoCWProxy {
  const _$GradebookHistoryDtoCWProxyImpl(this._value);

  final GradebookHistoryDto _value;

  @override
  GradebookHistoryDto items(List<GradebookHistoryEntryDto> items) =>
      this(items: items);

  @override
  GradebookHistoryDto nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradebookHistoryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradebookHistoryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  GradebookHistoryDto call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return GradebookHistoryDto(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GradebookHistoryEntryDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $GradebookHistoryDtoCopyWith on GradebookHistoryDto {
  /// Returns a callable class that can be used as follows: `instanceOfGradebookHistoryDto.copyWith(...)` or like so:`instanceOfGradebookHistoryDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GradebookHistoryDtoCWProxy get copyWith =>
      _$GradebookHistoryDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GradebookHistoryDto _$GradebookHistoryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GradebookHistoryDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = GradebookHistoryDto(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => GradebookHistoryEntryDto.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$GradebookHistoryDtoToJson(
  GradebookHistoryDto instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': instance.nextCursor,
};
