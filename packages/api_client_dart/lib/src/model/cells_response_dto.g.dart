// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cells_response_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CellsResponseDtoCWProxy {
  CellsResponseDto book(GradebookDto book);

  CellsResponseDto items(List<GradeCellDto> items);

  CellsResponseDto nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CellsResponseDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CellsResponseDto(...).copyWith(id: 12, name: "My name")
  /// ````
  CellsResponseDto call({
    GradebookDto book,
    List<GradeCellDto> items,
    String? nextCursor,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCellsResponseDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCellsResponseDto.copyWith.fieldName(...)`
class _$CellsResponseDtoCWProxyImpl implements _$CellsResponseDtoCWProxy {
  const _$CellsResponseDtoCWProxyImpl(this._value);

  final CellsResponseDto _value;

  @override
  CellsResponseDto book(GradebookDto book) => this(book: book);

  @override
  CellsResponseDto items(List<GradeCellDto> items) => this(items: items);

  @override
  CellsResponseDto nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CellsResponseDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CellsResponseDto(...).copyWith(id: 12, name: "My name")
  /// ````
  CellsResponseDto call({
    Object? book = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return CellsResponseDto(
      book: book == const $CopyWithPlaceholder()
          ? _value.book
          // ignore: cast_nullable_to_non_nullable
          : book as GradebookDto,
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GradeCellDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $CellsResponseDtoCopyWith on CellsResponseDto {
  /// Returns a callable class that can be used as follows: `instanceOfCellsResponseDto.copyWith(...)` or like so:`instanceOfCellsResponseDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CellsResponseDtoCWProxy get copyWith => _$CellsResponseDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CellsResponseDto _$CellsResponseDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CellsResponseDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['book', 'items', 'nextCursor']);
      final val = CellsResponseDto(
        book: $checkedConvert(
          'book',
          (v) => GradebookDto.fromJson(v as Map<String, dynamic>),
        ),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => GradeCellDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CellsResponseDtoToJson(CellsResponseDto instance) =>
    <String, dynamic>{
      'book': instance.book.toJson(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
