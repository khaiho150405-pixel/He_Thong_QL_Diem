//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/teachers_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'teachers_import_result.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TeachersImportResult {
  /// Returns a new [TeachersImportResult] instance.
  TeachersImportResult({required this.imported, required this.items});

  @JsonKey(name: r'imported', required: true, includeIfNull: false)
  final num imported;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<TeachersDto> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeachersImportResult &&
          other.imported == imported &&
          other.items == items;

  @override
  int get hashCode => imported.hashCode + items.hashCode;

  factory TeachersImportResult.fromJson(Map<String, dynamic> json) =>
      _$TeachersImportResultFromJson(json);

  Map<String, dynamic> toJson() => _$TeachersImportResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
