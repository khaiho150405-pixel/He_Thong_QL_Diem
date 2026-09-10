// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_gradebook_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateGradebookInputCWProxy {
  CreateGradebookInput classId(num classId);

  CreateGradebookInput subjectId(num subjectId);

  CreateGradebookInput termId(num termId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateGradebookInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateGradebookInput(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateGradebookInput call({num classId, num subjectId, num termId});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCreateGradebookInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCreateGradebookInput.copyWith.fieldName(...)`
class _$CreateGradebookInputCWProxyImpl
    implements _$CreateGradebookInputCWProxy {
  const _$CreateGradebookInputCWProxyImpl(this._value);

  final CreateGradebookInput _value;

  @override
  CreateGradebookInput classId(num classId) => this(classId: classId);

  @override
  CreateGradebookInput subjectId(num subjectId) => this(subjectId: subjectId);

  @override
  CreateGradebookInput termId(num termId) => this(termId: termId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateGradebookInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateGradebookInput(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateGradebookInput call({
    Object? classId = const $CopyWithPlaceholder(),
    Object? subjectId = const $CopyWithPlaceholder(),
    Object? termId = const $CopyWithPlaceholder(),
  }) {
    return CreateGradebookInput(
      classId: classId == const $CopyWithPlaceholder()
          ? _value.classId
          // ignore: cast_nullable_to_non_nullable
          : classId as num,
      subjectId: subjectId == const $CopyWithPlaceholder()
          ? _value.subjectId
          // ignore: cast_nullable_to_non_nullable
          : subjectId as num,
      termId: termId == const $CopyWithPlaceholder()
          ? _value.termId
          // ignore: cast_nullable_to_non_nullable
          : termId as num,
    );
  }
}

extension $CreateGradebookInputCopyWith on CreateGradebookInput {
  /// Returns a callable class that can be used as follows: `instanceOfCreateGradebookInput.copyWith(...)` or like so:`instanceOfCreateGradebookInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateGradebookInputCWProxy get copyWith =>
      _$CreateGradebookInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateGradebookInput _$CreateGradebookInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateGradebookInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['classId', 'subjectId', 'termId']);
  final val = CreateGradebookInput(
    classId: $checkedConvert('classId', (v) => v as num),
    subjectId: $checkedConvert('subjectId', (v) => v as num),
    termId: $checkedConvert('termId', (v) => v as num),
  );
  return val;
});

Map<String, dynamic> _$CreateGradebookInputToJson(
  CreateGradebookInput instance,
) => <String, dynamic>{
  'classId': instance.classId,
  'subjectId': instance.subjectId,
  'termId': instance.termId,
};
