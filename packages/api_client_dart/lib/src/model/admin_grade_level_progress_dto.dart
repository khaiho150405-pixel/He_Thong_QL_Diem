//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_grade_level_progress_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminGradeLevelProgressDto {
  /// Returns a new [AdminGradeLevelProgressDto] instance.
  AdminGradeLevelProgressDto({
    required this.grade,

    required this.title,

    required this.lockedClasses,

    required this.totalClasses,

    required this.percentage,
  });

  @JsonKey(name: r'grade', required: true, includeIfNull: false)
  final num grade;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'lockedClasses', required: true, includeIfNull: false)
  final num lockedClasses;

  @JsonKey(name: r'totalClasses', required: true, includeIfNull: false)
  final num totalClasses;

  @JsonKey(name: r'percentage', required: true, includeIfNull: false)
  final num percentage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminGradeLevelProgressDto &&
          other.grade == grade &&
          other.title == title &&
          other.lockedClasses == lockedClasses &&
          other.totalClasses == totalClasses &&
          other.percentage == percentage;

  @override
  int get hashCode =>
      grade.hashCode +
      title.hashCode +
      lockedClasses.hashCode +
      totalClasses.hashCode +
      percentage.hashCode;

  factory AdminGradeLevelProgressDto.fromJson(Map<String, dynamic> json) =>
      _$AdminGradeLevelProgressDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AdminGradeLevelProgressDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
