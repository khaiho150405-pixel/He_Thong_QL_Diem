//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/students_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'students_import_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StudentsImportInput {
  /// Returns a new [StudentsImportInput] instance.
  StudentsImportInput({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<StudentsInput> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentsImportInput && other.items == items;

  @override
  int get hashCode => items.hashCode;

  factory StudentsImportInput.fromJson(Map<String, dynamic> json) =>
      _$StudentsImportInputFromJson(json);

  Map<String, dynamic> toJson() => _$StudentsImportInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
