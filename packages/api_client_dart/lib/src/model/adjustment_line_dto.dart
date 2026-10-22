//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'adjustment_line_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdjustmentLineDto {
  /// Returns a new [AdjustmentLineDto] instance.
  AdjustmentLineDto({
    required this.cellId,

    required this.studentId,

    required this.studentName,

    required this.componentId,

    required this.componentName,

    required this.oldValue,

    required this.oldStatus,

    required this.newValue,

    required this.newExempt,

    required this.note,
  });

  @JsonKey(name: r'cellId', required: true, includeIfNull: false)
  final String cellId;

  @JsonKey(name: r'studentId', required: true, includeIfNull: false)
  final num studentId;

  @JsonKey(name: r'studentName', required: true, includeIfNull: false)
  final String studentName;

  @JsonKey(name: r'componentId', required: true, includeIfNull: false)
  final num componentId;

  @JsonKey(name: r'componentName', required: true, includeIfNull: false)
  final String componentName;

  @JsonKey(name: r'oldValue', required: true, includeIfNull: true)
  final String? oldValue;

  @JsonKey(name: r'oldStatus', required: true, includeIfNull: false)
  final AdjustmentLineDtoOldStatusEnum oldStatus;

  @JsonKey(name: r'newValue', required: true, includeIfNull: true)
  final String? newValue;

  @JsonKey(name: r'newExempt', required: true, includeIfNull: false)
  final bool newExempt;

  @JsonKey(name: r'note', required: true, includeIfNull: true)
  final String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdjustmentLineDto &&
          other.cellId == cellId &&
          other.studentId == studentId &&
          other.studentName == studentName &&
          other.componentId == componentId &&
          other.componentName == componentName &&
          other.oldValue == oldValue &&
          other.oldStatus == oldStatus &&
          other.newValue == newValue &&
          other.newExempt == newExempt &&
          other.note == note;

  @override
  int get hashCode =>
      cellId.hashCode +
      studentId.hashCode +
      studentName.hashCode +
      componentId.hashCode +
      componentName.hashCode +
      (oldValue == null ? 0 : oldValue.hashCode) +
      oldStatus.hashCode +
      (newValue == null ? 0 : newValue.hashCode) +
      newExempt.hashCode +
      (note == null ? 0 : note.hashCode);

  factory AdjustmentLineDto.fromJson(Map<String, dynamic> json) =>
      _$AdjustmentLineDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AdjustmentLineDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdjustmentLineDtoOldStatusEnum {
  @JsonValue(r'CHUA_CO')
  CHUA_CO(r'CHUA_CO'),
  @JsonValue(r'CHO_DOI_CHIEU')
  CHO_DOI_CHIEU(r'CHO_DOI_CHIEU'),
  @JsonValue(r'DA_DUYET')
  DA_DUYET(r'DA_DUYET'),
  @JsonValue(r'MIEN')
  MIEN(r'MIEN');

  const AdjustmentLineDtoOldStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
