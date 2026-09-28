// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_result_summary_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StudentResultSummaryDtoCWProxy {
  StudentResultSummaryDto termId(num? termId);

  StudentResultSummaryDto termName(String? termName);

  StudentResultSummaryDto className(String className);

  StudentResultSummaryDto averageScore(String? averageScore);

  StudentResultSummaryDto publishedSubjects(num publishedSubjects);

  StudentResultSummaryDto totalSubjects(num totalSubjects);

  StudentResultSummaryDto classRank(num? classRank);

  StudentResultSummaryDto classSize(num classSize);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentResultSummaryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentResultSummaryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentResultSummaryDto call({
    num? termId,
    String? termName,
    String className,
    String? averageScore,
    num publishedSubjects,
    num totalSubjects,
    num? classRank,
    num classSize,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStudentResultSummaryDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStudentResultSummaryDto.copyWith.fieldName(...)`
class _$StudentResultSummaryDtoCWProxyImpl
    implements _$StudentResultSummaryDtoCWProxy {
  const _$StudentResultSummaryDtoCWProxyImpl(this._value);

  final StudentResultSummaryDto _value;

  @override
  StudentResultSummaryDto termId(num? termId) => this(termId: termId);

  @override
  StudentResultSummaryDto termName(String? termName) =>
      this(termName: termName);

  @override
  StudentResultSummaryDto className(String className) =>
      this(className: className);

  @override
  StudentResultSummaryDto averageScore(String? averageScore) =>
      this(averageScore: averageScore);

  @override
  StudentResultSummaryDto publishedSubjects(num publishedSubjects) =>
      this(publishedSubjects: publishedSubjects);

  @override
  StudentResultSummaryDto totalSubjects(num totalSubjects) =>
      this(totalSubjects: totalSubjects);

  @override
  StudentResultSummaryDto classRank(num? classRank) =>
      this(classRank: classRank);

  @override
  StudentResultSummaryDto classSize(num classSize) =>
      this(classSize: classSize);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentResultSummaryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentResultSummaryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentResultSummaryDto call({
    Object? termId = const $CopyWithPlaceholder(),
    Object? termName = const $CopyWithPlaceholder(),
    Object? className = const $CopyWithPlaceholder(),
    Object? averageScore = const $CopyWithPlaceholder(),
    Object? publishedSubjects = const $CopyWithPlaceholder(),
    Object? totalSubjects = const $CopyWithPlaceholder(),
    Object? classRank = const $CopyWithPlaceholder(),
    Object? classSize = const $CopyWithPlaceholder(),
  }) {
    return StudentResultSummaryDto(
      termId: termId == const $CopyWithPlaceholder()
          ? _value.termId
          // ignore: cast_nullable_to_non_nullable
          : termId as num?,
      termName: termName == const $CopyWithPlaceholder()
          ? _value.termName
          // ignore: cast_nullable_to_non_nullable
          : termName as String?,
      className: className == const $CopyWithPlaceholder()
          ? _value.className
          // ignore: cast_nullable_to_non_nullable
          : className as String,
      averageScore: averageScore == const $CopyWithPlaceholder()
          ? _value.averageScore
          // ignore: cast_nullable_to_non_nullable
          : averageScore as String?,
      publishedSubjects: publishedSubjects == const $CopyWithPlaceholder()
          ? _value.publishedSubjects
          // ignore: cast_nullable_to_non_nullable
          : publishedSubjects as num,
      totalSubjects: totalSubjects == const $CopyWithPlaceholder()
          ? _value.totalSubjects
          // ignore: cast_nullable_to_non_nullable
          : totalSubjects as num,
      classRank: classRank == const $CopyWithPlaceholder()
          ? _value.classRank
          // ignore: cast_nullable_to_non_nullable
          : classRank as num?,
      classSize: classSize == const $CopyWithPlaceholder()
          ? _value.classSize
          // ignore: cast_nullable_to_non_nullable
          : classSize as num,
    );
  }
}

extension $StudentResultSummaryDtoCopyWith on StudentResultSummaryDto {
  /// Returns a callable class that can be used as follows: `instanceOfStudentResultSummaryDto.copyWith(...)` or like so:`instanceOfStudentResultSummaryDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StudentResultSummaryDtoCWProxy get copyWith =>
      _$StudentResultSummaryDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentResultSummaryDto _$StudentResultSummaryDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StudentResultSummaryDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'termId',
      'termName',
      'className',
      'averageScore',
      'publishedSubjects',
      'totalSubjects',
      'classRank',
      'classSize',
    ],
  );
  final val = StudentResultSummaryDto(
    termId: $checkedConvert('termId', (v) => v as num?),
    termName: $checkedConvert('termName', (v) => v as String?),
    className: $checkedConvert('className', (v) => v as String),
    averageScore: $checkedConvert('averageScore', (v) => v as String?),
    publishedSubjects: $checkedConvert('publishedSubjects', (v) => v as num),
    totalSubjects: $checkedConvert('totalSubjects', (v) => v as num),
    classRank: $checkedConvert('classRank', (v) => v as num?),
    classSize: $checkedConvert('classSize', (v) => v as num),
  );
  return val;
});

Map<String, dynamic> _$StudentResultSummaryDtoToJson(
  StudentResultSummaryDto instance,
) => <String, dynamic>{
  'termId': instance.termId,
  'termName': instance.termName,
  'className': instance.className,
  'averageScore': instance.averageScore,
  'publishedSubjects': instance.publishedSubjects,
  'totalSubjects': instance.totalSubjects,
  'classRank': instance.classRank,
  'classSize': instance.classSize,
};
