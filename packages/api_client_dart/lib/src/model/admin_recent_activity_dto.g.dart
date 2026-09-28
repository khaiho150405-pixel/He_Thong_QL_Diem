// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_recent_activity_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminRecentActivityDtoCWProxy {
  AdminRecentActivityDto className(String className);

  AdminRecentActivityDto subjectName(String subjectName);

  AdminRecentActivityDto teacherName(String teacherName);

  AdminRecentActivityDto status(String status);

  AdminRecentActivityDto updatedAt(String updatedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminRecentActivityDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminRecentActivityDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminRecentActivityDto call({
    String className,
    String subjectName,
    String teacherName,
    String status,
    String updatedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminRecentActivityDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminRecentActivityDto.copyWith.fieldName(...)`
class _$AdminRecentActivityDtoCWProxyImpl
    implements _$AdminRecentActivityDtoCWProxy {
  const _$AdminRecentActivityDtoCWProxyImpl(this._value);

  final AdminRecentActivityDto _value;

  @override
  AdminRecentActivityDto className(String className) =>
      this(className: className);

  @override
  AdminRecentActivityDto subjectName(String subjectName) =>
      this(subjectName: subjectName);

  @override
  AdminRecentActivityDto teacherName(String teacherName) =>
      this(teacherName: teacherName);

  @override
  AdminRecentActivityDto status(String status) => this(status: status);

  @override
  AdminRecentActivityDto updatedAt(String updatedAt) =>
      this(updatedAt: updatedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminRecentActivityDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminRecentActivityDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminRecentActivityDto call({
    Object? className = const $CopyWithPlaceholder(),
    Object? subjectName = const $CopyWithPlaceholder(),
    Object? teacherName = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return AdminRecentActivityDto(
      className: className == const $CopyWithPlaceholder()
          ? _value.className
          // ignore: cast_nullable_to_non_nullable
          : className as String,
      subjectName: subjectName == const $CopyWithPlaceholder()
          ? _value.subjectName
          // ignore: cast_nullable_to_non_nullable
          : subjectName as String,
      teacherName: teacherName == const $CopyWithPlaceholder()
          ? _value.teacherName
          // ignore: cast_nullable_to_non_nullable
          : teacherName as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as String,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as String,
    );
  }
}

extension $AdminRecentActivityDtoCopyWith on AdminRecentActivityDto {
  /// Returns a callable class that can be used as follows: `instanceOfAdminRecentActivityDto.copyWith(...)` or like so:`instanceOfAdminRecentActivityDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminRecentActivityDtoCWProxy get copyWith =>
      _$AdminRecentActivityDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminRecentActivityDto _$AdminRecentActivityDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminRecentActivityDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'className',
      'subjectName',
      'teacherName',
      'status',
      'updatedAt',
    ],
  );
  final val = AdminRecentActivityDto(
    className: $checkedConvert('className', (v) => v as String),
    subjectName: $checkedConvert('subjectName', (v) => v as String),
    teacherName: $checkedConvert('teacherName', (v) => v as String),
    status: $checkedConvert('status', (v) => v as String),
    updatedAt: $checkedConvert('updatedAt', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$AdminRecentActivityDtoToJson(
  AdminRecentActivityDto instance,
) => <String, dynamic>{
  'className': instance.className,
  'subjectName': instance.subjectName,
  'teacherName': instance.teacherName,
  'status': instance.status,
  'updatedAt': instance.updatedAt,
};
