// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publish_issue_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublishIssueDtoCWProxy {
  PublishIssueDto code(PublishIssueDtoCodeEnum code);

  PublishIssueDto severity(PublishIssueDtoSeverityEnum severity);

  PublishIssueDto classId(num classId);

  PublishIssueDto className(String className);

  PublishIssueDto subjectId(num subjectId);

  PublishIssueDto subjectName(String subjectName);

  PublishIssueDto gradebookId(num? gradebookId);

  PublishIssueDto studentIds(List<num>? studentIds);

  PublishIssueDto count(num? count);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublishIssueDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublishIssueDto(...).copyWith(id: 12, name: "My name")
  /// ````
  PublishIssueDto call({
    PublishIssueDtoCodeEnum code,
    PublishIssueDtoSeverityEnum severity,
    num classId,
    String className,
    num subjectId,
    String subjectName,
    num? gradebookId,
    List<num>? studentIds,
    num? count,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublishIssueDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublishIssueDto.copyWith.fieldName(...)`
class _$PublishIssueDtoCWProxyImpl implements _$PublishIssueDtoCWProxy {
  const _$PublishIssueDtoCWProxyImpl(this._value);

  final PublishIssueDto _value;

  @override
  PublishIssueDto code(PublishIssueDtoCodeEnum code) => this(code: code);

  @override
  PublishIssueDto severity(PublishIssueDtoSeverityEnum severity) =>
      this(severity: severity);

  @override
  PublishIssueDto classId(num classId) => this(classId: classId);

  @override
  PublishIssueDto className(String className) => this(className: className);

  @override
  PublishIssueDto subjectId(num subjectId) => this(subjectId: subjectId);

  @override
  PublishIssueDto subjectName(String subjectName) =>
      this(subjectName: subjectName);

  @override
  PublishIssueDto gradebookId(num? gradebookId) =>
      this(gradebookId: gradebookId);

  @override
  PublishIssueDto studentIds(List<num>? studentIds) =>
      this(studentIds: studentIds);

  @override
  PublishIssueDto count(num? count) => this(count: count);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublishIssueDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublishIssueDto(...).copyWith(id: 12, name: "My name")
  /// ````
  PublishIssueDto call({
    Object? code = const $CopyWithPlaceholder(),
    Object? severity = const $CopyWithPlaceholder(),
    Object? classId = const $CopyWithPlaceholder(),
    Object? className = const $CopyWithPlaceholder(),
    Object? subjectId = const $CopyWithPlaceholder(),
    Object? subjectName = const $CopyWithPlaceholder(),
    Object? gradebookId = const $CopyWithPlaceholder(),
    Object? studentIds = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
  }) {
    return PublishIssueDto(
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as PublishIssueDtoCodeEnum,
      severity: severity == const $CopyWithPlaceholder()
          ? _value.severity
          // ignore: cast_nullable_to_non_nullable
          : severity as PublishIssueDtoSeverityEnum,
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
      gradebookId: gradebookId == const $CopyWithPlaceholder()
          ? _value.gradebookId
          // ignore: cast_nullable_to_non_nullable
          : gradebookId as num?,
      studentIds: studentIds == const $CopyWithPlaceholder()
          ? _value.studentIds
          // ignore: cast_nullable_to_non_nullable
          : studentIds as List<num>?,
      count: count == const $CopyWithPlaceholder()
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as num?,
    );
  }
}

extension $PublishIssueDtoCopyWith on PublishIssueDto {
  /// Returns a callable class that can be used as follows: `instanceOfPublishIssueDto.copyWith(...)` or like so:`instanceOfPublishIssueDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublishIssueDtoCWProxy get copyWith => _$PublishIssueDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublishIssueDto _$PublishIssueDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PublishIssueDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'code',
          'severity',
          'classId',
          'className',
          'subjectId',
          'subjectName',
          'gradebookId',
          'studentIds',
          'count',
        ],
      );
      final val = PublishIssueDto(
        code: $checkedConvert(
          'code',
          (v) => $enumDecode(_$PublishIssueDtoCodeEnumEnumMap, v),
        ),
        severity: $checkedConvert(
          'severity',
          (v) => $enumDecode(_$PublishIssueDtoSeverityEnumEnumMap, v),
        ),
        classId: $checkedConvert('classId', (v) => v as num),
        className: $checkedConvert('className', (v) => v as String),
        subjectId: $checkedConvert('subjectId', (v) => v as num),
        subjectName: $checkedConvert('subjectName', (v) => v as String),
        gradebookId: $checkedConvert('gradebookId', (v) => v as num?),
        studentIds: $checkedConvert(
          'studentIds',
          (v) => (v as List<dynamic>?)?.map((e) => e as num).toList(),
        ),
        count: $checkedConvert('count', (v) => v as num?),
      );
      return val;
    });

Map<String, dynamic> _$PublishIssueDtoToJson(PublishIssueDto instance) =>
    <String, dynamic>{
      'code': _$PublishIssueDtoCodeEnumEnumMap[instance.code]!,
      'severity': _$PublishIssueDtoSeverityEnumEnumMap[instance.severity]!,
      'classId': instance.classId,
      'className': instance.className,
      'subjectId': instance.subjectId,
      'subjectName': instance.subjectName,
      'gradebookId': instance.gradebookId,
      'studentIds': instance.studentIds,
      'count': instance.count,
    };

const _$PublishIssueDtoCodeEnumEnumMap = {
  PublishIssueDtoCodeEnum.GRADEBOOK_MISSING: 'GRADEBOOK_MISSING',
  PublishIssueDtoCodeEnum.GRADEBOOK_NOT_LOCKED: 'GRADEBOOK_NOT_LOCKED',
  PublishIssueDtoCodeEnum.RECOGNITION_PENDING: 'RECOGNITION_PENDING',
  PublishIssueDtoCodeEnum.STUDENT_NOT_IN_GRADEBOOK: 'STUDENT_NOT_IN_GRADEBOOK',
  PublishIssueDtoCodeEnum.RESULTS_MISSING: 'RESULTS_MISSING',
  PublishIssueDtoCodeEnum.COLUMNS_WITHOUT_DEADLINE: 'COLUMNS_WITHOUT_DEADLINE',
};

const _$PublishIssueDtoSeverityEnumEnumMap = {
  PublishIssueDtoSeverityEnum.BLOCKING: 'BLOCKING',
  PublishIssueDtoSeverityEnum.WARNING: 'WARNING',
};
