//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'review_approval_result_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReviewApprovalResultDto {
  /// Returns a new [ReviewApprovalResultDto] instance.
  ReviewApprovalResultDto({
    required this.ticketId,

    required this.ticketVersion,

    required this.gradebookId,

    required this.gradebookVersion,

    required this.reviewedRows,

    required this.machineMatchedRows,

    required this.humanCorrectedRows,

    required this.errorRows,

    required this.status,
  });

  @JsonKey(name: r'ticketId', required: true, includeIfNull: false)
  final String ticketId;

  @JsonKey(name: r'ticketVersion', required: true, includeIfNull: false)
  final num ticketVersion;

  @JsonKey(name: r'gradebookId', required: true, includeIfNull: false)
  final num gradebookId;

  @JsonKey(name: r'gradebookVersion', required: true, includeIfNull: false)
  final num gradebookVersion;

  @JsonKey(name: r'reviewedRows', required: true, includeIfNull: false)
  final num reviewedRows;

  @JsonKey(name: r'machineMatchedRows', required: true, includeIfNull: false)
  final num machineMatchedRows;

  @JsonKey(name: r'humanCorrectedRows', required: true, includeIfNull: false)
  final num humanCorrectedRows;

  @JsonKey(name: r'errorRows', required: true, includeIfNull: false)
  final num errorRows;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final ReviewApprovalResultDtoStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewApprovalResultDto &&
          other.ticketId == ticketId &&
          other.ticketVersion == ticketVersion &&
          other.gradebookId == gradebookId &&
          other.gradebookVersion == gradebookVersion &&
          other.reviewedRows == reviewedRows &&
          other.machineMatchedRows == machineMatchedRows &&
          other.humanCorrectedRows == humanCorrectedRows &&
          other.errorRows == errorRows &&
          other.status == status;

  @override
  int get hashCode =>
      ticketId.hashCode +
      ticketVersion.hashCode +
      gradebookId.hashCode +
      gradebookVersion.hashCode +
      reviewedRows.hashCode +
      machineMatchedRows.hashCode +
      humanCorrectedRows.hashCode +
      errorRows.hashCode +
      status.hashCode;

  factory ReviewApprovalResultDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewApprovalResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewApprovalResultDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ReviewApprovalResultDtoStatusEnum {
  @JsonValue(r'DA_DUYET')
  DA_DUYET(r'DA_DUYET');

  const ReviewApprovalResultDtoStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
