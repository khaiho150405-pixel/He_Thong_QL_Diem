//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'enrollment_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EnrollmentDto {
  /// Returns a new [EnrollmentDto] instance.
  EnrollmentDto({
    required this.id,

    required this.classId,

    required this.className,

    required this.grade,

    required this.yearId,

    required this.yearName,

    required this.fromDate,

    required this.toDate,

    required this.status,

    required this.reason,

    required this.actorName,

    required this.createdAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'classId', required: true, includeIfNull: false)
  final num classId;

  @JsonKey(name: r'className', required: true, includeIfNull: false)
  final String className;

  @JsonKey(name: r'grade', required: true, includeIfNull: false)
  final num grade;

  @JsonKey(name: r'yearId', required: true, includeIfNull: false)
  final num yearId;

  @JsonKey(name: r'yearName', required: true, includeIfNull: false)
  final String yearName;

  @JsonKey(name: r'fromDate', required: true, includeIfNull: false)
  final String fromDate;

  @JsonKey(name: r'toDate', required: true, includeIfNull: true)
  final String? toDate;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final EnrollmentDtoStatusEnum status;

  @JsonKey(name: r'reason', required: true, includeIfNull: true)
  final String? reason;

  @JsonKey(name: r'actorName', required: true, includeIfNull: true)
  final String? actorName;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnrollmentDto &&
          other.id == id &&
          other.classId == classId &&
          other.className == className &&
          other.grade == grade &&
          other.yearId == yearId &&
          other.yearName == yearName &&
          other.fromDate == fromDate &&
          other.toDate == toDate &&
          other.status == status &&
          other.reason == reason &&
          other.actorName == actorName &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      id.hashCode +
      classId.hashCode +
      className.hashCode +
      grade.hashCode +
      yearId.hashCode +
      yearName.hashCode +
      fromDate.hashCode +
      (toDate == null ? 0 : toDate.hashCode) +
      status.hashCode +
      (reason == null ? 0 : reason.hashCode) +
      (actorName == null ? 0 : actorName.hashCode) +
      createdAt.hashCode;

  factory EnrollmentDto.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollmentDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum EnrollmentDtoStatusEnum {
  @JsonValue(r'DANG_HOC')
  DANG_HOC(r'DANG_HOC'),
  @JsonValue(r'LEN_LOP')
  LEN_LOP(r'LEN_LOP'),
  @JsonValue(r'LUU_BAN')
  LUU_BAN(r'LUU_BAN'),
  @JsonValue(r'DA_CHUYEN_LOP')
  DA_CHUYEN_LOP(r'DA_CHUYEN_LOP'),
  @JsonValue(r'NGHI_HOC')
  NGHI_HOC(r'NGHI_HOC'),
  @JsonValue(r'TOT_NGHIEP')
  TOT_NGHIEP(r'TOT_NGHIEP');

  const EnrollmentDtoStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
