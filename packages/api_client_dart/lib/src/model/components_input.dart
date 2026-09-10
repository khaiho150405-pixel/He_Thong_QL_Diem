//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'components_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComponentsInput {
  /// Returns a new [ComponentsInput] instance.
  ComponentsInput({
    required this.maMon,

    required this.tenThanhPhan,

    required this.heSo,

    required this.batBuoc,

    required this.thuTuHienThi,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentsInput &&
          other.maMon == maMon &&
          other.tenThanhPhan == tenThanhPhan &&
          other.heSo == heSo &&
          other.batBuoc == batBuoc &&
          other.thuTuHienThi == thuTuHienThi;

  @override
  int get hashCode =>
      maMon.hashCode +
      tenThanhPhan.hashCode +
      heSo.hashCode +
      batBuoc.hashCode +
      thuTuHienThi.hashCode;

  factory ComponentsInput.fromJson(Map<String, dynamic> json) =>
      _$ComponentsInputFromJson(json);

  Map<String, dynamic> toJson() => _$ComponentsInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
