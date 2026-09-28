// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teachers_import_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TeachersImportInputCWProxy {
  TeachersImportInput items(List<TeachersInput> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TeachersImportInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TeachersImportInput(...).copyWith(id: 12, name: "My name")
  /// ````
  TeachersImportInput call({List<TeachersInput> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTeachersImportInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTeachersImportInput.copyWith.fieldName(...)`
class _$TeachersImportInputCWProxyImpl implements _$TeachersImportInputCWProxy {
  const _$TeachersImportInputCWProxyImpl(this._value);

  final TeachersImportInput _value;

  @override
  TeachersImportInput items(List<TeachersInput> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TeachersImportInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TeachersImportInput(...).copyWith(id: 12, name: "My name")
  /// ````
  TeachersImportInput call({Object? items = const $CopyWithPlaceholder()}) {
    return TeachersImportInput(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<TeachersInput>,
    );
  }
}

extension $TeachersImportInputCopyWith on TeachersImportInput {
  /// Returns a callable class that can be used as follows: `instanceOfTeachersImportInput.copyWith(...)` or like so:`instanceOfTeachersImportInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TeachersImportInputCWProxy get copyWith =>
      _$TeachersImportInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeachersImportInput _$TeachersImportInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TeachersImportInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = TeachersImportInput(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => TeachersInput.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TeachersImportInputToJson(
  TeachersImportInput instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
