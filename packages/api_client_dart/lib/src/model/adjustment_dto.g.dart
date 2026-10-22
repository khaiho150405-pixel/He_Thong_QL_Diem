// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adjustment_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdjustmentDtoCWProxy {
  AdjustmentDto id(String id);

  AdjustmentDto gradebookId(num gradebookId);

  AdjustmentDto className(String className);

  AdjustmentDto subjectName(String subjectName);

  AdjustmentDto termName(String termName);

  AdjustmentDto status(AdjustmentDtoStatusEnum status);

  AdjustmentDto reason(String reason);

  AdjustmentDto submittedBy(AdjustmentPersonDto submittedBy);

  AdjustmentDto submittedAt(DateTime submittedAt);

  AdjustmentDto decidedBy(AdjustmentPersonDto? decidedBy);

  AdjustmentDto decidedAt(DateTime? decidedAt);

  AdjustmentDto decisionReason(String? decisionReason);

  AdjustmentDto lineCount(num lineCount);

  AdjustmentDto version(num version);

  AdjustmentDto lines(List<AdjustmentLineDto>? lines);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentDto call({
    String id,
    num gradebookId,
    String className,
    String subjectName,
    String termName,
    AdjustmentDtoStatusEnum status,
    String reason,
    AdjustmentPersonDto submittedBy,
    DateTime submittedAt,
    AdjustmentPersonDto? decidedBy,
    DateTime? decidedAt,
    String? decisionReason,
    num lineCount,
    num version,
    List<AdjustmentLineDto>? lines,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdjustmentDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdjustmentDto.copyWith.fieldName(...)`
class _$AdjustmentDtoCWProxyImpl implements _$AdjustmentDtoCWProxy {
  const _$AdjustmentDtoCWProxyImpl(this._value);

  final AdjustmentDto _value;

  @override
  AdjustmentDto id(String id) => this(id: id);

  @override
  AdjustmentDto gradebookId(num gradebookId) => this(gradebookId: gradebookId);

  @override
  AdjustmentDto className(String className) => this(className: className);

  @override
  AdjustmentDto subjectName(String subjectName) =>
      this(subjectName: subjectName);

  @override
  AdjustmentDto termName(String termName) => this(termName: termName);

  @override
  AdjustmentDto status(AdjustmentDtoStatusEnum status) => this(status: status);

  @override
  AdjustmentDto reason(String reason) => this(reason: reason);

  @override
  AdjustmentDto submittedBy(AdjustmentPersonDto submittedBy) =>
      this(submittedBy: submittedBy);

  @override
  AdjustmentDto submittedAt(DateTime submittedAt) =>
      this(submittedAt: submittedAt);

  @override
  AdjustmentDto decidedBy(AdjustmentPersonDto? decidedBy) =>
      this(decidedBy: decidedBy);

  @override
  AdjustmentDto decidedAt(DateTime? decidedAt) => this(decidedAt: decidedAt);

  @override
  AdjustmentDto decisionReason(String? decisionReason) =>
      this(decisionReason: decisionReason);

  @override
  AdjustmentDto lineCount(num lineCount) => this(lineCount: lineCount);

  @override
  AdjustmentDto version(num version) => this(version: version);

  @override
  AdjustmentDto lines(List<AdjustmentLineDto>? lines) => this(lines: lines);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? gradebookId = const $CopyWithPlaceholder(),
    Object? className = const $CopyWithPlaceholder(),
    Object? subjectName = const $CopyWithPlaceholder(),
    Object? termName = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? submittedBy = const $CopyWithPlaceholder(),
    Object? submittedAt = const $CopyWithPlaceholder(),
    Object? decidedBy = const $CopyWithPlaceholder(),
    Object? decidedAt = const $CopyWithPlaceholder(),
    Object? decisionReason = const $CopyWithPlaceholder(),
    Object? lineCount = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? lines = const $CopyWithPlaceholder(),
  }) {
    return AdjustmentDto(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      gradebookId: gradebookId == const $CopyWithPlaceholder()
          ? _value.gradebookId
          // ignore: cast_nullable_to_non_nullable
          : gradebookId as num,
      className: className == const $CopyWithPlaceholder()
          ? _value.className
          // ignore: cast_nullable_to_non_nullable
          : className as String,
      subjectName: subjectName == const $CopyWithPlaceholder()
          ? _value.subjectName
          // ignore: cast_nullable_to_non_nullable
          : subjectName as String,
      termName: termName == const $CopyWithPlaceholder()
          ? _value.termName
          // ignore: cast_nullable_to_non_nullable
          : termName as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AdjustmentDtoStatusEnum,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      submittedBy: submittedBy == const $CopyWithPlaceholder()
          ? _value.submittedBy
          // ignore: cast_nullable_to_non_nullable
          : submittedBy as AdjustmentPersonDto,
      submittedAt: submittedAt == const $CopyWithPlaceholder()
          ? _value.submittedAt
          // ignore: cast_nullable_to_non_nullable
          : submittedAt as DateTime,
      decidedBy: decidedBy == const $CopyWithPlaceholder()
          ? _value.decidedBy
          // ignore: cast_nullable_to_non_nullable
          : decidedBy as AdjustmentPersonDto?,
      decidedAt: decidedAt == const $CopyWithPlaceholder()
          ? _value.decidedAt
          // ignore: cast_nullable_to_non_nullable
          : decidedAt as DateTime?,
      decisionReason: decisionReason == const $CopyWithPlaceholder()
          ? _value.decisionReason
          // ignore: cast_nullable_to_non_nullable
          : decisionReason as String?,
      lineCount: lineCount == const $CopyWithPlaceholder()
          ? _value.lineCount
          // ignore: cast_nullable_to_non_nullable
          : lineCount as num,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as num,
      lines: lines == const $CopyWithPlaceholder()
          ? _value.lines
          // ignore: cast_nullable_to_non_nullable
          : lines as List<AdjustmentLineDto>?,
    );
  }
}

extension $AdjustmentDtoCopyWith on AdjustmentDto {
  /// Returns a callable class that can be used as follows: `instanceOfAdjustmentDto.copyWith(...)` or like so:`instanceOfAdjustmentDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdjustmentDtoCWProxy get copyWith => _$AdjustmentDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdjustmentDto _$AdjustmentDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdjustmentDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'gradebookId',
          'className',
          'subjectName',
          'termName',
          'status',
          'reason',
          'submittedBy',
          'submittedAt',
          'decidedBy',
          'decidedAt',
          'decisionReason',
          'lineCount',
          'version',
        ],
      );
      final val = AdjustmentDto(
        id: $checkedConvert('id', (v) => v as String),
        gradebookId: $checkedConvert('gradebookId', (v) => v as num),
        className: $checkedConvert('className', (v) => v as String),
        subjectName: $checkedConvert('subjectName', (v) => v as String),
        termName: $checkedConvert('termName', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$AdjustmentDtoStatusEnumEnumMap, v),
        ),
        reason: $checkedConvert('reason', (v) => v as String),
        submittedBy: $checkedConvert(
          'submittedBy',
          (v) => AdjustmentPersonDto.fromJson(v as Map<String, dynamic>),
        ),
        submittedAt: $checkedConvert(
          'submittedAt',
          (v) => DateTime.parse(v as String),
        ),
        decidedBy: $checkedConvert(
          'decidedBy',
          (v) => v == null
              ? null
              : AdjustmentPersonDto.fromJson(v as Map<String, dynamic>),
        ),
        decidedAt: $checkedConvert(
          'decidedAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        decisionReason: $checkedConvert('decisionReason', (v) => v as String?),
        lineCount: $checkedConvert('lineCount', (v) => v as num),
        version: $checkedConvert('version', (v) => v as num),
        lines: $checkedConvert(
          'lines',
          (v) => (v as List<dynamic>?)
              ?.map(
                (e) => AdjustmentLineDto.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdjustmentDtoToJson(AdjustmentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'gradebookId': instance.gradebookId,
      'className': instance.className,
      'subjectName': instance.subjectName,
      'termName': instance.termName,
      'status': _$AdjustmentDtoStatusEnumEnumMap[instance.status]!,
      'reason': instance.reason,
      'submittedBy': instance.submittedBy.toJson(),
      'submittedAt': instance.submittedAt.toIso8601String(),
      'decidedBy': instance.decidedBy?.toJson(),
      'decidedAt': instance.decidedAt?.toIso8601String(),
      'decisionReason': instance.decisionReason,
      'lineCount': instance.lineCount,
      'version': instance.version,
      'lines': ?instance.lines?.map((e) => e.toJson()).toList(),
    };

const _$AdjustmentDtoStatusEnumEnumMap = {
  AdjustmentDtoStatusEnum.CHO_DUYET: 'CHO_DUYET',
  AdjustmentDtoStatusEnum.DA_DUYET: 'DA_DUYET',
  AdjustmentDtoStatusEnum.TU_CHOI: 'TU_CHOI',
  AdjustmentDtoStatusEnum.DA_HUY: 'DA_HUY',
};
