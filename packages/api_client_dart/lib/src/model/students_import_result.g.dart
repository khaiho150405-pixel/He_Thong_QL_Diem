// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'students_import_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StudentsImportResultCWProxy {
  StudentsImportResult imported(num imported);

  StudentsImportResult items(List<StudentsDto> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentsImportResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentsImportResult(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentsImportResult call({num imported, List<StudentsDto> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStudentsImportResult.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStudentsImportResult.copyWith.fieldName(...)`
class _$StudentsImportResultCWProxyImpl
    implements _$StudentsImportResultCWProxy {
  const _$StudentsImportResultCWProxyImpl(this._value);

  final StudentsImportResult _value;

  @override
  StudentsImportResult imported(num imported) => this(imported: imported);

  @override
  StudentsImportResult items(List<StudentsDto> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentsImportResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentsImportResult(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentsImportResult call({
    Object? imported = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return StudentsImportResult(
      imported: imported == const $CopyWithPlaceholder()
          ? _value.imported
          // ignore: cast_nullable_to_non_nullable
          : imported as num,
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<StudentsDto>,
    );
  }
}

extension $StudentsImportResultCopyWith on StudentsImportResult {
  /// Returns a callable class that can be used as follows: `instanceOfStudentsImportResult.copyWith(...)` or like so:`instanceOfStudentsImportResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StudentsImportResultCWProxy get copyWith =>
      _$StudentsImportResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentsImportResult _$StudentsImportResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StudentsImportResult', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['imported', 'items']);
  final val = StudentsImportResult(
    imported: $checkedConvert('imported', (v) => v as num),
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => StudentsDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$StudentsImportResultToJson(
  StudentsImportResult instance,
) => <String, dynamic>{
  'imported': instance.imported,
  'items': instance.items.map((e) => e.toJson()).toList(),
};
