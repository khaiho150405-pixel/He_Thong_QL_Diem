//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gradebook_history_entry_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GradebookHistoryEntryDto {
  /// Returns a new [GradebookHistoryEntryDto] instance.
  GradebookHistoryEntryDto({
    required this.id,

    required this.cellId,

    required this.editor,

    required this.oldValue,

    required this.newValue,

    required this.reason,

    required this.timestamp,

    required this.studentName,

    required this.componentName,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'cellId', required: true, includeIfNull: false)
  final String cellId;

  @JsonKey(name: r'editor', required: true, includeIfNull: false)
  final num editor;

  @JsonKey(name: r'oldValue', required: true, includeIfNull: true)
  final String? oldValue;

  @JsonKey(name: r'newValue', required: true, includeIfNull: true)
  final String? newValue;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @JsonKey(name: r'timestamp', required: true, includeIfNull: false)
  final String timestamp;

  @JsonKey(name: r'studentName', required: true, includeIfNull: false)
  final String studentName;

  @JsonKey(name: r'componentName', required: true, includeIfNull: false)
  final String componentName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradebookHistoryEntryDto &&
          other.id == id &&
          other.cellId == cellId &&
          other.editor == editor &&
          other.oldValue == oldValue &&
          other.newValue == newValue &&
          other.reason == reason &&
          other.timestamp == timestamp &&
          other.studentName == studentName &&
          other.componentName == componentName;

  @override
  int get hashCode =>
      id.hashCode +
      cellId.hashCode +
      editor.hashCode +
      (oldValue == null ? 0 : oldValue.hashCode) +
      (newValue == null ? 0 : newValue.hashCode) +
      reason.hashCode +
      timestamp.hashCode +
      studentName.hashCode +
      componentName.hashCode;

  factory GradebookHistoryEntryDto.fromJson(Map<String, dynamic> json) =>
      _$GradebookHistoryEntryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GradebookHistoryEntryDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
