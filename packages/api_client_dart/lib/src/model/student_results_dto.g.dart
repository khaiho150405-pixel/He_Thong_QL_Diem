// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_results_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StudentResultsDtoCWProxy {
  StudentResultsDto items(List<StudentSubjectResultDto> items);

  StudentResultsDto summary(StudentResultSummaryDto summary);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentResultsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentResultsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentResultsDto call({
    List<StudentSubjectResultDto> items,
    StudentResultSummaryDto summary,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStudentResultsDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStudentResultsDto.copyWith.fieldName(...)`
class _$StudentResultsDtoCWProxyImpl implements _$StudentResultsDtoCWProxy {
  const _$StudentResultsDtoCWProxyImpl(this._value);

  final StudentResultsDto _value;

  @override
  StudentResultsDto items(List<StudentSubjectResultDto> items) =>
      this(items: items);

  @override
  StudentResultsDto summary(StudentResultSummaryDto summary) =>
      this(summary: summary);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentResultsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentResultsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentResultsDto call({
    Object? items = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
  }) {
    return StudentResultsDto(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<StudentSubjectResultDto>,
      summary: summary == const $CopyWithPlaceholder()
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as StudentResultSummaryDto,
    );
  }
}

extension $StudentResultsDtoCopyWith on StudentResultsDto {
  /// Returns a callable class that can be used as follows: `instanceOfStudentResultsDto.copyWith(...)` or like so:`instanceOfStudentResultsDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StudentResultsDtoCWProxy get copyWith =>
      _$StudentResultsDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentResultsDto _$StudentResultsDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StudentResultsDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'summary']);
      final val = StudentResultsDto(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) =>
                    StudentSubjectResultDto.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        summary: $checkedConvert(
          'summary',
          (v) => StudentResultSummaryDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$StudentResultsDtoToJson(StudentResultsDto instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'summary': instance.summary.toJson(),
    };
