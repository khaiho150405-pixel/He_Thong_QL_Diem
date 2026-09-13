//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/distribution_item_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gradebook_summary_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GradebookSummaryDto {
  /// Returns a new [GradebookSummaryDto] instance.
  GradebookSummaryDto({
    required this.gradebookId,

    required this.students,

    required this.average,

    required this.highest,

    required this.lowest,

    required this.passed,

    required this.failed,

    required this.distribution,
  });

  @JsonKey(name: r'gradebookId', required: true, includeIfNull: false)
  final num gradebookId;

  @JsonKey(name: r'students', required: true, includeIfNull: false)
  final num students;

  @JsonKey(name: r'average', required: true, includeIfNull: true)
  final String? average;

  @JsonKey(name: r'highest', required: true, includeIfNull: true)
  final String? highest;

  @JsonKey(name: r'lowest', required: true, includeIfNull: true)
  final String? lowest;

  @JsonKey(name: r'passed', required: true, includeIfNull: false)
  final num passed;

  @JsonKey(name: r'failed', required: true, includeIfNull: false)
  final num failed;

  @JsonKey(name: r'distribution', required: true, includeIfNull: false)
  final List<DistributionItemDto> distribution;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradebookSummaryDto &&
          other.gradebookId == gradebookId &&
          other.students == students &&
          other.average == average &&
          other.highest == highest &&
          other.lowest == lowest &&
          other.passed == passed &&
          other.failed == failed &&
          other.distribution == distribution;

  @override
  int get hashCode =>
      gradebookId.hashCode +
      students.hashCode +
      (average == null ? 0 : average.hashCode) +
      (highest == null ? 0 : highest.hashCode) +
      (lowest == null ? 0 : lowest.hashCode) +
      passed.hashCode +
      failed.hashCode +
      distribution.hashCode;

  factory GradebookSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$GradebookSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GradebookSummaryDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
