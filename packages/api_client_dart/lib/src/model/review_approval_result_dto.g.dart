// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_approval_result_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReviewApprovalResultDtoCWProxy {
  ReviewApprovalResultDto ticketId(String ticketId);

  ReviewApprovalResultDto ticketVersion(num ticketVersion);

  ReviewApprovalResultDto gradebookId(num gradebookId);

  ReviewApprovalResultDto gradebookVersion(num gradebookVersion);

  ReviewApprovalResultDto reviewedRows(num reviewedRows);

  ReviewApprovalResultDto machineMatchedRows(num machineMatchedRows);

  ReviewApprovalResultDto humanCorrectedRows(num humanCorrectedRows);

  ReviewApprovalResultDto errorRows(num errorRows);

  ReviewApprovalResultDto status(ReviewApprovalResultDtoStatusEnum status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReviewApprovalResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReviewApprovalResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ReviewApprovalResultDto call({
    String ticketId,
    num ticketVersion,
    num gradebookId,
    num gradebookVersion,
    num reviewedRows,
    num machineMatchedRows,
    num humanCorrectedRows,
    num errorRows,
    ReviewApprovalResultDtoStatusEnum status,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReviewApprovalResultDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReviewApprovalResultDto.copyWith.fieldName(...)`
class _$ReviewApprovalResultDtoCWProxyImpl
    implements _$ReviewApprovalResultDtoCWProxy {
  const _$ReviewApprovalResultDtoCWProxyImpl(this._value);

  final ReviewApprovalResultDto _value;

  @override
  ReviewApprovalResultDto ticketId(String ticketId) => this(ticketId: ticketId);

  @override
  ReviewApprovalResultDto ticketVersion(num ticketVersion) =>
      this(ticketVersion: ticketVersion);

  @override
  ReviewApprovalResultDto gradebookId(num gradebookId) =>
      this(gradebookId: gradebookId);

  @override
  ReviewApprovalResultDto gradebookVersion(num gradebookVersion) =>
      this(gradebookVersion: gradebookVersion);

  @override
  ReviewApprovalResultDto reviewedRows(num reviewedRows) =>
      this(reviewedRows: reviewedRows);

  @override
  ReviewApprovalResultDto machineMatchedRows(num machineMatchedRows) =>
      this(machineMatchedRows: machineMatchedRows);

  @override
  ReviewApprovalResultDto humanCorrectedRows(num humanCorrectedRows) =>
      this(humanCorrectedRows: humanCorrectedRows);

  @override
  ReviewApprovalResultDto errorRows(num errorRows) =>
      this(errorRows: errorRows);

  @override
  ReviewApprovalResultDto status(ReviewApprovalResultDtoStatusEnum status) =>
      this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReviewApprovalResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReviewApprovalResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ReviewApprovalResultDto call({
    Object? ticketId = const $CopyWithPlaceholder(),
    Object? ticketVersion = const $CopyWithPlaceholder(),
    Object? gradebookId = const $CopyWithPlaceholder(),
    Object? gradebookVersion = const $CopyWithPlaceholder(),
    Object? reviewedRows = const $CopyWithPlaceholder(),
    Object? machineMatchedRows = const $CopyWithPlaceholder(),
    Object? humanCorrectedRows = const $CopyWithPlaceholder(),
    Object? errorRows = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return ReviewApprovalResultDto(
      ticketId: ticketId == const $CopyWithPlaceholder()
          ? _value.ticketId
          // ignore: cast_nullable_to_non_nullable
          : ticketId as String,
      ticketVersion: ticketVersion == const $CopyWithPlaceholder()
          ? _value.ticketVersion
          // ignore: cast_nullable_to_non_nullable
          : ticketVersion as num,
      gradebookId: gradebookId == const $CopyWithPlaceholder()
          ? _value.gradebookId
          // ignore: cast_nullable_to_non_nullable
          : gradebookId as num,
      gradebookVersion: gradebookVersion == const $CopyWithPlaceholder()
          ? _value.gradebookVersion
          // ignore: cast_nullable_to_non_nullable
          : gradebookVersion as num,
      reviewedRows: reviewedRows == const $CopyWithPlaceholder()
          ? _value.reviewedRows
          // ignore: cast_nullable_to_non_nullable
          : reviewedRows as num,
      machineMatchedRows: machineMatchedRows == const $CopyWithPlaceholder()
          ? _value.machineMatchedRows
          // ignore: cast_nullable_to_non_nullable
          : machineMatchedRows as num,
      humanCorrectedRows: humanCorrectedRows == const $CopyWithPlaceholder()
          ? _value.humanCorrectedRows
          // ignore: cast_nullable_to_non_nullable
          : humanCorrectedRows as num,
      errorRows: errorRows == const $CopyWithPlaceholder()
          ? _value.errorRows
          // ignore: cast_nullable_to_non_nullable
          : errorRows as num,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as ReviewApprovalResultDtoStatusEnum,
    );
  }
}

extension $ReviewApprovalResultDtoCopyWith on ReviewApprovalResultDto {
  /// Returns a callable class that can be used as follows: `instanceOfReviewApprovalResultDto.copyWith(...)` or like so:`instanceOfReviewApprovalResultDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReviewApprovalResultDtoCWProxy get copyWith =>
      _$ReviewApprovalResultDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewApprovalResultDto _$ReviewApprovalResultDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ReviewApprovalResultDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'ticketId',
      'ticketVersion',
      'gradebookId',
      'gradebookVersion',
      'reviewedRows',
      'machineMatchedRows',
      'humanCorrectedRows',
      'errorRows',
      'status',
    ],
  );
  final val = ReviewApprovalResultDto(
    ticketId: $checkedConvert('ticketId', (v) => v as String),
    ticketVersion: $checkedConvert('ticketVersion', (v) => v as num),
    gradebookId: $checkedConvert('gradebookId', (v) => v as num),
    gradebookVersion: $checkedConvert('gradebookVersion', (v) => v as num),
    reviewedRows: $checkedConvert('reviewedRows', (v) => v as num),
    machineMatchedRows: $checkedConvert('machineMatchedRows', (v) => v as num),
    humanCorrectedRows: $checkedConvert('humanCorrectedRows', (v) => v as num),
    errorRows: $checkedConvert('errorRows', (v) => v as num),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$ReviewApprovalResultDtoStatusEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$ReviewApprovalResultDtoToJson(
  ReviewApprovalResultDto instance,
) => <String, dynamic>{
  'ticketId': instance.ticketId,
  'ticketVersion': instance.ticketVersion,
  'gradebookId': instance.gradebookId,
  'gradebookVersion': instance.gradebookVersion,
  'reviewedRows': instance.reviewedRows,
  'machineMatchedRows': instance.machineMatchedRows,
  'humanCorrectedRows': instance.humanCorrectedRows,
  'errorRows': instance.errorRows,
  'status': _$ReviewApprovalResultDtoStatusEnumEnumMap[instance.status]!,
};

const _$ReviewApprovalResultDtoStatusEnumEnumMap = {
  ReviewApprovalResultDtoStatusEnum.DA_DUYET: 'DA_DUYET',
};
