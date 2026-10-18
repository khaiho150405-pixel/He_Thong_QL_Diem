//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/template_column_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'versioned_definition_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VersionedDefinitionInput {
  /// Returns a new [VersionedDefinitionInput] instance.
  VersionedDefinitionInput({
    required this.name,

    this.description,

    required this.columns,

    required this.expectedVersion,
  });

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final String? description;

  /// Mọi cột 0..n-1 của tờ mẫu (cột không đọc dùng BO_QUA). Đúng một HO_TEN, tối đa một STT, ít nhất một DIEM; cặp (group, order) không trùng; mỗi DIEM_CHU trỏ tới một DIEM bằng pairedWith.
  @JsonKey(name: r'columns', required: true, includeIfNull: false)
  final List<TemplateColumnDto> columns;

  // minimum: 0
  @JsonKey(name: r'expectedVersion', required: true, includeIfNull: false)
  final num expectedVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VersionedDefinitionInput &&
          other.name == name &&
          other.description == description &&
          other.columns == columns &&
          other.expectedVersion == expectedVersion;

  @override
  int get hashCode =>
      name.hashCode +
      (description == null ? 0 : description.hashCode) +
      columns.hashCode +
      expectedVersion.hashCode;

  factory VersionedDefinitionInput.fromJson(Map<String, dynamic> json) =>
      _$VersionedDefinitionInputFromJson(json);

  Map<String, dynamic> toJson() => _$VersionedDefinitionInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
