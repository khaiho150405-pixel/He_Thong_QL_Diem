// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enrollment_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EnrollmentDtoCWProxy {
  EnrollmentDto id(String id);

  EnrollmentDto classId(num classId);

  EnrollmentDto className(String className);

  EnrollmentDto grade(num grade);

  EnrollmentDto yearId(num yearId);

  EnrollmentDto yearName(String yearName);

  EnrollmentDto fromDate(String fromDate);

  EnrollmentDto toDate(String? toDate);

  EnrollmentDto status(EnrollmentDtoStatusEnum status);

  EnrollmentDto reason(String? reason);

  EnrollmentDto actorName(String? actorName);

  EnrollmentDto createdAt(DateTime createdAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EnrollmentDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EnrollmentDto(...).copyWith(id: 12, name: "My name")
  /// ````
  EnrollmentDto call({
    String id,
    num classId,
    String className,
    num grade,
    num yearId,
    String yearName,
    String fromDate,
    String? toDate,
    EnrollmentDtoStatusEnum status,
    String? reason,
    String? actorName,
    DateTime createdAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfEnrollmentDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfEnrollmentDto.copyWith.fieldName(...)`
class _$EnrollmentDtoCWProxyImpl implements _$EnrollmentDtoCWProxy {
  const _$EnrollmentDtoCWProxyImpl(this._value);

  final EnrollmentDto _value;

  @override
  EnrollmentDto id(String id) => this(id: id);

  @override
  EnrollmentDto classId(num classId) => this(classId: classId);

  @override
  EnrollmentDto className(String className) => this(className: className);

  @override
  EnrollmentDto grade(num grade) => this(grade: grade);

  @override
  EnrollmentDto yearId(num yearId) => this(yearId: yearId);

  @override
  EnrollmentDto yearName(String yearName) => this(yearName: yearName);

  @override
  EnrollmentDto fromDate(String fromDate) => this(fromDate: fromDate);

  @override
  EnrollmentDto toDate(String? toDate) => this(toDate: toDate);

  @override
  EnrollmentDto status(EnrollmentDtoStatusEnum status) => this(status: status);

  @override
  EnrollmentDto reason(String? reason) => this(reason: reason);

  @override
  EnrollmentDto actorName(String? actorName) => this(actorName: actorName);

  @override
  EnrollmentDto createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EnrollmentDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EnrollmentDto(...).copyWith(id: 12, name: "My name")
  /// ````
  EnrollmentDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? classId = const $CopyWithPlaceholder(),
    Object? className = const $CopyWithPlaceholder(),
    Object? grade = const $CopyWithPlaceholder(),
    Object? yearId = const $CopyWithPlaceholder(),
    Object? yearName = const $CopyWithPlaceholder(),
    Object? fromDate = const $CopyWithPlaceholder(),
    Object? toDate = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? actorName = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return EnrollmentDto(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      classId: classId == const $CopyWithPlaceholder()
          ? _value.classId
          // ignore: cast_nullable_to_non_nullable
          : classId as num,
      className: className == const $CopyWithPlaceholder()
          ? _value.className
          // ignore: cast_nullable_to_non_nullable
          : className as String,
      grade: grade == const $CopyWithPlaceholder()
          ? _value.grade
          // ignore: cast_nullable_to_non_nullable
          : grade as num,
      yearId: yearId == const $CopyWithPlaceholder()
          ? _value.yearId
          // ignore: cast_nullable_to_non_nullable
          : yearId as num,
      yearName: yearName == const $CopyWithPlaceholder()
          ? _value.yearName
          // ignore: cast_nullable_to_non_nullable
          : yearName as String,
      fromDate: fromDate == const $CopyWithPlaceholder()
          ? _value.fromDate
          // ignore: cast_nullable_to_non_nullable
          : fromDate as String,
      toDate: toDate == const $CopyWithPlaceholder()
          ? _value.toDate
          // ignore: cast_nullable_to_non_nullable
          : toDate as String?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as EnrollmentDtoStatusEnum,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String?,
      actorName: actorName == const $CopyWithPlaceholder()
          ? _value.actorName
          // ignore: cast_nullable_to_non_nullable
          : actorName as String?,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $EnrollmentDtoCopyWith on EnrollmentDto {
  /// Returns a callable class that can be used as follows: `instanceOfEnrollmentDto.copyWith(...)` or like so:`instanceOfEnrollmentDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EnrollmentDtoCWProxy get copyWith => _$EnrollmentDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnrollmentDto _$EnrollmentDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EnrollmentDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'classId',
          'className',
          'grade',
          'yearId',
          'yearName',
          'fromDate',
          'toDate',
          'status',
          'reason',
          'actorName',
          'createdAt',
        ],
      );
      final val = EnrollmentDto(
        id: $checkedConvert('id', (v) => v as String),
        classId: $checkedConvert('classId', (v) => v as num),
        className: $checkedConvert('className', (v) => v as String),
        grade: $checkedConvert('grade', (v) => v as num),
        yearId: $checkedConvert('yearId', (v) => v as num),
        yearName: $checkedConvert('yearName', (v) => v as String),
        fromDate: $checkedConvert('fromDate', (v) => v as String),
        toDate: $checkedConvert('toDate', (v) => v as String?),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$EnrollmentDtoStatusEnumEnumMap, v),
        ),
        reason: $checkedConvert('reason', (v) => v as String?),
        actorName: $checkedConvert('actorName', (v) => v as String?),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$EnrollmentDtoToJson(EnrollmentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'classId': instance.classId,
      'className': instance.className,
      'grade': instance.grade,
      'yearId': instance.yearId,
      'yearName': instance.yearName,
      'fromDate': instance.fromDate,
      'toDate': instance.toDate,
      'status': _$EnrollmentDtoStatusEnumEnumMap[instance.status]!,
      'reason': instance.reason,
      'actorName': instance.actorName,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$EnrollmentDtoStatusEnumEnumMap = {
  EnrollmentDtoStatusEnum.DANG_HOC: 'DANG_HOC',
  EnrollmentDtoStatusEnum.LEN_LOP: 'LEN_LOP',
  EnrollmentDtoStatusEnum.LUU_BAN: 'LUU_BAN',
  EnrollmentDtoStatusEnum.DA_CHUYEN_LOP: 'DA_CHUYEN_LOP',
  EnrollmentDtoStatusEnum.NGHI_HOC: 'NGHI_HOC',
  EnrollmentDtoStatusEnum.TOT_NGHIEP: 'TOT_NGHIEP',
};
