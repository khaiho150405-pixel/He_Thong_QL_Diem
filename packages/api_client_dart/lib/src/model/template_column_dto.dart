//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'template_column_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TemplateColumnDto {
  /// Returns a new [TemplateColumnDto] instance.
  TemplateColumnDto({
    required this.index,

    required this.role,

    required this.group,

    required this.order,

    required this.pairedWith,

    required this.headerText,
  });

  // minimum: 0
  // maximum: 63
  @JsonKey(name: r'index', required: true, includeIfNull: false)
  final num index;

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final TemplateColumnDtoRoleEnum role;

  @JsonKey(name: r'group', required: true, includeIfNull: true)
  final TemplateColumnDtoGroupEnum? group;

  /// Thứ tự trong nhóm hệ số, từ 1 (chỉ cột DIEM)
  @JsonKey(name: r'order', required: true, includeIfNull: true)
  final num? order;

  /// Chỉ số cột DIEM đi kèm (chỉ cột DIEM_CHU)
  @JsonKey(name: r'pairedWith', required: true, includeIfNull: true)
  final num? pairedWith;

  @JsonKey(name: r'headerText', required: true, includeIfNull: true)
  final String? headerText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateColumnDto &&
          other.index == index &&
          other.role == role &&
          other.group == group &&
          other.order == order &&
          other.pairedWith == pairedWith &&
          other.headerText == headerText;

  @override
  int get hashCode =>
      index.hashCode +
      role.hashCode +
      (group == null ? 0 : group.hashCode) +
      (order == null ? 0 : order.hashCode) +
      (pairedWith == null ? 0 : pairedWith.hashCode) +
      (headerText == null ? 0 : headerText.hashCode);

  factory TemplateColumnDto.fromJson(Map<String, dynamic> json) =>
      _$TemplateColumnDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateColumnDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum TemplateColumnDtoRoleEnum {
  @JsonValue(r'STT')
  STT(r'STT'),
  @JsonValue(r'HO_TEN')
  HO_TEN(r'HO_TEN'),
  @JsonValue(r'DIEM')
  DIEM(r'DIEM'),
  @JsonValue(r'DIEM_CHU')
  DIEM_CHU(r'DIEM_CHU'),
  @JsonValue(r'BO_QUA')
  BO_QUA(r'BO_QUA');

  const TemplateColumnDtoRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum TemplateColumnDtoGroupEnum {
  @JsonValue(r'TX')
  TX(r'TX'),
  @JsonValue(r'GK')
  GK(r'GK'),
  @JsonValue(r'CK')
  CK(r'CK');

  const TemplateColumnDtoGroupEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
