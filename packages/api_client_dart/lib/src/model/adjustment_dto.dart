//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/adjustment_person_dto.dart';
import 'package:api_client_dart/src/model/adjustment_line_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'adjustment_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdjustmentDto {
  /// Returns a new [AdjustmentDto] instance.
  AdjustmentDto({
    required this.id,

    required this.gradebookId,

    required this.className,

    required this.subjectName,

    required this.termName,

    required this.status,

    required this.reason,

    required this.submittedBy,

    required this.submittedAt,

    required this.decidedBy,

    required this.decidedAt,

    required this.decisionReason,

    required this.lineCount,

    required this.version,

    this.lines,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'gradebookId', required: true, includeIfNull: false)
  final num gradebookId;

  @JsonKey(name: r'className', required: true, includeIfNull: false)
  final String className;

  @JsonKey(name: r'subjectName', required: true, includeIfNull: false)
  final String subjectName;

  @JsonKey(name: r'termName', required: true, includeIfNull: false)
  final String termName;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AdjustmentDtoStatusEnum status;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @JsonKey(name: r'submittedBy', required: true, includeIfNull: false)
  final AdjustmentPersonDto submittedBy;

  @JsonKey(name: r'submittedAt', required: true, includeIfNull: false)
  final DateTime submittedAt;

  @JsonKey(name: r'decidedBy', required: true, includeIfNull: true)
  final AdjustmentPersonDto? decidedBy;

  @JsonKey(name: r'decidedAt', required: true, includeIfNull: true)
  final DateTime? decidedAt;

  @JsonKey(name: r'decisionReason', required: true, includeIfNull: true)
  final String? decisionReason;

  @JsonKey(name: r'lineCount', required: true, includeIfNull: false)
  final num lineCount;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final num version;

  /// Chỉ có trong chi tiết một phiếu
  @JsonKey(name: r'lines', required: false, includeIfNull: false)
  final List<AdjustmentLineDto>? lines;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdjustmentDto &&
          other.id == id &&
          other.gradebookId == gradebookId &&
          other.className == className &&
          other.subjectName == subjectName &&
          other.termName == termName &&
          other.status == status &&
          other.reason == reason &&
          other.submittedBy == submittedBy &&
          other.submittedAt == submittedAt &&
          other.decidedBy == decidedBy &&
          other.decidedAt == decidedAt &&
          other.decisionReason == decisionReason &&
          other.lineCount == lineCount &&
          other.version == version &&
          other.lines == lines;

  @override
  int get hashCode =>
      id.hashCode +
      gradebookId.hashCode +
      className.hashCode +
      subjectName.hashCode +
      termName.hashCode +
      status.hashCode +
      reason.hashCode +
      submittedBy.hashCode +
      submittedAt.hashCode +
      (decidedBy == null ? 0 : decidedBy.hashCode) +
      (decidedAt == null ? 0 : decidedAt.hashCode) +
      (decisionReason == null ? 0 : decisionReason.hashCode) +
      lineCount.hashCode +
      version.hashCode +
      lines.hashCode;

  factory AdjustmentDto.fromJson(Map<String, dynamic> json) =>
      _$AdjustmentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AdjustmentDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdjustmentDtoStatusEnum {
  @JsonValue(r'CHO_DUYET')
  CHO_DUYET(r'CHO_DUYET'),
  @JsonValue(r'DA_DUYET')
  DA_DUYET(r'DA_DUYET'),
  @JsonValue(r'TU_CHOI')
  TU_CHOI(r'TU_CHOI'),
  @JsonValue(r'DA_HUY')
  DA_HUY(r'DA_HUY');

  const AdjustmentDtoStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
