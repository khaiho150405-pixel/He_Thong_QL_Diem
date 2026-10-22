//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'affected_gradebook_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AffectedGradebookDto {
  /// Returns a new [AffectedGradebookDto] instance.
  AffectedGradebookDto({
    required this.id,

    required this.subjectName,

    required this.termName,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final num id;

  @JsonKey(name: r'subjectName', required: true, includeIfNull: false)
  final String subjectName;

  @JsonKey(name: r'termName', required: true, includeIfNull: false)
  final String termName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AffectedGradebookDto &&
          other.id == id &&
          other.subjectName == subjectName &&
          other.termName == termName;

  @override
  int get hashCode => id.hashCode + subjectName.hashCode + termName.hashCode;

  factory AffectedGradebookDto.fromJson(Map<String, dynamic> json) =>
      _$AffectedGradebookDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AffectedGradebookDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
