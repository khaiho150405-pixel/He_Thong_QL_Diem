//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/skipped_student_dto.dart';
import 'package:api_client_dart/src/model/final_result_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'calculate_final_results_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CalculateFinalResultsDto {
  /// Returns a new [CalculateFinalResultsDto] instance.
  CalculateFinalResultsDto({
    required this.gradebookId,

    required this.gradebookVersion,

    required this.weightVersion,

    required this.policyVersion,

    required this.calculatedStudents,

    required this.skippedStudents,

    required this.results,

    required this.skipped,
  });

  @JsonKey(name: r'gradebookId', required: true, includeIfNull: false)
  final num gradebookId;

  @JsonKey(name: r'gradebookVersion', required: true, includeIfNull: false)
  final num gradebookVersion;

  @JsonKey(name: r'weightVersion', required: true, includeIfNull: false)
  final String weightVersion;

  @JsonKey(name: r'policyVersion', required: true, includeIfNull: false)
  final String policyVersion;

  @JsonKey(name: r'calculatedStudents', required: true, includeIfNull: false)
  final num calculatedStudents;

  @JsonKey(name: r'skippedStudents', required: true, includeIfNull: false)
  final num skippedStudents;

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<FinalResultDto> results;

  @JsonKey(name: r'skipped', required: true, includeIfNull: false)
  final List<SkippedStudentDto> skipped;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculateFinalResultsDto &&
          other.gradebookId == gradebookId &&
          other.gradebookVersion == gradebookVersion &&
          other.weightVersion == weightVersion &&
          other.policyVersion == policyVersion &&
          other.calculatedStudents == calculatedStudents &&
          other.skippedStudents == skippedStudents &&
          other.results == results &&
          other.skipped == skipped;

  @override
  int get hashCode =>
      gradebookId.hashCode +
      gradebookVersion.hashCode +
      weightVersion.hashCode +
      policyVersion.hashCode +
      calculatedStudents.hashCode +
      skippedStudents.hashCode +
      results.hashCode +
      skipped.hashCode;

  factory CalculateFinalResultsDto.fromJson(Map<String, dynamic> json) =>
      _$CalculateFinalResultsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CalculateFinalResultsDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
