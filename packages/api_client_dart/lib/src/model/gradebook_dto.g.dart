// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gradebook_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GradebookDtoCWProxy {
  GradebookDto id(num id);

  GradebookDto classId(num classId);

  GradebookDto subjectId(num subjectId);

  GradebookDto termId(num termId);

  GradebookDto status(GradebookDtoStatusEnum status);

  GradebookDto version(num version);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradebookDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradebookDto(...).copyWith(id: 12, name: "My name")
  /// ````
  GradebookDto call({
    num id,
    num classId,
    num subjectId,
    num termId,
    GradebookDtoStatusEnum status,
    num version,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGradebookDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGradebookDto.copyWith.fieldName(...)`
class _$GradebookDtoCWProxyImpl implements _$GradebookDtoCWProxy {
  const _$GradebookDtoCWProxyImpl(this._value);

  final GradebookDto _value;

  @override
  GradebookDto id(num id) => this(id: id);

  @override
  GradebookDto classId(num classId) => this(classId: classId);

  @override
  GradebookDto subjectId(num subjectId) => this(subjectId: subjectId);

  @override
  GradebookDto termId(num termId) => this(termId: termId);

  @override
  GradebookDto status(GradebookDtoStatusEnum status) => this(status: status);

  @override
  GradebookDto version(num version) => this(version: version);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradebookDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradebookDto(...).copyWith(id: 12, name: "My name")
  /// ````
  GradebookDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? classId = const $CopyWithPlaceholder(),
    Object? subjectId = const $CopyWithPlaceholder(),
    Object? termId = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
  }) {
    return GradebookDto(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as num,
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
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as GradebookDtoStatusEnum,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as num,
    );
  }
}

extension $GradebookDtoCopyWith on GradebookDto {
  /// Returns a callable class that can be used as follows: `instanceOfGradebookDto.copyWith(...)` or like so:`instanceOfGradebookDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GradebookDtoCWProxy get copyWith => _$GradebookDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GradebookDto _$GradebookDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GradebookDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'classId',
          'subjectId',
          'termId',
          'status',
          'version',
        ],
      );
      final val = GradebookDto(
        id: $checkedConvert('id', (v) => v as num),
        classId: $checkedConvert('classId', (v) => v as num),
        subjectId: $checkedConvert('subjectId', (v) => v as num),
        termId: $checkedConvert('termId', (v) => v as num),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$GradebookDtoStatusEnumEnumMap, v),
        ),
        version: $checkedConvert('version', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$GradebookDtoToJson(GradebookDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'classId': instance.classId,
      'subjectId': instance.subjectId,
      'termId': instance.termId,
      'status': _$GradebookDtoStatusEnumEnumMap[instance.status]!,
      'version': instance.version,
    };

const _$GradebookDtoStatusEnumEnumMap = {
  GradebookDtoStatusEnum.DANG_NHAP_LIEU: 'DANG_NHAP_LIEU',
  GradebookDtoStatusEnum.DA_CHOT: 'DA_CHOT',
};
