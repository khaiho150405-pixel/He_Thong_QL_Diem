//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'semester_weights_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SemesterWeightsInput {
  /// Returns a new [SemesterWeightsInput] instance.
  SemesterWeightsInput({
    required this.loaiHeSo,

    required this.maHocKy,

    required this.heSo,
  });

  @JsonKey(name: r'loai_he_so', required: true, includeIfNull: false)
  final SemesterWeightsInputLoaiHeSoEnum loaiHeSo;

  @JsonKey(name: r'ma_hoc_ky', required: true, includeIfNull: false)
  final num maHocKy;

  @JsonKey(name: r'he_so', required: true, includeIfNull: false)
  final String heSo;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemesterWeightsInput &&
          other.loaiHeSo == loaiHeSo &&
          other.maHocKy == maHocKy &&
          other.heSo == heSo;

  @override
  int get hashCode => loaiHeSo.hashCode + maHocKy.hashCode + heSo.hashCode;

  factory SemesterWeightsInput.fromJson(Map<String, dynamic> json) =>
      _$SemesterWeightsInputFromJson(json);

  Map<String, dynamic> toJson() => _$SemesterWeightsInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum SemesterWeightsInputLoaiHeSoEnum {
  @JsonValue(r'TX')
  TX(r'TX'),
  @JsonValue(r'GK')
  GK(r'GK'),
  @JsonValue(r'CK')
  CK(r'CK');

  const SemesterWeightsInputLoaiHeSoEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
