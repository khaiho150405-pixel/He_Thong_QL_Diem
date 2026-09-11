//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_gradebook_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateGradebookInput {
  /// Returns a new [CreateGradebookInput] instance.
  CreateGradebookInput({
    required this.classId,

    required this.subjectId,

    required this.termId,
  });

  @JsonKey(name: r'classId', required: true, includeIfNull: false)
  final num classId;

  @JsonKey(name: r'subjectId', required: true, includeIfNull: false)
  final num subjectId;

  @JsonKey(name: r'termId', required: true, includeIfNull: false)
  final num termId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateGradebookInput &&
          other.classId == classId &&
          other.subjectId == subjectId &&
          other.termId == termId;

  @override
  int get hashCode => classId.hashCode + subjectId.hashCode + termId.hashCode;

  factory CreateGradebookInput.fromJson(Map<String, dynamic> json) =>
      _$CreateGradebookInputFromJson(json);

  Map<String, dynamic> toJson() => _$CreateGradebookInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
