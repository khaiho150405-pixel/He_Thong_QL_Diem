//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gradebook_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GradebookDto {
  /// Returns a new [GradebookDto] instance.
  GradebookDto({
    required this.id,

    required this.classId,

    required this.subjectId,

    required this.termId,

    required this.className,

    required this.subjectName,

    required this.termName,

    required this.status,

    required this.version,

    required this.pendingAdjustmentId,

    required this.resultsOutdated,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final num id;

  @JsonKey(name: r'classId', required: true, includeIfNull: false)
  final num classId;

  @JsonKey(name: r'subjectId', required: true, includeIfNull: false)
  final num subjectId;

  @JsonKey(name: r'termId', required: true, includeIfNull: false)
  final num termId;

  @JsonKey(name: r'className', required: true, includeIfNull: false)
  final String className;

  @JsonKey(name: r'subjectName', required: true, includeIfNull: false)
  final String subjectName;

  @JsonKey(name: r'termName', required: true, includeIfNull: false)
  final String termName;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final GradebookDtoStatusEnum status;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final num version;

  /// Mã phiếu điều chỉnh sau chốt đang CHO_DUYET (nếu có)
  @JsonKey(name: r'pendingAdjustmentId', required: true, includeIfNull: true)
  final String? pendingAdjustmentId;

  /// Điểm đã được điều chỉnh sau lần tính tổng kết gần nhất
  @JsonKey(name: r'resultsOutdated', required: true, includeIfNull: false)
  final bool resultsOutdated;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradebookDto &&
          other.id == id &&
          other.classId == classId &&
          other.subjectId == subjectId &&
          other.termId == termId &&
          other.className == className &&
          other.subjectName == subjectName &&
          other.termName == termName &&
          other.status == status &&
          other.version == version &&
          other.pendingAdjustmentId == pendingAdjustmentId &&
          other.resultsOutdated == resultsOutdated;

  @override
  int get hashCode =>
      id.hashCode +
      classId.hashCode +
      subjectId.hashCode +
      termId.hashCode +
      className.hashCode +
      subjectName.hashCode +
      termName.hashCode +
      status.hashCode +
      version.hashCode +
      (pendingAdjustmentId == null ? 0 : pendingAdjustmentId.hashCode) +
      resultsOutdated.hashCode;

  factory GradebookDto.fromJson(Map<String, dynamic> json) =>
      _$GradebookDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GradebookDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum GradebookDtoStatusEnum {
  @JsonValue(r'DANG_NHAP_LIEU')
  DANG_NHAP_LIEU(r'DANG_NHAP_LIEU'),
  @JsonValue(r'DA_CHOT')
  DA_CHOT(r'DA_CHOT');

  const GradebookDtoStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
