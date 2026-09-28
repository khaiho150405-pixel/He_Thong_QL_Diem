//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_ocr_accuracy_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminOcrAccuracyDto {
  /// Returns a new [AdminOcrAccuracyDto] instance.
  AdminOcrAccuracyDto({
    required this.totalCells,

    required this.greenCount,

    required this.yellowCount,

    required this.redCount,

    required this.accuracyRate,
  });

  @JsonKey(name: r'totalCells', required: true, includeIfNull: false)
  final num totalCells;

  @JsonKey(name: r'greenCount', required: true, includeIfNull: false)
  final num greenCount;

  @JsonKey(name: r'yellowCount', required: true, includeIfNull: false)
  final num yellowCount;

  @JsonKey(name: r'redCount', required: true, includeIfNull: false)
  final num redCount;

  @JsonKey(name: r'accuracyRate', required: true, includeIfNull: false)
  final num accuracyRate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminOcrAccuracyDto &&
          other.totalCells == totalCells &&
          other.greenCount == greenCount &&
          other.yellowCount == yellowCount &&
          other.redCount == redCount &&
          other.accuracyRate == accuracyRate;

  @override
  int get hashCode =>
      totalCells.hashCode +
      greenCount.hashCode +
      yellowCount.hashCode +
      redCount.hashCode +
      accuracyRate.hashCode;

  factory AdminOcrAccuracyDto.fromJson(Map<String, dynamic> json) =>
      _$AdminOcrAccuracyDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AdminOcrAccuracyDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
