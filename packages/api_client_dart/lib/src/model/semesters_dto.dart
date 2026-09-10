//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'semesters_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SemestersDto {
  /// Returns a new [SemestersDto] instance.
  SemestersDto({
    required this.maNamHoc,

    required this.ten,

    required this.thuTu,

    required this.ngayBatDau,

    required this.ngayKetThuc,

    required this.label,

    required this.maHocKy,
  });

  @JsonKey(name: r'ma_nam_hoc', required: true, includeIfNull: false)
  final num maNamHoc;

  @JsonKey(name: r'ten', required: true, includeIfNull: false)
  final String ten;

  @JsonKey(name: r'thu_tu', required: true, includeIfNull: false)
  final num thuTu;

  @JsonKey(name: r'ngay_bat_dau', required: true, includeIfNull: false)
  final String ngayBatDau;

  @JsonKey(name: r'ngay_ket_thuc', required: true, includeIfNull: false)
  final String ngayKetThuc;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'ma_hoc_ky', required: true, includeIfNull: false)
  final num maHocKy;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemestersDto &&
          other.maNamHoc == maNamHoc &&
          other.ten == ten &&
          other.thuTu == thuTu &&
          other.ngayBatDau == ngayBatDau &&
          other.ngayKetThuc == ngayKetThuc &&
          other.label == label &&
          other.maHocKy == maHocKy;

  @override
  int get hashCode =>
      maNamHoc.hashCode +
      ten.hashCode +
      thuTu.hashCode +
      ngayBatDau.hashCode +
      ngayKetThuc.hashCode +
      label.hashCode +
      maHocKy.hashCode;

  factory SemestersDto.fromJson(Map<String, dynamic> json) =>
      _$SemestersDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SemestersDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
