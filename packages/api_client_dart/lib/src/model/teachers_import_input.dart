//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/teachers_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'teachers_import_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TeachersImportInput {
  /// Returns a new [TeachersImportInput] instance.
  TeachersImportInput({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<TeachersInput> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeachersImportInput && other.items == items;

  @override
  int get hashCode => items.hashCode;

  factory TeachersImportInput.fromJson(Map<String, dynamic> json) =>
      _$TeachersImportInputFromJson(json);

  Map<String, dynamic> toJson() => _$TeachersImportInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
