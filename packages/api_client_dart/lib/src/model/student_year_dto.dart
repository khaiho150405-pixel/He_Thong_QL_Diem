//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'student_year_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StudentYearDto {
  /// Returns a new [StudentYearDto] instance.
  StudentYearDto({
    required this.id,

    required this.name,

    required this.className,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final num id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'className', required: true, includeIfNull: false)
  final String className;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentYearDto &&
          other.id == id &&
          other.name == name &&
          other.className == className;

  @override
  int get hashCode => id.hashCode + name.hashCode + className.hashCode;

  factory StudentYearDto.fromJson(Map<String, dynamic> json) =>
      _$StudentYearDtoFromJson(json);

  Map<String, dynamic> toJson() => _$StudentYearDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
