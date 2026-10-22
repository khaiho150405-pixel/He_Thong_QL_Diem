// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_result_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TransferResultDtoCWProxy {
  TransferResultDto enrollment(EnrollmentDto enrollment);

  TransferResultDto affectedGradebooks(
    List<AffectedGradebookDto> affectedGradebooks,
  );

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TransferResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TransferResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TransferResultDto call({
    EnrollmentDto enrollment,
    List<AffectedGradebookDto> affectedGradebooks,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTransferResultDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTransferResultDto.copyWith.fieldName(...)`
class _$TransferResultDtoCWProxyImpl implements _$TransferResultDtoCWProxy {
  const _$TransferResultDtoCWProxyImpl(this._value);

  final TransferResultDto _value;

  @override
  TransferResultDto enrollment(EnrollmentDto enrollment) =>
      this(enrollment: enrollment);

  @override
  TransferResultDto affectedGradebooks(
    List<AffectedGradebookDto> affectedGradebooks,
  ) => this(affectedGradebooks: affectedGradebooks);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TransferResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TransferResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TransferResultDto call({
    Object? enrollment = const $CopyWithPlaceholder(),
    Object? affectedGradebooks = const $CopyWithPlaceholder(),
  }) {
    return TransferResultDto(
      enrollment: enrollment == const $CopyWithPlaceholder()
          ? _value.enrollment
          // ignore: cast_nullable_to_non_nullable
          : enrollment as EnrollmentDto,
      affectedGradebooks: affectedGradebooks == const $CopyWithPlaceholder()
          ? _value.affectedGradebooks
          // ignore: cast_nullable_to_non_nullable
          : affectedGradebooks as List<AffectedGradebookDto>,
    );
  }
}

extension $TransferResultDtoCopyWith on TransferResultDto {
  /// Returns a callable class that can be used as follows: `instanceOfTransferResultDto.copyWith(...)` or like so:`instanceOfTransferResultDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TransferResultDtoCWProxy get copyWith =>
      _$TransferResultDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferResultDto _$TransferResultDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('TransferResultDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['enrollment', 'affectedGradebooks']);
  final val = TransferResultDto(
    enrollment: $checkedConvert(
      'enrollment',
      (v) => EnrollmentDto.fromJson(v as Map<String, dynamic>),
    ),
    affectedGradebooks: $checkedConvert(
      'affectedGradebooks',
      (v) => (v as List<dynamic>)
          .map((e) => AffectedGradebookDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$TransferResultDtoToJson(TransferResultDto instance) =>
    <String, dynamic>{
      'enrollment': instance.enrollment.toJson(),
      'affectedGradebooks': instance.affectedGradebooks
          .map((e) => e.toJson())
          .toList(),
    };
