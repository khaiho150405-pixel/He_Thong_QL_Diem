//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'final_result_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FinalResultDto {
  /// Returns a new [FinalResultDto] instance.
  FinalResultDto({
    required this.id,

    required this.studentId,

    required this.studentName,

    required this.finalScore,

    required this.classification,

    required this.weightVersion,

    required this.policyVersion,

    required this.calculatedAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'studentId', required: true, includeIfNull: false)
  final num studentId;

  @JsonKey(name: r'studentName', required: true, includeIfNull: false)
  final String studentName;

  @JsonKey(name: r'finalScore', required: true, includeIfNull: false)
  final String finalScore;

  @JsonKey(name: r'classification', required: true, includeIfNull: false)
  final String classification;

  @JsonKey(name: r'weightVersion', required: true, includeIfNull: false)
  final String weightVersion;

  @JsonKey(name: r'policyVersion', required: true, includeIfNull: false)
  final String policyVersion;

  @JsonKey(name: r'calculatedAt', required: true, includeIfNull: false)
  final DateTime calculatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinalResultDto &&
          other.id == id &&
          other.studentId == studentId &&
          other.studentName == studentName &&
          other.finalScore == finalScore &&
          other.classification == classification &&
          other.weightVersion == weightVersion &&
          other.policyVersion == policyVersion &&
          other.calculatedAt == calculatedAt;

  @override
  int get hashCode =>
      id.hashCode +
      studentId.hashCode +
      studentName.hashCode +
      finalScore.hashCode +
      classification.hashCode +
      weightVersion.hashCode +
      policyVersion.hashCode +
      calculatedAt.hashCode;

  factory FinalResultDto.fromJson(Map<String, dynamic> json) =>
      _$FinalResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FinalResultDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
