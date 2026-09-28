// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_kpi_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminKpiDtoCWProxy {
  AdminKpiDto totalStudents(num totalStudents);

  AdminKpiDto totalClasses(num totalClasses);

  AdminKpiDto totalTeachers(num totalTeachers);

  AdminKpiDto lockedGradebooks(num lockedGradebooks);

  AdminKpiDto totalGradebooks(num totalGradebooks);

  AdminKpiDto completionRate(num completionRate);

  AdminKpiDto pendingOcrTickets(num pendingOcrTickets);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminKpiDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminKpiDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminKpiDto call({
    num totalStudents,
    num totalClasses,
    num totalTeachers,
    num lockedGradebooks,
    num totalGradebooks,
    num completionRate,
    num pendingOcrTickets,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminKpiDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminKpiDto.copyWith.fieldName(...)`
class _$AdminKpiDtoCWProxyImpl implements _$AdminKpiDtoCWProxy {
  const _$AdminKpiDtoCWProxyImpl(this._value);

  final AdminKpiDto _value;

  @override
  AdminKpiDto totalStudents(num totalStudents) =>
      this(totalStudents: totalStudents);

  @override
  AdminKpiDto totalClasses(num totalClasses) =>
      this(totalClasses: totalClasses);

  @override
  AdminKpiDto totalTeachers(num totalTeachers) =>
      this(totalTeachers: totalTeachers);

  @override
  AdminKpiDto lockedGradebooks(num lockedGradebooks) =>
      this(lockedGradebooks: lockedGradebooks);

  @override
  AdminKpiDto totalGradebooks(num totalGradebooks) =>
      this(totalGradebooks: totalGradebooks);

  @override
  AdminKpiDto completionRate(num completionRate) =>
      this(completionRate: completionRate);

  @override
  AdminKpiDto pendingOcrTickets(num pendingOcrTickets) =>
      this(pendingOcrTickets: pendingOcrTickets);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminKpiDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminKpiDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminKpiDto call({
    Object? totalStudents = const $CopyWithPlaceholder(),
    Object? totalClasses = const $CopyWithPlaceholder(),
    Object? totalTeachers = const $CopyWithPlaceholder(),
    Object? lockedGradebooks = const $CopyWithPlaceholder(),
    Object? totalGradebooks = const $CopyWithPlaceholder(),
    Object? completionRate = const $CopyWithPlaceholder(),
    Object? pendingOcrTickets = const $CopyWithPlaceholder(),
  }) {
    return AdminKpiDto(
      totalStudents: totalStudents == const $CopyWithPlaceholder()
          ? _value.totalStudents
          // ignore: cast_nullable_to_non_nullable
          : totalStudents as num,
      totalClasses: totalClasses == const $CopyWithPlaceholder()
          ? _value.totalClasses
          // ignore: cast_nullable_to_non_nullable
          : totalClasses as num,
      totalTeachers: totalTeachers == const $CopyWithPlaceholder()
          ? _value.totalTeachers
          // ignore: cast_nullable_to_non_nullable
          : totalTeachers as num,
      lockedGradebooks: lockedGradebooks == const $CopyWithPlaceholder()
          ? _value.lockedGradebooks
          // ignore: cast_nullable_to_non_nullable
          : lockedGradebooks as num,
      totalGradebooks: totalGradebooks == const $CopyWithPlaceholder()
          ? _value.totalGradebooks
          // ignore: cast_nullable_to_non_nullable
          : totalGradebooks as num,
      completionRate: completionRate == const $CopyWithPlaceholder()
          ? _value.completionRate
          // ignore: cast_nullable_to_non_nullable
          : completionRate as num,
      pendingOcrTickets: pendingOcrTickets == const $CopyWithPlaceholder()
          ? _value.pendingOcrTickets
          // ignore: cast_nullable_to_non_nullable
          : pendingOcrTickets as num,
    );
  }
}

extension $AdminKpiDtoCopyWith on AdminKpiDto {
  /// Returns a callable class that can be used as follows: `instanceOfAdminKpiDto.copyWith(...)` or like so:`instanceOfAdminKpiDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminKpiDtoCWProxy get copyWith => _$AdminKpiDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminKpiDto _$AdminKpiDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AdminKpiDto',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'totalStudents',
        'totalClasses',
        'totalTeachers',
        'lockedGradebooks',
        'totalGradebooks',
        'completionRate',
        'pendingOcrTickets',
      ],
    );
    final val = AdminKpiDto(
      totalStudents: $checkedConvert('totalStudents', (v) => v as num),
      totalClasses: $checkedConvert('totalClasses', (v) => v as num),
      totalTeachers: $checkedConvert('totalTeachers', (v) => v as num),
      lockedGradebooks: $checkedConvert('lockedGradebooks', (v) => v as num),
      totalGradebooks: $checkedConvert('totalGradebooks', (v) => v as num),
      completionRate: $checkedConvert('completionRate', (v) => v as num),
      pendingOcrTickets: $checkedConvert('pendingOcrTickets', (v) => v as num),
    );
    return val;
  },
);

Map<String, dynamic> _$AdminKpiDtoToJson(AdminKpiDto instance) =>
    <String, dynamic>{
      'totalStudents': instance.totalStudents,
      'totalClasses': instance.totalClasses,
      'totalTeachers': instance.totalTeachers,
      'lockedGradebooks': instance.lockedGradebooks,
      'totalGradebooks': instance.totalGradebooks,
      'completionRate': instance.completionRate,
      'pendingOcrTickets': instance.pendingOcrTickets,
    };
