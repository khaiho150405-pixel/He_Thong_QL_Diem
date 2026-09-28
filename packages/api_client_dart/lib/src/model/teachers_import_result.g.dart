// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teachers_import_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TeachersImportResultCWProxy {
  TeachersImportResult imported(num imported);

  TeachersImportResult items(List<TeachersDto> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TeachersImportResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TeachersImportResult(...).copyWith(id: 12, name: "My name")
  /// ````
  TeachersImportResult call({num imported, List<TeachersDto> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTeachersImportResult.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTeachersImportResult.copyWith.fieldName(...)`
class _$TeachersImportResultCWProxyImpl
    implements _$TeachersImportResultCWProxy {
  const _$TeachersImportResultCWProxyImpl(this._value);

  final TeachersImportResult _value;

  @override
  TeachersImportResult imported(num imported) => this(imported: imported);

  @override
  TeachersImportResult items(List<TeachersDto> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TeachersImportResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TeachersImportResult(...).copyWith(id: 12, name: "My name")
  /// ````
  TeachersImportResult call({
    Object? imported = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return TeachersImportResult(
      imported: imported == const $CopyWithPlaceholder()
          ? _value.imported
          // ignore: cast_nullable_to_non_nullable
          : imported as num,
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<TeachersDto>,
    );
  }
}

extension $TeachersImportResultCopyWith on TeachersImportResult {
  /// Returns a callable class that can be used as follows: `instanceOfTeachersImportResult.copyWith(...)` or like so:`instanceOfTeachersImportResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TeachersImportResultCWProxy get copyWith =>
      _$TeachersImportResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeachersImportResult _$TeachersImportResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('TeachersImportResult', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['imported', 'items']);
  final val = TeachersImportResult(
    imported: $checkedConvert('imported', (v) => v as num),
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => TeachersDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$TeachersImportResultToJson(
  TeachersImportResult instance,
) => <String, dynamic>{
  'imported': instance.imported,
  'items': instance.items.map((e) => e.toJson()).toList(),
};
