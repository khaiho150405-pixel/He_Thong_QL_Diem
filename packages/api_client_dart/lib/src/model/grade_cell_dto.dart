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

    required this.stt,

    required this.active,

    required this.componentId,

    required this.componentName,

    required this.coefficient,

    required this.required_,

    required this.displayOrder,

    this.openForInput,

    this.columnLocked,

    this.passFail,

    this.opensAt,

    this.closesAt,

    this.deadlineVersion,

    this.deadlineSource,

    required this.value,

    required this.status,

    required this.source_,

    required this.exemptionReason,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'studentId', required: true, includeIfNull: false)
  final num studentId;

  @JsonKey(name: r'studentName', required: true, includeIfNull: false)
  final String studentName;

  /// STT trong lớp theo thứ tự tên; null khi học sinh đã nghỉ
  @JsonKey(name: r'stt', required: true, includeIfNull: true)
  final num? stt;

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

  @JsonKey(name: r'openForInput', required: false, includeIfNull: false)
  final bool? openForInput;

  @JsonKey(name: r'columnLocked', required: false, includeIfNull: false)
  final bool? columnLocked;

  @JsonKey(name: r'passFail', required: false, includeIfNull: false)
  final bool? passFail;

  @JsonKey(name: r'opensAt', required: false, includeIfNull: false)
  final String? opensAt;

  @JsonKey(name: r'closesAt', required: false, includeIfNull: false)
  final String? closesAt;

  @JsonKey(name: r'deadlineVersion', required: false, includeIfNull: false)
  final num? deadlineVersion;

  /// Nguồn lịch hiệu lực: RIENG (bảng + cột) ghi đè HOC_KY (mặc định theo loại điểm); null = chưa có lịch
  @JsonKey(name: r'deadlineSource', required: false, includeIfNull: false)
  final GradeCellDtoDeadlineSourceEnum? deadlineSource;

  @JsonKey(name: r'value', required: true, includeIfNull: true)
  final String? value;

  /// MIEN: ô được miễn (giá trị luôn null, khác chưa có điểm)
  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final GradeCellDtoStatusEnum status;

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final GradeCellDtoSource_Enum source_;

  /// Lý do miễn gần nhất khi status = MIEN, ngược lại null
  @JsonKey(name: r'exemptionReason', required: true, includeIfNull: true)
  final String? exemptionReason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeCellDto &&
          other.id == id &&
          other.studentId == studentId &&
          other.studentName == studentName &&
          other.stt == stt &&
          other.active == active &&
          other.componentId == componentId &&
          other.componentName == componentName &&
          other.coefficient == coefficient &&
          other.required_ == required_ &&
          other.displayOrder == displayOrder &&
          other.openForInput == openForInput &&
          other.columnLocked == columnLocked &&
          other.passFail == passFail &&
          other.opensAt == opensAt &&
          other.closesAt == closesAt &&
          other.deadlineVersion == deadlineVersion &&
          other.deadlineSource == deadlineSource &&
          other.value == value &&
          other.status == status &&
          other.source_ == source_ &&
          other.exemptionReason == exemptionReason;

  @override
  int get hashCode =>
      id.hashCode +
      studentId.hashCode +
      studentName.hashCode +
      (stt == null ? 0 : stt.hashCode) +
      active.hashCode +
      componentId.hashCode +
      componentName.hashCode +
      coefficient.hashCode +
      required_.hashCode +
      displayOrder.hashCode +
      openForInput.hashCode +
      columnLocked.hashCode +
      passFail.hashCode +
      (opensAt == null ? 0 : opensAt.hashCode) +
      (closesAt == null ? 0 : closesAt.hashCode) +
      deadlineVersion.hashCode +
      (deadlineSource == null ? 0 : deadlineSource.hashCode) +
      (value == null ? 0 : value.hashCode) +
      status.hashCode +
      source_.hashCode +
      (exemptionReason == null ? 0 : exemptionReason.hashCode);

  factory GradeCellDto.fromJson(Map<String, dynamic> json) =>
      _$GradeCellDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GradeCellDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Nguồn lịch hiệu lực: RIENG (bảng + cột) ghi đè HOC_KY (mặc định theo loại điểm); null = chưa có lịch
enum GradeCellDtoDeadlineSourceEnum {
  /// Nguồn lịch hiệu lực: RIENG (bảng + cột) ghi đè HOC_KY (mặc định theo loại điểm); null = chưa có lịch
  @JsonValue(r'RIENG')
  RIENG(r'RIENG'),

  /// Nguồn lịch hiệu lực: RIENG (bảng + cột) ghi đè HOC_KY (mặc định theo loại điểm); null = chưa có lịch
  @JsonValue(r'HOC_KY')
  HOC_KY(r'HOC_KY');

  const GradeCellDtoDeadlineSourceEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

/// MIEN: ô được miễn (giá trị luôn null, khác chưa có điểm)
enum GradeCellDtoStatusEnum {
  /// MIEN: ô được miễn (giá trị luôn null, khác chưa có điểm)
  @JsonValue(r'CHUA_CO')
  CHUA_CO(r'CHUA_CO'),

  /// MIEN: ô được miễn (giá trị luôn null, khác chưa có điểm)
  @JsonValue(r'CHO_DOI_CHIEU')
  CHO_DOI_CHIEU(r'CHO_DOI_CHIEU'),

  /// MIEN: ô được miễn (giá trị luôn null, khác chưa có điểm)
  @JsonValue(r'DA_DUYET')
  DA_DUYET(r'DA_DUYET'),

  /// MIEN: ô được miễn (giá trị luôn null, khác chưa có điểm)
  @JsonValue(r'MIEN')
  MIEN(r'MIEN');

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
