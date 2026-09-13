//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'distribution_item_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DistributionItemDto {
  /// Returns a new [DistributionItemDto] instance.
  DistributionItemDto({required this.classification, required this.students});

  @JsonKey(name: r'classification', required: true, includeIfNull: false)
  final String classification;

  @JsonKey(name: r'students', required: true, includeIfNull: false)
  final num students;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistributionItemDto &&
          other.classification == classification &&
          other.students == students;

  @override
  int get hashCode => classification.hashCode + students.hashCode;

  factory DistributionItemDto.fromJson(Map<String, dynamic> json) =>
      _$DistributionItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DistributionItemDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
