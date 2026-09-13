//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'calculation_history_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CalculationHistoryDto {
  /// Returns a new [CalculationHistoryDto] instance.
  CalculationHistoryDto({
    required this.id,

    required this.resultId,

    required this.calculatorId,

    required this.oldScore,

    required this.oldClassification,

    required this.newScore,

    required this.newClassification,

    required this.reason,

    required this.calculatedAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'resultId', required: true, includeIfNull: false)
  final String resultId;

  @JsonKey(name: r'calculatorId', required: true, includeIfNull: false)
  final num calculatorId;

  @JsonKey(name: r'oldScore', required: true, includeIfNull: true)
  final String? oldScore;

  @JsonKey(name: r'oldClassification', required: true, includeIfNull: true)
  final String? oldClassification;

  @JsonKey(name: r'newScore', required: true, includeIfNull: false)
  final String newScore;

  @JsonKey(name: r'newClassification', required: true, includeIfNull: false)
  final String newClassification;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @JsonKey(name: r'calculatedAt', required: true, includeIfNull: false)
  final DateTime calculatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculationHistoryDto &&
          other.id == id &&
          other.resultId == resultId &&
          other.calculatorId == calculatorId &&
          other.oldScore == oldScore &&
          other.oldClassification == oldClassification &&
          other.newScore == newScore &&
          other.newClassification == newClassification &&
          other.reason == reason &&
          other.calculatedAt == calculatedAt;

  @override
  int get hashCode =>
      id.hashCode +
      resultId.hashCode +
      calculatorId.hashCode +
      (oldScore == null ? 0 : oldScore.hashCode) +
      (oldClassification == null ? 0 : oldClassification.hashCode) +
      newScore.hashCode +
      newClassification.hashCode +
      reason.hashCode +
      calculatedAt.hashCode;

  factory CalculationHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$CalculationHistoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CalculationHistoryDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
