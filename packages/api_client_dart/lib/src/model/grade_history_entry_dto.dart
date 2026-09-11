//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'grade_history_entry_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GradeHistoryEntryDto {
  /// Returns a new [GradeHistoryEntryDto] instance.
  GradeHistoryEntryDto({
    required this.id,

    required this.cellId,

    required this.editor,

    required this.oldValue,

    required this.newValue,

    required this.reason,

    required this.timestamp,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeHistoryEntryDto &&
          other.id == id &&
          other.cellId == cellId &&
          other.editor == editor &&
          other.oldValue == oldValue &&
          other.newValue == newValue &&
          other.reason == reason &&
          other.timestamp == timestamp;

  @override
  int get hashCode =>
      id.hashCode +
      cellId.hashCode +
      editor.hashCode +
      (oldValue == null ? 0 : oldValue.hashCode) +
      (newValue == null ? 0 : newValue.hashCode) +
      reason.hashCode +
      timestamp.hashCode;

  factory GradeHistoryEntryDto.fromJson(Map<String, dynamic> json) =>
      _$GradeHistoryEntryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GradeHistoryEntryDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
