//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'components_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComponentsDto {
  /// Returns a new [ComponentsDto] instance.
  ComponentsDto({
    required this.maMon,

    required this.tenThanhPhan,

    required this.heSo,

    required this.batBuoc,

    required this.thuTuHienThi,

    required this.label,

    required this.maThanhPhan,
  });

  @JsonKey(name: r'ma_mon', required: true, includeIfNull: false)
  final num maMon;

  @JsonKey(name: r'ten_thanh_phan', required: true, includeIfNull: false)
  final String tenThanhPhan;

  @JsonKey(name: r'he_so', required: true, includeIfNull: false)
  final String heSo;

  @JsonKey(name: r'bat_buoc', required: true, includeIfNull: false)
  final bool batBuoc;

  @JsonKey(name: r'thu_tu_hien_thi', required: true, includeIfNull: false)
  final num thuTuHienThi;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'ma_thanh_phan', required: true, includeIfNull: false)
  final num maThanhPhan;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentsDto &&
          other.maMon == maMon &&
          other.tenThanhPhan == tenThanhPhan &&
          other.heSo == heSo &&
          other.batBuoc == batBuoc &&
          other.thuTuHienThi == thuTuHienThi &&
          other.label == label &&
          other.maThanhPhan == maThanhPhan;

  @override
  int get hashCode =>
      maMon.hashCode +
      tenThanhPhan.hashCode +
      heSo.hashCode +
      batBuoc.hashCode +
      thuTuHienThi.hashCode +
      label.hashCode +
      maThanhPhan.hashCode;

  factory ComponentsDto.fromJson(Map<String, dynamic> json) =>
      _$ComponentsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ComponentsDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
