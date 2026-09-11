//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'grade_cell_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GradeCellDto {
  /// Returns a new [GradeCellDto] instance.
  GradeCellDto({
    required this.id,

    required this.studentId,

    required this.studentName,

    required this.active,

    required this.componentId,

    required this.componentName,

    required this.coefficient,

    required this.required_,

    required this.displayOrder,

    required this.value,

    required this.status,

    required this.source_,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'studentId', required: true, includeIfNull: false)
  final num studentId;

  @JsonKey(name: r'studentName', required: true, includeIfNull: false)
  final String studentName;

  @JsonKey(name: r'active', required: true, includeIfNull: false)
  final bool active;

  @JsonKey(name: r'componentId', required: true, includeIfNull: false)
  final num componentId;

  @JsonKey(name: r'componentName', required: true, includeIfNull: false)
  final String componentName;

  @JsonKey(name: r'coefficient', required: true, includeIfNull: false)
  final String coefficient;

  @JsonKey(name: r'required', required: true, includeIfNull: false)
  final bool required_;

  @JsonKey(name: r'displayOrder', required: true, includeIfNull: false)
  final num displayOrder;

  @JsonKey(name: r'value', required: true, includeIfNull: true)
  final String? value;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final GradeCellDtoStatusEnum status;

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final GradeCellDtoSource_Enum source_;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeCellDto &&
          other.id == id &&
          other.studentId == studentId &&
          other.studentName == studentName &&
          other.active == active &&
          other.componentId == componentId &&
          other.componentName == componentName &&
          other.coefficient == coefficient &&
          other.required_ == required_ &&
          other.displayOrder == displayOrder &&
          other.value == value &&
          other.status == status &&
          other.source_ == source_;

  @override
  int get hashCode =>
      id.hashCode +
      studentId.hashCode +
      studentName.hashCode +
      active.hashCode +
      componentId.hashCode +
      componentName.hashCode +
      coefficient.hashCode +
      required_.hashCode +
      displayOrder.hashCode +
      (value == null ? 0 : value.hashCode) +
      status.hashCode +
      source_.hashCode;

  factory GradeCellDto.fromJson(Map<String, dynamic> json) =>
      _$GradeCellDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GradeCellDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum GradeCellDtoStatusEnum {
  @JsonValue(r'CHUA_CO')
  CHUA_CO(r'CHUA_CO'),
  @JsonValue(r'CHO_DOI_CHIEU')
  CHO_DOI_CHIEU(r'CHO_DOI_CHIEU'),
  @JsonValue(r'DA_DUYET')
  DA_DUYET(r'DA_DUYET');

  const GradeCellDtoStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum GradeCellDtoSource_Enum {
  @JsonValue(r'NHAP_TAY')
  NHAP_TAY(r'NHAP_TAY'),
  @JsonValue(r'NHAN_DIEN')
  NHAN_DIEN(r'NHAN_DIEN');

  const GradeCellDtoSource_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}
