// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_summary_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TemplateSummaryDtoCWProxy {
  TemplateSummaryDto id(num id);

  TemplateSummaryDto name(String name);

  TemplateSummaryDto description(String? description);

  TemplateSummaryDto status(TemplateSummaryDtoStatusEnum status);

  TemplateSummaryDto revision(num revision);

  TemplateSummaryDto rootTemplateId(num? rootTemplateId);

  TemplateSummaryDto columnCount(num columnCount);

  TemplateSummaryDto gradeColumnCount(num gradeColumnCount);

  TemplateSummaryDto version(num version);

  TemplateSummaryDto createdAt(DateTime createdAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TemplateSummaryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TemplateSummaryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TemplateSummaryDto call({
    num id,
    String name,
    String? description,
    TemplateSummaryDtoStatusEnum status,
    num revision,
    num? rootTemplateId,
    num columnCount,
    num gradeColumnCount,
    num version,
    DateTime createdAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTemplateSummaryDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTemplateSummaryDto.copyWith.fieldName(...)`
class _$TemplateSummaryDtoCWProxyImpl implements _$TemplateSummaryDtoCWProxy {
  const _$TemplateSummaryDtoCWProxyImpl(this._value);

  final TemplateSummaryDto _value;

  @override
  TemplateSummaryDto id(num id) => this(id: id);

  @override
  TemplateSummaryDto name(String name) => this(name: name);

  @override
  TemplateSummaryDto description(String? description) =>
      this(description: description);

  @override
  TemplateSummaryDto status(TemplateSummaryDtoStatusEnum status) =>
      this(status: status);

  @override
  TemplateSummaryDto revision(num revision) => this(revision: revision);

  @override
  TemplateSummaryDto rootTemplateId(num? rootTemplateId) =>
      this(rootTemplateId: rootTemplateId);

  @override
  TemplateSummaryDto columnCount(num columnCount) =>
      this(columnCount: columnCount);

  @override
  TemplateSummaryDto gradeColumnCount(num gradeColumnCount) =>
      this(gradeColumnCount: gradeColumnCount);

  @override
  TemplateSummaryDto version(num version) => this(version: version);

  @override
  TemplateSummaryDto createdAt(DateTime createdAt) =>
      this(createdAt: createdAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TemplateSummaryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TemplateSummaryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TemplateSummaryDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? revision = const $CopyWithPlaceholder(),
    Object? rootTemplateId = const $CopyWithPlaceholder(),
    Object? columnCount = const $CopyWithPlaceholder(),
    Object? gradeColumnCount = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return TemplateSummaryDto(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as num,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as TemplateSummaryDtoStatusEnum,
      revision: revision == const $CopyWithPlaceholder()
          ? _value.revision
          // ignore: cast_nullable_to_non_nullable
          : revision as num,
      rootTemplateId: rootTemplateId == const $CopyWithPlaceholder()
          ? _value.rootTemplateId
          // ignore: cast_nullable_to_non_nullable
          : rootTemplateId as num?,
      columnCount: columnCount == const $CopyWithPlaceholder()
          ? _value.columnCount
          // ignore: cast_nullable_to_non_nullable
          : columnCount as num,
      gradeColumnCount: gradeColumnCount == const $CopyWithPlaceholder()
          ? _value.gradeColumnCount
          // ignore: cast_nullable_to_non_nullable
          : gradeColumnCount as num,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as num,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $TemplateSummaryDtoCopyWith on TemplateSummaryDto {
  /// Returns a callable class that can be used as follows: `instanceOfTemplateSummaryDto.copyWith(...)` or like so:`instanceOfTemplateSummaryDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TemplateSummaryDtoCWProxy get copyWith =>
      _$TemplateSummaryDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TemplateSummaryDto _$TemplateSummaryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TemplateSummaryDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'name',
          'description',
          'status',
          'revision',
          'rootTemplateId',
          'columnCount',
          'gradeColumnCount',
          'version',
          'createdAt',
        ],
      );
      final val = TemplateSummaryDto(
        id: $checkedConvert('id', (v) => v as num),
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String?),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$TemplateSummaryDtoStatusEnumEnumMap, v),
        ),
        revision: $checkedConvert('revision', (v) => v as num),
        rootTemplateId: $checkedConvert('rootTemplateId', (v) => v as num?),
        columnCount: $checkedConvert('columnCount', (v) => v as num),
        gradeColumnCount: $checkedConvert('gradeColumnCount', (v) => v as num),
        version: $checkedConvert('version', (v) => v as num),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TemplateSummaryDtoToJson(TemplateSummaryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'status': _$TemplateSummaryDtoStatusEnumEnumMap[instance.status]!,
      'revision': instance.revision,
      'rootTemplateId': instance.rootTemplateId,
      'columnCount': instance.columnCount,
      'gradeColumnCount': instance.gradeColumnCount,
      'version': instance.version,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$TemplateSummaryDtoStatusEnumEnumMap = {
  TemplateSummaryDtoStatusEnum.NHAP: 'NHAP',
  TemplateSummaryDtoStatusEnum.DANG_DUNG: 'DANG_DUNG',
  TemplateSummaryDtoStatusEnum.NGUNG: 'NGUNG',
};
