//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/template_column_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'template_detail_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TemplateDetailDto {
  /// Returns a new [TemplateDetailDto] instance.
  TemplateDetailDto({
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

    required this.columns,

    required this.imageUrl,

    required this.imageUrlExpiresInSeconds,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final num id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'description', required: true, includeIfNull: true)
  final String? description;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final TemplateDetailDtoStatusEnum status;

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

  @JsonKey(name: r'columns', required: true, includeIfNull: false)
  final List<TemplateColumnDto> columns;

  /// URL ký 300 giây của ảnh mẫu (kho lưu trữ private)
  @JsonKey(name: r'imageUrl', required: true, includeIfNull: false)
  final String imageUrl;

  @JsonKey(
    name: r'imageUrlExpiresInSeconds',
    required: true,
    includeIfNull: false,
  )
  final num imageUrlExpiresInSeconds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateDetailDto &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.status == status &&
          other.revision == revision &&
          other.rootTemplateId == rootTemplateId &&
          other.columnCount == columnCount &&
          other.gradeColumnCount == gradeColumnCount &&
          other.version == version &&
          other.createdAt == createdAt &&
          other.columns == columns &&
          other.imageUrl == imageUrl &&
          other.imageUrlExpiresInSeconds == imageUrlExpiresInSeconds;

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
      createdAt.hashCode +
      columns.hashCode +
      imageUrl.hashCode +
      imageUrlExpiresInSeconds.hashCode;

  factory TemplateDetailDto.fromJson(Map<String, dynamic> json) =>
      _$TemplateDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateDetailDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum TemplateDetailDtoStatusEnum {
  @JsonValue(r'NHAP')
  NHAP(r'NHAP'),
  @JsonValue(r'DANG_DUNG')
  DANG_DUNG(r'DANG_DUNG'),
  @JsonValue(r'NGUNG')
  NGUNG(r'NGUNG');

  const TemplateDetailDtoStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
