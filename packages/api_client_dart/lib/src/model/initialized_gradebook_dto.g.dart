// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'initialized_gradebook_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InitializedGradebookDtoCWProxy {
  InitializedGradebookDto gradebookId(num gradebookId);

  InitializedGradebookDto classId(num classId);

  InitializedGradebookDto className(String className);

  InitializedGradebookDto subjectId(num subjectId);

  InitializedGradebookDto subjectName(String subjectName);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InitializedGradebookDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InitializedGradebookDto(...).copyWith(id: 12, name: "My name")
  /// ````
  InitializedGradebookDto call({
    num gradebookId,
    num classId,
    String className,
    num subjectId,
    String subjectName,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfInitializedGradebookDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfInitializedGradebookDto.copyWith.fieldName(...)`
class _$InitializedGradebookDtoCWProxyImpl
    implements _$InitializedGradebookDtoCWProxy {
  const _$InitializedGradebookDtoCWProxyImpl(this._value);

  final InitializedGradebookDto _value;

  @override
  InitializedGradebookDto gradebookId(num gradebookId) =>
      this(gradebookId: gradebookId);

  @override
  InitializedGradebookDto classId(num classId) => this(classId: classId);

  @override
  InitializedGradebookDto className(String className) =>
      this(className: className);

  @override
  InitializedGradebookDto subjectId(num subjectId) =>
      this(subjectId: subjectId);

  @override
  InitializedGradebookDto subjectName(String subjectName) =>
      this(subjectName: subjectName);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InitializedGradebookDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InitializedGradebookDto(...).copyWith(id: 12, name: "My name")
  /// ````
  InitializedGradebookDto call({
    Object? gradebookId = const $CopyWithPlaceholder(),
    Object? classId = const $CopyWithPlaceholder(),
    Object? className = const $CopyWithPlaceholder(),
    Object? subjectId = const $CopyWithPlaceholder(),
    Object? subjectName = const $CopyWithPlaceholder(),
  }) {
    return InitializedGradebookDto(
      gradebookId: gradebookId == const $CopyWithPlaceholder()
          ? _value.gradebookId
          // ignore: cast_nullable_to_non_nullable
          : gradebookId as num,
      classId: classId == const $CopyWithPlaceholder()
          ? _value.classId
          // ignore: cast_nullable_to_non_nullable
          : classId as num,
      className: className == const $CopyWithPlaceholder()
          ? _value.className
          // ignore: cast_nullable_to_non_nullable
          : className as String,
      subjectId: subjectId == const $CopyWithPlaceholder()
          ? _value.subjectId
          // ignore: cast_nullable_to_non_nullable
          : subjectId as num,
      subjectName: subjectName == const $CopyWithPlaceholder()
          ? _value.subjectName
          // ignore: cast_nullable_to_non_nullable
          : subjectName as String,
    );
  }
}

extension $InitializedGradebookDtoCopyWith on InitializedGradebookDto {
  /// Returns a callable class that can be used as follows: `instanceOfInitializedGradebookDto.copyWith(...)` or like so:`instanceOfInitializedGradebookDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InitializedGradebookDtoCWProxy get copyWith =>
      _$InitializedGradebookDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InitializedGradebookDto _$InitializedGradebookDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('InitializedGradebookDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'gradebookId',
      'classId',
      'className',
      'subjectId',
      'subjectName',
    ],
  );
  final val = InitializedGradebookDto(
    gradebookId: $checkedConvert('gradebookId', (v) => v as num),
    classId: $checkedConvert('classId', (v) => v as num),
    className: $checkedConvert('className', (v) => v as String),
    subjectId: $checkedConvert('subjectId', (v) => v as num),
    subjectName: $checkedConvert('subjectName', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$InitializedGradebookDtoToJson(
  InitializedGradebookDto instance,
) => <String, dynamic>{
  'gradebookId': instance.gradebookId,
  'classId': instance.classId,
  'className': instance.className,
  'subjectId': instance.subjectId,
  'subjectName': instance.subjectName,
};
