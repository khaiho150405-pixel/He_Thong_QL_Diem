//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/missing_student_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'missing_students_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MissingStudentsDto {
  /// Returns a new [MissingStudentsDto] instance.
  MissingStudentsDto({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<MissingStudentDto> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissingStudentsDto && other.items == items;

  @override
  int get hashCode => items.hashCode;

  factory MissingStudentsDto.fromJson(Map<String, dynamic> json) =>
      _$MissingStudentsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MissingStudentsDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
