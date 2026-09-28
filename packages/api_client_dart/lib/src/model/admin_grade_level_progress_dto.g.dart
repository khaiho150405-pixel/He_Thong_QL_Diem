// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_grade_level_progress_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminGradeLevelProgressDtoCWProxy {
  AdminGradeLevelProgressDto grade(num grade);

  AdminGradeLevelProgressDto title(String title);

  AdminGradeLevelProgressDto lockedClasses(num lockedClasses);

  AdminGradeLevelProgressDto totalClasses(num totalClasses);

  AdminGradeLevelProgressDto percentage(num percentage);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminGradeLevelProgressDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminGradeLevelProgressDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminGradeLevelProgressDto call({
    num grade,
    String title,
    num lockedClasses,
    num totalClasses,
    num percentage,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminGradeLevelProgressDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminGradeLevelProgressDto.copyWith.fieldName(...)`
class _$AdminGradeLevelProgressDtoCWProxyImpl
    implements _$AdminGradeLevelProgressDtoCWProxy {
  const _$AdminGradeLevelProgressDtoCWProxyImpl(this._value);

  final AdminGradeLevelProgressDto _value;

  @override
  AdminGradeLevelProgressDto grade(num grade) => this(grade: grade);

  @override
  AdminGradeLevelProgressDto title(String title) => this(title: title);

  @override
  AdminGradeLevelProgressDto lockedClasses(num lockedClasses) =>
      this(lockedClasses: lockedClasses);

  @override
  AdminGradeLevelProgressDto totalClasses(num totalClasses) =>
      this(totalClasses: totalClasses);

  @override
  AdminGradeLevelProgressDto percentage(num percentage) =>
      this(percentage: percentage);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminGradeLevelProgressDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminGradeLevelProgressDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminGradeLevelProgressDto call({
    Object? grade = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? lockedClasses = const $CopyWithPlaceholder(),
    Object? totalClasses = const $CopyWithPlaceholder(),
    Object? percentage = const $CopyWithPlaceholder(),
  }) {
    return AdminGradeLevelProgressDto(
      grade: grade == const $CopyWithPlaceholder()
          ? _value.grade
          // ignore: cast_nullable_to_non_nullable
          : grade as num,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      lockedClasses: lockedClasses == const $CopyWithPlaceholder()
          ? _value.lockedClasses
          // ignore: cast_nullable_to_non_nullable
          : lockedClasses as num,
      totalClasses: totalClasses == const $CopyWithPlaceholder()
          ? _value.totalClasses
          // ignore: cast_nullable_to_non_nullable
          : totalClasses as num,
      percentage: percentage == const $CopyWithPlaceholder()
          ? _value.percentage
          // ignore: cast_nullable_to_non_nullable
          : percentage as num,
    );
  }
}

extension $AdminGradeLevelProgressDtoCopyWith on AdminGradeLevelProgressDto {
  /// Returns a callable class that can be used as follows: `instanceOfAdminGradeLevelProgressDto.copyWith(...)` or like so:`instanceOfAdminGradeLevelProgressDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminGradeLevelProgressDtoCWProxy get copyWith =>
      _$AdminGradeLevelProgressDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminGradeLevelProgressDto _$AdminGradeLevelProgressDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminGradeLevelProgressDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'grade',
      'title',
      'lockedClasses',
      'totalClasses',
      'percentage',
    ],
  );
  final val = AdminGradeLevelProgressDto(
    grade: $checkedConvert('grade', (v) => v as num),
    title: $checkedConvert('title', (v) => v as String),
    lockedClasses: $checkedConvert('lockedClasses', (v) => v as num),
    totalClasses: $checkedConvert('totalClasses', (v) => v as num),
    percentage: $checkedConvert('percentage', (v) => v as num),
  );
  return val;
});

Map<String, dynamic> _$AdminGradeLevelProgressDtoToJson(
  AdminGradeLevelProgressDto instance,
) => <String, dynamic>{
  'grade': instance.grade,
  'title': instance.title,
  'lockedClasses': instance.lockedClasses,
  'totalClasses': instance.totalClasses,
  'percentage': instance.percentage,
};
