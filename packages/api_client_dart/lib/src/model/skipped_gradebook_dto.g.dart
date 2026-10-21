// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skipped_gradebook_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SkippedGradebookDtoCWProxy {
  SkippedGradebookDto classId(num classId);

  SkippedGradebookDto className(String className);

  SkippedGradebookDto subjectId(num subjectId);

  SkippedGradebookDto subjectName(String subjectName);

  SkippedGradebookDto reason(SkippedGradebookDtoReasonEnum reason);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SkippedGradebookDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SkippedGradebookDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SkippedGradebookDto call({
    num classId,
    String className,
    num subjectId,
    String subjectName,
    SkippedGradebookDtoReasonEnum reason,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSkippedGradebookDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSkippedGradebookDto.copyWith.fieldName(...)`
class _$SkippedGradebookDtoCWProxyImpl implements _$SkippedGradebookDtoCWProxy {
  const _$SkippedGradebookDtoCWProxyImpl(this._value);

  final SkippedGradebookDto _value;

  @override
  SkippedGradebookDto classId(num classId) => this(classId: classId);

  @override
  SkippedGradebookDto className(String className) => this(className: className);

  @override
  SkippedGradebookDto subjectId(num subjectId) => this(subjectId: subjectId);

  @override
  SkippedGradebookDto subjectName(String subjectName) =>
      this(subjectName: subjectName);

  @override
  SkippedGradebookDto reason(SkippedGradebookDtoReasonEnum reason) =>
      this(reason: reason);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SkippedGradebookDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SkippedGradebookDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SkippedGradebookDto call({
    Object? classId = const $CopyWithPlaceholder(),
    Object? className = const $CopyWithPlaceholder(),
    Object? subjectId = const $CopyWithPlaceholder(),
    Object? subjectName = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return SkippedGradebookDto(
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
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as SkippedGradebookDtoReasonEnum,
    );
  }
}

extension $SkippedGradebookDtoCopyWith on SkippedGradebookDto {
  /// Returns a callable class that can be used as follows: `instanceOfSkippedGradebookDto.copyWith(...)` or like so:`instanceOfSkippedGradebookDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SkippedGradebookDtoCWProxy get copyWith =>
      _$SkippedGradebookDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkippedGradebookDto _$SkippedGradebookDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SkippedGradebookDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'classId',
          'className',
          'subjectId',
          'subjectName',
          'reason',
        ],
      );
      final val = SkippedGradebookDto(
        classId: $checkedConvert('classId', (v) => v as num),
        className: $checkedConvert('className', (v) => v as String),
        subjectId: $checkedConvert('subjectId', (v) => v as num),
        subjectName: $checkedConvert('subjectName', (v) => v as String),
        reason: $checkedConvert(
          'reason',
          (v) => $enumDecode(_$SkippedGradebookDtoReasonEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SkippedGradebookDtoToJson(
  SkippedGradebookDto instance,
) => <String, dynamic>{
  'classId': instance.classId,
  'className': instance.className,
  'subjectId': instance.subjectId,
  'subjectName': instance.subjectName,
  'reason': _$SkippedGradebookDtoReasonEnumEnumMap[instance.reason]!,
};

const _$SkippedGradebookDtoReasonEnumEnumMap = {
  SkippedGradebookDtoReasonEnum.EMPTY_ROSTER: 'EMPTY_ROSTER',
  SkippedGradebookDtoReasonEnum.NO_COMPONENTS: 'NO_COMPONENTS',
};
