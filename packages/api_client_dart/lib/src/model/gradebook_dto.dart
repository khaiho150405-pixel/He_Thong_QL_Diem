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

    required this.status,

    required this.version,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final num id;

  @JsonKey(name: r'classId', required: true, includeIfNull: false)
  final num classId;

  @JsonKey(name: r'subjectId', required: true, includeIfNull: false)
  final num subjectId;

  @JsonKey(name: r'termId', required: true, includeIfNull: false)
  final num termId;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final GradebookDtoStatusEnum status;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final num version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradebookDto &&
          other.id == id &&
          other.classId == classId &&
          other.subjectId == subjectId &&
          other.termId == termId &&
          other.status == status &&
          other.version == version;

  @override
  int get hashCode =>
      id.hashCode +
      classId.hashCode +
      subjectId.hashCode +
      termId.hashCode +
      status.hashCode +
      version.hashCode;

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
