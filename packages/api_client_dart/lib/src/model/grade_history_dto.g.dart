// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grade_history_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GradeHistoryDtoCWProxy {
  GradeHistoryDto items(List<GradeHistoryEntryDto> items);

  GradeHistoryDto nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradeHistoryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradeHistoryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  GradeHistoryDto call({List<GradeHistoryEntryDto> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGradeHistoryDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGradeHistoryDto.copyWith.fieldName(...)`
class _$GradeHistoryDtoCWProxyImpl implements _$GradeHistoryDtoCWProxy {
  const _$GradeHistoryDtoCWProxyImpl(this._value);

  final GradeHistoryDto _value;

  @override
  GradeHistoryDto items(List<GradeHistoryEntryDto> items) => this(items: items);

  @override
  GradeHistoryDto nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradeHistoryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradeHistoryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  GradeHistoryDto call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return GradeHistoryDto(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GradeHistoryEntryDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $GradeHistoryDtoCopyWith on GradeHistoryDto {
  /// Returns a callable class that can be used as follows: `instanceOfGradeHistoryDto.copyWith(...)` or like so:`instanceOfGradeHistoryDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GradeHistoryDtoCWProxy get copyWith => _$GradeHistoryDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GradeHistoryDto _$GradeHistoryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GradeHistoryDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = GradeHistoryDto(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => GradeHistoryEntryDto.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$GradeHistoryDtoToJson(GradeHistoryDto instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
