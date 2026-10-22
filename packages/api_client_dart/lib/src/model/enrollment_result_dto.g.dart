// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enrollment_result_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EnrollmentResultDtoCWProxy {
  EnrollmentResultDto enrollment(EnrollmentDto enrollment);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EnrollmentResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EnrollmentResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  EnrollmentResultDto call({EnrollmentDto enrollment});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfEnrollmentResultDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfEnrollmentResultDto.copyWith.fieldName(...)`
class _$EnrollmentResultDtoCWProxyImpl implements _$EnrollmentResultDtoCWProxy {
  const _$EnrollmentResultDtoCWProxyImpl(this._value);

  final EnrollmentResultDto _value;

  @override
  EnrollmentResultDto enrollment(EnrollmentDto enrollment) =>
      this(enrollment: enrollment);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EnrollmentResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EnrollmentResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  EnrollmentResultDto call({
    Object? enrollment = const $CopyWithPlaceholder(),
  }) {
    return EnrollmentResultDto(
      enrollment: enrollment == const $CopyWithPlaceholder()
          ? _value.enrollment
          // ignore: cast_nullable_to_non_nullable
          : enrollment as EnrollmentDto,
    );
  }
}

extension $EnrollmentResultDtoCopyWith on EnrollmentResultDto {
  /// Returns a callable class that can be used as follows: `instanceOfEnrollmentResultDto.copyWith(...)` or like so:`instanceOfEnrollmentResultDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EnrollmentResultDtoCWProxy get copyWith =>
      _$EnrollmentResultDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnrollmentResultDto _$EnrollmentResultDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EnrollmentResultDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['enrollment']);
      final val = EnrollmentResultDto(
        enrollment: $checkedConvert(
          'enrollment',
          (v) => EnrollmentDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$EnrollmentResultDtoToJson(
  EnrollmentResultDto instance,
) => <String, dynamic>{'enrollment': instance.enrollment.toJson()};
