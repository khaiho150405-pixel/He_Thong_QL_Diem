//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'classes_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClassesDto {
  /// Returns a new [ClassesDto] instance.
  ClassesDto({
    required this.maNamHoc,

    required this.maGvChuNhiem,

    required this.tenLop,

    required this.khoi,

    required this.label,

    required this.maLop,
  });

  @JsonKey(name: r'ma_nam_hoc', required: true, includeIfNull: false)
  final num maNamHoc;

  @JsonKey(name: r'ma_gv_chu_nhiem', required: true, includeIfNull: false)
  final num maGvChuNhiem;

  @JsonKey(name: r'ten_lop', required: true, includeIfNull: false)
  final String tenLop;

  @JsonKey(name: r'khoi', required: true, includeIfNull: false)
  final num khoi;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'ma_lop', required: true, includeIfNull: false)
  final num maLop;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassesDto &&
          other.maNamHoc == maNamHoc &&
          other.maGvChuNhiem == maGvChuNhiem &&
          other.tenLop == tenLop &&
          other.khoi == khoi &&
          other.label == label &&
          other.maLop == maLop;

  @override
  int get hashCode =>
      maNamHoc.hashCode +
      maGvChuNhiem.hashCode +
      tenLop.hashCode +
      khoi.hashCode +
      label.hashCode +
      maLop.hashCode;

  factory ClassesDto.fromJson(Map<String, dynamic> json) =>
      _$ClassesDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ClassesDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
