// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'students_import_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StudentsImportInputCWProxy {
  StudentsImportInput items(List<StudentsInput> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentsImportInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentsImportInput(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentsImportInput call({List<StudentsInput> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStudentsImportInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStudentsImportInput.copyWith.fieldName(...)`
class _$StudentsImportInputCWProxyImpl implements _$StudentsImportInputCWProxy {
  const _$StudentsImportInputCWProxyImpl(this._value);

  final StudentsImportInput _value;

  @override
  StudentsImportInput items(List<StudentsInput> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentsImportInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentsImportInput(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentsImportInput call({Object? items = const $CopyWithPlaceholder()}) {
    return StudentsImportInput(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<StudentsInput>,
    );
  }
}

extension $StudentsImportInputCopyWith on StudentsImportInput {
  /// Returns a callable class that can be used as follows: `instanceOfStudentsImportInput.copyWith(...)` or like so:`instanceOfStudentsImportInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StudentsImportInputCWProxy get copyWith =>
      _$StudentsImportInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentsImportInput _$StudentsImportInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StudentsImportInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = StudentsImportInput(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => StudentsInput.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$StudentsImportInputToJson(
  StudentsImportInput instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
