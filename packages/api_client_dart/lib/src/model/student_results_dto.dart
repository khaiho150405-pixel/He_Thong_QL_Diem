//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/student_subject_result_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'student_results_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StudentResultsDto {
  /// Returns a new [StudentResultsDto] instance.
  StudentResultsDto({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<StudentSubjectResultDto> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentResultsDto && other.items == items;

  @override
  int get hashCode => items.hashCode;

  factory StudentResultsDto.fromJson(Map<String, dynamic> json) =>
      _$StudentResultsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$StudentResultsDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
