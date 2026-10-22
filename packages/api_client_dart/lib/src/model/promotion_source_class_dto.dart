//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'promotion_source_class_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PromotionSourceClassDto {
  /// Returns a new [PromotionSourceClassDto] instance.
  PromotionSourceClassDto({
    required this.id,

    required this.name,

    required this.grade,

    required this.yearId,

    required this.yearName,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final num id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'grade', required: true, includeIfNull: false)
  final num grade;

  @JsonKey(name: r'yearId', required: true, includeIfNull: false)
  final num yearId;

  @JsonKey(name: r'yearName', required: true, includeIfNull: false)
  final String yearName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromotionSourceClassDto &&
          other.id == id &&
          other.name == name &&
          other.grade == grade &&
          other.yearId == yearId &&
          other.yearName == yearName;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      grade.hashCode +
      yearId.hashCode +
      yearName.hashCode;

  factory PromotionSourceClassDto.fromJson(Map<String, dynamic> json) =>
      _$PromotionSourceClassDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PromotionSourceClassDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
