// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'affected_gradebook_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AffectedGradebookDtoCWProxy {
  AffectedGradebookDto id(num id);

  AffectedGradebookDto subjectName(String subjectName);

  AffectedGradebookDto termName(String termName);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AffectedGradebookDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AffectedGradebookDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AffectedGradebookDto call({num id, String subjectName, String termName});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAffectedGradebookDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAffectedGradebookDto.copyWith.fieldName(...)`
class _$AffectedGradebookDtoCWProxyImpl
    implements _$AffectedGradebookDtoCWProxy {
  const _$AffectedGradebookDtoCWProxyImpl(this._value);

  final AffectedGradebookDto _value;

  @override
  AffectedGradebookDto id(num id) => this(id: id);

  @override
  AffectedGradebookDto subjectName(String subjectName) =>
      this(subjectName: subjectName);

  @override
  AffectedGradebookDto termName(String termName) => this(termName: termName);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AffectedGradebookDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AffectedGradebookDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AffectedGradebookDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? subjectName = const $CopyWithPlaceholder(),
    Object? termName = const $CopyWithPlaceholder(),
  }) {
    return AffectedGradebookDto(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as num,
      subjectName: subjectName == const $CopyWithPlaceholder()
          ? _value.subjectName
          // ignore: cast_nullable_to_non_nullable
          : subjectName as String,
      termName: termName == const $CopyWithPlaceholder()
          ? _value.termName
          // ignore: cast_nullable_to_non_nullable
          : termName as String,
    );
  }
}

extension $AffectedGradebookDtoCopyWith on AffectedGradebookDto {
  /// Returns a callable class that can be used as follows: `instanceOfAffectedGradebookDto.copyWith(...)` or like so:`instanceOfAffectedGradebookDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AffectedGradebookDtoCWProxy get copyWith =>
      _$AffectedGradebookDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AffectedGradebookDto _$AffectedGradebookDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AffectedGradebookDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['id', 'subjectName', 'termName']);
  final val = AffectedGradebookDto(
    id: $checkedConvert('id', (v) => v as num),
    subjectName: $checkedConvert('subjectName', (v) => v as String),
    termName: $checkedConvert('termName', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$AffectedGradebookDtoToJson(
  AffectedGradebookDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'subjectName': instance.subjectName,
  'termName': instance.termName,
};
