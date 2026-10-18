//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'template_summary_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TemplateSummaryDto {
  /// Returns a new [TemplateSummaryDto] instance.
  TemplateSummaryDto({
    required this.id,

    required this.name,

    required this.description,

    required this.status,

    required this.revision,

    required this.rootTemplateId,

    required this.columnCount,

    required this.gradeColumnCount,

    required this.version,

    required this.createdAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final num id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'description', required: true, includeIfNull: true)
  final String? description;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final TemplateSummaryDtoStatusEnum status;

  /// Số phiên bản của chuỗi mẫu
  @JsonKey(name: r'revision', required: true, includeIfNull: false)
  final num revision;

  @JsonKey(name: r'rootTemplateId', required: true, includeIfNull: true)
  final num? rootTemplateId;

  @JsonKey(name: r'columnCount', required: true, includeIfNull: false)
  final num columnCount;

  @JsonKey(name: r'gradeColumnCount', required: true, includeIfNull: false)
  final num gradeColumnCount;

  /// Dùng làm expectedVersion khi sửa/kích hoạt/ngừng
  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final num version;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateSummaryDto &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.status == status &&
          other.revision == revision &&
          other.rootTemplateId == rootTemplateId &&
          other.columnCount == columnCount &&
          other.gradeColumnCount == gradeColumnCount &&
          other.version == version &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      (description == null ? 0 : description.hashCode) +
      status.hashCode +
      revision.hashCode +
      (rootTemplateId == null ? 0 : rootTemplateId.hashCode) +
      columnCount.hashCode +
      gradeColumnCount.hashCode +
      version.hashCode +
      createdAt.hashCode;

  factory TemplateSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$TemplateSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateSummaryDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum TemplateSummaryDtoStatusEnum {
  @JsonValue(r'NHAP')
  NHAP(r'NHAP'),
  @JsonValue(r'DANG_DUNG')
  DANG_DUNG(r'DANG_DUNG'),
  @JsonValue(r'NGUNG')
  NGUNG(r'NGUNG');

  const TemplateSummaryDtoStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
