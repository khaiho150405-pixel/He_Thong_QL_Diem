// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_update_result_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BatchUpdateResultDtoCWProxy {
  BatchUpdateResultDto items(List<UpdatedCellDto> items);

  BatchUpdateResultDto bookId(num bookId);

  BatchUpdateResultDto version(num version);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BatchUpdateResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BatchUpdateResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  BatchUpdateResultDto call({
    List<UpdatedCellDto> items,
    num bookId,
    num version,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfBatchUpdateResultDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfBatchUpdateResultDto.copyWith.fieldName(...)`
class _$BatchUpdateResultDtoCWProxyImpl
    implements _$BatchUpdateResultDtoCWProxy {
  const _$BatchUpdateResultDtoCWProxyImpl(this._value);

  final BatchUpdateResultDto _value;

  @override
  BatchUpdateResultDto items(List<UpdatedCellDto> items) => this(items: items);

  @override
  BatchUpdateResultDto bookId(num bookId) => this(bookId: bookId);

  @override
  BatchUpdateResultDto version(num version) => this(version: version);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BatchUpdateResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BatchUpdateResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  BatchUpdateResultDto call({
    Object? items = const $CopyWithPlaceholder(),
    Object? bookId = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
  }) {
    return BatchUpdateResultDto(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<UpdatedCellDto>,
      bookId: bookId == const $CopyWithPlaceholder()
          ? _value.bookId
          // ignore: cast_nullable_to_non_nullable
          : bookId as num,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as num,
    );
  }
}

extension $BatchUpdateResultDtoCopyWith on BatchUpdateResultDto {
  /// Returns a callable class that can be used as follows: `instanceOfBatchUpdateResultDto.copyWith(...)` or like so:`instanceOfBatchUpdateResultDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BatchUpdateResultDtoCWProxy get copyWith =>
      _$BatchUpdateResultDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BatchUpdateResultDto _$BatchUpdateResultDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('BatchUpdateResultDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items', 'bookId', 'version']);
  final val = BatchUpdateResultDto(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => UpdatedCellDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    bookId: $checkedConvert('bookId', (v) => v as num),
    version: $checkedConvert('version', (v) => v as num),
  );
  return val;
});

Map<String, dynamic> _$BatchUpdateResultDtoToJson(
  BatchUpdateResultDto instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'bookId': instance.bookId,
  'version': instance.version,
};
