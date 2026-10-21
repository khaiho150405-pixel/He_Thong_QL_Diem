// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exemptions_result_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ExemptionsResultDtoCWProxy {
  ExemptionsResultDto bookId(num bookId);

  ExemptionsResultDto version(num version);

  ExemptionsResultDto items(List<GradeCellDto> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExemptionsResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExemptionsResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ExemptionsResultDto call({num bookId, num version, List<GradeCellDto> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfExemptionsResultDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfExemptionsResultDto.copyWith.fieldName(...)`
class _$ExemptionsResultDtoCWProxyImpl implements _$ExemptionsResultDtoCWProxy {
  const _$ExemptionsResultDtoCWProxyImpl(this._value);

  final ExemptionsResultDto _value;

  @override
  ExemptionsResultDto bookId(num bookId) => this(bookId: bookId);

  @override
  ExemptionsResultDto version(num version) => this(version: version);

  @override
  ExemptionsResultDto items(List<GradeCellDto> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExemptionsResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExemptionsResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ExemptionsResultDto call({
    Object? bookId = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return ExemptionsResultDto(
      bookId: bookId == const $CopyWithPlaceholder()
          ? _value.bookId
          // ignore: cast_nullable_to_non_nullable
          : bookId as num,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as num,
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GradeCellDto>,
    );
  }
}

extension $ExemptionsResultDtoCopyWith on ExemptionsResultDto {
  /// Returns a callable class that can be used as follows: `instanceOfExemptionsResultDto.copyWith(...)` or like so:`instanceOfExemptionsResultDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ExemptionsResultDtoCWProxy get copyWith =>
      _$ExemptionsResultDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExemptionsResultDto _$ExemptionsResultDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ExemptionsResultDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['bookId', 'version', 'items']);
      final val = ExemptionsResultDto(
        bookId: $checkedConvert('bookId', (v) => v as num),
        version: $checkedConvert('version', (v) => v as num),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => GradeCellDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ExemptionsResultDtoToJson(
  ExemptionsResultDto instance,
) => <String, dynamic>{
  'bookId': instance.bookId,
  'version': instance.version,
  'items': instance.items.map((e) => e.toJson()).toList(),
};
