//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'semesters_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SemestersInput {
  /// Returns a new [SemestersInput] instance.
  SemestersInput({
    required this.maNamHoc,

    required this.ten,

    required this.thuTu,

    required this.ngayBatDau,

    required this.ngayKetThuc,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemestersInput &&
          other.maNamHoc == maNamHoc &&
          other.ten == ten &&
          other.thuTu == thuTu &&
          other.ngayBatDau == ngayBatDau &&
          other.ngayKetThuc == ngayKetThuc;

  @override
  int get hashCode =>
      maNamHoc.hashCode +
      ten.hashCode +
      thuTu.hashCode +
      ngayBatDau.hashCode +
      ngayKetThuc.hashCode;

  factory SemestersInput.fromJson(Map<String, dynamic> json) =>
      _$SemestersInputFromJson(json);

  Map<String, dynamic> toJson() => _$SemestersInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
