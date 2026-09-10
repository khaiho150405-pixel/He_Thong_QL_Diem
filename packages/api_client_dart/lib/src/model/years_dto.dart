//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'years_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class YearsDto {
  /// Returns a new [YearsDto] instance.
  YearsDto({
    required this.ten,

    required this.ngayBatDau,

    required this.ngayKetThuc,

    required this.hienHanh,

    required this.label,

    required this.maNamHoc,
  });

  @JsonKey(name: r'ten', required: true, includeIfNull: false)
  final String ten;

  @JsonKey(name: r'ngay_bat_dau', required: true, includeIfNull: false)
  final String ngayBatDau;

  @JsonKey(name: r'ngay_ket_thuc', required: true, includeIfNull: false)
  final String ngayKetThuc;

  @JsonKey(name: r'hien_hanh', required: true, includeIfNull: false)
  final bool hienHanh;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'ma_nam_hoc', required: true, includeIfNull: false)
  final num maNamHoc;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearsDto &&
          other.ten == ten &&
          other.ngayBatDau == ngayBatDau &&
          other.ngayKetThuc == ngayKetThuc &&
          other.hienHanh == hienHanh &&
          other.label == label &&
          other.maNamHoc == maNamHoc;

  @override
  int get hashCode =>
      ten.hashCode +
      ngayBatDau.hashCode +
      ngayKetThuc.hashCode +
      hienHanh.hashCode +
      label.hashCode +
      maNamHoc.hashCode;

  factory YearsDto.fromJson(Map<String, dynamic> json) =>
      _$YearsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YearsDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
