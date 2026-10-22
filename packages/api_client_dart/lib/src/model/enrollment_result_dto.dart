//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/enrollment_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'enrollment_result_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EnrollmentResultDto {
  /// Returns a new [EnrollmentResultDto] instance.
  EnrollmentResultDto({required this.enrollment});

  @JsonKey(name: r'enrollment', required: true, includeIfNull: false)
  final EnrollmentDto enrollment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnrollmentResultDto && other.enrollment == enrollment;

  @override
  int get hashCode => enrollment.hashCode;

  factory EnrollmentResultDto.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollmentResultDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
