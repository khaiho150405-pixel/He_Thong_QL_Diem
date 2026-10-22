//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'promotion_result_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PromotionResultDto {
  /// Returns a new [PromotionResultDto] instance.
  PromotionResultDto({
    required this.processed,

    required this.promoted,

    required this.retained,

    required this.graduated,

    required this.withdrawn,
  });

  @JsonKey(name: r'processed', required: true, includeIfNull: false)
  final num processed;

  @JsonKey(name: r'promoted', required: true, includeIfNull: false)
  final num promoted;

  @JsonKey(name: r'retained', required: true, includeIfNull: false)
  final num retained;

  @JsonKey(name: r'graduated', required: true, includeIfNull: false)
  final num graduated;

  @JsonKey(name: r'withdrawn', required: true, includeIfNull: false)
  final num withdrawn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromotionResultDto &&
          other.processed == processed &&
          other.promoted == promoted &&
          other.retained == retained &&
          other.graduated == graduated &&
          other.withdrawn == withdrawn;

  @override
  int get hashCode =>
      processed.hashCode +
      promoted.hashCode +
      retained.hashCode +
      graduated.hashCode +
      withdrawn.hashCode;

  factory PromotionResultDto.fromJson(Map<String, dynamic> json) =>
      _$PromotionResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PromotionResultDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
