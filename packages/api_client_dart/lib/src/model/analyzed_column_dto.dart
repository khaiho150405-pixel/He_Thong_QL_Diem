//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'analyzed_column_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AnalyzedColumnDto {
  /// Returns a new [AnalyzedColumnDto] instance.
  AnalyzedColumnDto({
    required this.index,

    required this.x0,

    required this.x1,

    required this.widthMm,

    required this.headerText,

    required this.suggestedRole,

    required this.suggestedGroup,

    required this.suggestedOrder,
  });

  @JsonKey(name: r'index', required: true, includeIfNull: false)
  final num index;

  /// Tỉ lệ 0–1 theo bề rộng bảng
  @JsonKey(name: r'x0', required: true, includeIfNull: false)
  final num x0;

  @JsonKey(name: r'x1', required: true, includeIfNull: false)
  final num x1;

  @JsonKey(name: r'widthMm', required: true, includeIfNull: false)
  final num widthMm;

  @JsonKey(name: r'headerText', required: true, includeIfNull: false)
  final String headerText;

  @JsonKey(name: r'suggestedRole', required: true, includeIfNull: true)
  final AnalyzedColumnDtoSuggestedRoleEnum? suggestedRole;

  @JsonKey(name: r'suggestedGroup', required: true, includeIfNull: true)
  final AnalyzedColumnDtoSuggestedGroupEnum? suggestedGroup;

  @JsonKey(name: r'suggestedOrder', required: true, includeIfNull: true)
  final num? suggestedOrder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyzedColumnDto &&
          other.index == index &&
          other.x0 == x0 &&
          other.x1 == x1 &&
          other.widthMm == widthMm &&
          other.headerText == headerText &&
          other.suggestedRole == suggestedRole &&
          other.suggestedGroup == suggestedGroup &&
          other.suggestedOrder == suggestedOrder;

  @override
  int get hashCode =>
      index.hashCode +
      x0.hashCode +
      x1.hashCode +
      widthMm.hashCode +
      headerText.hashCode +
      (suggestedRole == null ? 0 : suggestedRole.hashCode) +
      (suggestedGroup == null ? 0 : suggestedGroup.hashCode) +
      (suggestedOrder == null ? 0 : suggestedOrder.hashCode);

  factory AnalyzedColumnDto.fromJson(Map<String, dynamic> json) =>
      _$AnalyzedColumnDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyzedColumnDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AnalyzedColumnDtoSuggestedRoleEnum {
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

  const AnalyzedColumnDtoSuggestedRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AnalyzedColumnDtoSuggestedGroupEnum {
  @JsonValue(r'TX')
  TX(r'TX'),
  @JsonValue(r'GK')
  GK(r'GK'),
  @JsonValue(r'CK')
  CK(r'CK');

  const AnalyzedColumnDtoSuggestedGroupEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
