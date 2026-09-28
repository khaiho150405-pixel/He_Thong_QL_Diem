//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_recent_activity_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminRecentActivityDto {
  /// Returns a new [AdminRecentActivityDto] instance.
  AdminRecentActivityDto({
    required this.className,

    required this.subjectName,

    required this.teacherName,

    required this.status,

    required this.updatedAt,
  });

  @JsonKey(name: r'className', required: true, includeIfNull: false)
  final String className;

  @JsonKey(name: r'subjectName', required: true, includeIfNull: false)
  final String subjectName;

  @JsonKey(name: r'teacherName', required: true, includeIfNull: false)
  final String teacherName;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final String status;

  @JsonKey(name: r'updatedAt', required: true, includeIfNull: false)
  final String updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminRecentActivityDto &&
          other.className == className &&
          other.subjectName == subjectName &&
          other.teacherName == teacherName &&
          other.status == status &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      className.hashCode +
      subjectName.hashCode +
      teacherName.hashCode +
      status.hashCode +
      updatedAt.hashCode;

  factory AdminRecentActivityDto.fromJson(Map<String, dynamic> json) =>
      _$AdminRecentActivityDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AdminRecentActivityDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
