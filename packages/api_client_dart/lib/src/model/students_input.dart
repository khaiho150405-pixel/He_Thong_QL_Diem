//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'students_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StudentsInput {
  /// Returns a new [StudentsInput] instance.
  StudentsInput({
    required this.maNguoiDung,

    required this.maLop,

    required this.hoTen,

    required this.ngaySinh,

    required this.dangTheoHoc,
  });

  @JsonKey(name: r'ma_nguoi_dung', required: true, includeIfNull: true)
  final num? maNguoiDung;

  @JsonKey(name: r'ma_lop', required: true, includeIfNull: false)
  final num maLop;

  @JsonKey(name: r'ho_ten', required: true, includeIfNull: false)
  final String hoTen;

  @JsonKey(name: r'ngay_sinh', required: true, includeIfNull: false)
  final String ngaySinh;

  @JsonKey(name: r'dang_theo_hoc', required: true, includeIfNull: false)
  final bool dangTheoHoc;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentsInput &&
          other.maNguoiDung == maNguoiDung &&
          other.maLop == maLop &&
          other.hoTen == hoTen &&
          other.ngaySinh == ngaySinh &&
          other.dangTheoHoc == dangTheoHoc;

  @override
  int get hashCode =>
      (maNguoiDung == null ? 0 : maNguoiDung.hashCode) +
      maLop.hashCode +
      hoTen.hashCode +
      ngaySinh.hashCode +
      dangTheoHoc.hashCode;

  factory StudentsInput.fromJson(Map<String, dynamic> json) =>
      _$StudentsInputFromJson(json);

  Map<String, dynamic> toJson() => _$StudentsInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
