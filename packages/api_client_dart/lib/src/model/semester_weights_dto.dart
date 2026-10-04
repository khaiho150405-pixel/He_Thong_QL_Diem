//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'semester_weights_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SemesterWeightsDto {
  /// Returns a new [SemesterWeightsDto] instance.
  SemesterWeightsDto({
    required this.loaiHeSo,

    required this.maHocKy,

    required this.heSo,

    required this.label,

    required this.maHeSo,
  });

  @JsonKey(name: r'loai_he_so', required: true, includeIfNull: false)
  final SemesterWeightsDtoLoaiHeSoEnum loaiHeSo;

  @JsonKey(name: r'ma_hoc_ky', required: true, includeIfNull: false)
  final num maHocKy;

  @JsonKey(name: r'he_so', required: true, includeIfNull: false)
  final String heSo;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'ma_he_so', required: true, includeIfNull: false)
  final num maHeSo;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemesterWeightsDto &&
          other.loaiHeSo == loaiHeSo &&
          other.maHocKy == maHocKy &&
          other.heSo == heSo &&
          other.label == label &&
          other.maHeSo == maHeSo;

  @override
  int get hashCode =>
      loaiHeSo.hashCode +
      maHocKy.hashCode +
      heSo.hashCode +
      label.hashCode +
      maHeSo.hashCode;

  factory SemesterWeightsDto.fromJson(Map<String, dynamic> json) =>
      _$SemesterWeightsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SemesterWeightsDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum SemesterWeightsDtoLoaiHeSoEnum {
  @JsonValue(r'TX')
  TX(r'TX'),
  @JsonValue(r'GK')
  GK(r'GK'),
  @JsonValue(r'CK')
  CK(r'CK');

  const SemesterWeightsDtoLoaiHeSoEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
