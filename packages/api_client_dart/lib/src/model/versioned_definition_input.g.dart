// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'versioned_definition_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VersionedDefinitionInputCWProxy {
  VersionedDefinitionInput name(String name);

  VersionedDefinitionInput description(String? description);

  VersionedDefinitionInput columns(List<TemplateColumnDto> columns);

  VersionedDefinitionInput expectedVersion(num expectedVersion);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VersionedDefinitionInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VersionedDefinitionInput(...).copyWith(id: 12, name: "My name")
  /// ````
  VersionedDefinitionInput call({
    String name,
    String? description,
    List<TemplateColumnDto> columns,
    num expectedVersion,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfVersionedDefinitionInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfVersionedDefinitionInput.copyWith.fieldName(...)`
class _$VersionedDefinitionInputCWProxyImpl
    implements _$VersionedDefinitionInputCWProxy {
  const _$VersionedDefinitionInputCWProxyImpl(this._value);

  final VersionedDefinitionInput _value;

  @override
  VersionedDefinitionInput name(String name) => this(name: name);

  @override
  VersionedDefinitionInput description(String? description) =>
      this(description: description);

  @override
  VersionedDefinitionInput columns(List<TemplateColumnDto> columns) =>
      this(columns: columns);

  @override
  VersionedDefinitionInput expectedVersion(num expectedVersion) =>
      this(expectedVersion: expectedVersion);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VersionedDefinitionInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VersionedDefinitionInput(...).copyWith(id: 12, name: "My name")
  /// ````
  VersionedDefinitionInput call({
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? columns = const $CopyWithPlaceholder(),
    Object? expectedVersion = const $CopyWithPlaceholder(),
  }) {
    return VersionedDefinitionInput(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
      columns: columns == const $CopyWithPlaceholder()
          ? _value.columns
          // ignore: cast_nullable_to_non_nullable
          : columns as List<TemplateColumnDto>,
      expectedVersion: expectedVersion == const $CopyWithPlaceholder()
          ? _value.expectedVersion
          // ignore: cast_nullable_to_non_nullable
          : expectedVersion as num,
    );
  }
}

extension $VersionedDefinitionInputCopyWith on VersionedDefinitionInput {
  /// Returns a callable class that can be used as follows: `instanceOfVersionedDefinitionInput.copyWith(...)` or like so:`instanceOfVersionedDefinitionInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VersionedDefinitionInputCWProxy get copyWith =>
      _$VersionedDefinitionInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VersionedDefinitionInput _$VersionedDefinitionInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('VersionedDefinitionInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name', 'columns', 'expectedVersion']);
  final val = VersionedDefinitionInput(
    name: $checkedConvert('name', (v) => v as String),
    description: $checkedConvert('description', (v) => v as String?),
    columns: $checkedConvert(
      'columns',
      (v) => (v as List<dynamic>)
          .map((e) => TemplateColumnDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    expectedVersion: $checkedConvert('expectedVersion', (v) => v as num),
  );
  return val;
});

Map<String, dynamic> _$VersionedDefinitionInputToJson(
  VersionedDefinitionInput instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': ?instance.description,
  'columns': instance.columns.map((e) => e.toJson()).toList(),
  'expectedVersion': instance.expectedVersion,
};
