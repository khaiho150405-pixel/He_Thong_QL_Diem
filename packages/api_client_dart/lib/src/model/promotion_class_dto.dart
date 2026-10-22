//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'promotion_class_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PromotionClassDto {
  /// Returns a new [PromotionClassDto] instance.
  PromotionClassDto({
    required this.id,

    required this.name,

    required this.grade,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final num id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'grade', required: true, includeIfNull: false)
  final num grade;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromotionClassDto &&
          other.id == id &&
          other.name == name &&
          other.grade == grade;

  @override
  int get hashCode => id.hashCode + name.hashCode + grade.hashCode;

  factory PromotionClassDto.fromJson(Map<String, dynamic> json) =>
      _$PromotionClassDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PromotionClassDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
