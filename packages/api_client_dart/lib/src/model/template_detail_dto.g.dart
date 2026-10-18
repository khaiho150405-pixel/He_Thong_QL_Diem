// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_detail_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TemplateDetailDtoCWProxy {
  TemplateDetailDto id(num id);

  TemplateDetailDto name(String name);

  TemplateDetailDto description(String? description);

  TemplateDetailDto status(TemplateDetailDtoStatusEnum status);

  TemplateDetailDto revision(num revision);

  TemplateDetailDto rootTemplateId(num? rootTemplateId);

  TemplateDetailDto columnCount(num columnCount);

  TemplateDetailDto gradeColumnCount(num gradeColumnCount);

  TemplateDetailDto version(num version);

  TemplateDetailDto createdAt(DateTime createdAt);

  TemplateDetailDto columns(List<TemplateColumnDto> columns);

  TemplateDetailDto imageUrl(String imageUrl);

  TemplateDetailDto imageUrlExpiresInSeconds(num imageUrlExpiresInSeconds);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TemplateDetailDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TemplateDetailDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TemplateDetailDto call({
    num id,
    String name,
    String? description,
    TemplateDetailDtoStatusEnum status,
    num revision,
    num? rootTemplateId,
    num columnCount,
    num gradeColumnCount,
    num version,
    DateTime createdAt,
    List<TemplateColumnDto> columns,
    String imageUrl,
    num imageUrlExpiresInSeconds,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTemplateDetailDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTemplateDetailDto.copyWith.fieldName(...)`
class _$TemplateDetailDtoCWProxyImpl implements _$TemplateDetailDtoCWProxy {
  const _$TemplateDetailDtoCWProxyImpl(this._value);

  final TemplateDetailDto _value;

  @override
  TemplateDetailDto id(num id) => this(id: id);

  @override
  TemplateDetailDto name(String name) => this(name: name);

  @override
  TemplateDetailDto description(String? description) =>
      this(description: description);

  @override
  TemplateDetailDto status(TemplateDetailDtoStatusEnum status) =>
      this(status: status);

  @override
  TemplateDetailDto revision(num revision) => this(revision: revision);

  @override
  TemplateDetailDto rootTemplateId(num? rootTemplateId) =>
      this(rootTemplateId: rootTemplateId);

  @override
  TemplateDetailDto columnCount(num columnCount) =>
      this(columnCount: columnCount);

  @override
  TemplateDetailDto gradeColumnCount(num gradeColumnCount) =>
      this(gradeColumnCount: gradeColumnCount);

  @override
  TemplateDetailDto version(num version) => this(version: version);

  @override
  TemplateDetailDto createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  TemplateDetailDto columns(List<TemplateColumnDto> columns) =>
      this(columns: columns);

  @override
  TemplateDetailDto imageUrl(String imageUrl) => this(imageUrl: imageUrl);

  @override
  TemplateDetailDto imageUrlExpiresInSeconds(num imageUrlExpiresInSeconds) =>
      this(imageUrlExpiresInSeconds: imageUrlExpiresInSeconds);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TemplateDetailDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TemplateDetailDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TemplateDetailDto call({
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
    Object? columns = const $CopyWithPlaceholder(),
    Object? imageUrl = const $CopyWithPlaceholder(),
    Object? imageUrlExpiresInSeconds = const $CopyWithPlaceholder(),
  }) {
    return TemplateDetailDto(
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
          : status as TemplateDetailDtoStatusEnum,
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
      columns: columns == const $CopyWithPlaceholder()
          ? _value.columns
          // ignore: cast_nullable_to_non_nullable
          : columns as List<TemplateColumnDto>,
      imageUrl: imageUrl == const $CopyWithPlaceholder()
          ? _value.imageUrl
          // ignore: cast_nullable_to_non_nullable
          : imageUrl as String,
      imageUrlExpiresInSeconds:
          imageUrlExpiresInSeconds == const $CopyWithPlaceholder()
          ? _value.imageUrlExpiresInSeconds
          // ignore: cast_nullable_to_non_nullable
          : imageUrlExpiresInSeconds as num,
    );
  }
}

extension $TemplateDetailDtoCopyWith on TemplateDetailDto {
  /// Returns a callable class that can be used as follows: `instanceOfTemplateDetailDto.copyWith(...)` or like so:`instanceOfTemplateDetailDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TemplateDetailDtoCWProxy get copyWith =>
      _$TemplateDetailDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TemplateDetailDto _$TemplateDetailDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TemplateDetailDto', json, ($checkedConvert) {
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
          'columns',
          'imageUrl',
          'imageUrlExpiresInSeconds',
        ],
      );
      final val = TemplateDetailDto(
        id: $checkedConvert('id', (v) => v as num),
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String?),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$TemplateDetailDtoStatusEnumEnumMap, v),
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
        columns: $checkedConvert(
          'columns',
          (v) => (v as List<dynamic>)
              .map((e) => TemplateColumnDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        imageUrl: $checkedConvert('imageUrl', (v) => v as String),
        imageUrlExpiresInSeconds: $checkedConvert(
          'imageUrlExpiresInSeconds',
          (v) => v as num,
        ),
      );
      return val;
    });

Map<String, dynamic> _$TemplateDetailDtoToJson(TemplateDetailDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'status': _$TemplateDetailDtoStatusEnumEnumMap[instance.status]!,
      'revision': instance.revision,
      'rootTemplateId': instance.rootTemplateId,
      'columnCount': instance.columnCount,
      'gradeColumnCount': instance.gradeColumnCount,
      'version': instance.version,
      'createdAt': instance.createdAt.toIso8601String(),
      'columns': instance.columns.map((e) => e.toJson()).toList(),
      'imageUrl': instance.imageUrl,
      'imageUrlExpiresInSeconds': instance.imageUrlExpiresInSeconds,
    };

const _$TemplateDetailDtoStatusEnumEnumMap = {
  TemplateDetailDtoStatusEnum.NHAP: 'NHAP',
  TemplateDetailDtoStatusEnum.DANG_DUNG: 'DANG_DUNG',
  TemplateDetailDtoStatusEnum.NGUNG: 'NGUNG',
};
