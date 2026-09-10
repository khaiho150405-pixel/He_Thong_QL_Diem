//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'teachers_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TeachersInput {
  /// Returns a new [TeachersInput] instance.
  TeachersInput({
    required this.maGiaoVien,

    required this.hoTen,

    required this.toChuyenMon,

    required this.email,

    required this.dienThoai,
  });

  @JsonKey(name: r'ma_giao_vien', required: true, includeIfNull: false)
  final num maGiaoVien;

  @JsonKey(name: r'ho_ten', required: true, includeIfNull: false)
  final String hoTen;

  @JsonKey(name: r'to_chuyen_mon', required: true, includeIfNull: true)
  final String? toChuyenMon;

  @JsonKey(name: r'email', required: true, includeIfNull: true)
  final String? email;

  @JsonKey(name: r'dien_thoai', required: true, includeIfNull: true)
  final String? dienThoai;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeachersInput &&
          other.maGiaoVien == maGiaoVien &&
          other.hoTen == hoTen &&
          other.toChuyenMon == toChuyenMon &&
          other.email == email &&
          other.dienThoai == dienThoai;

  @override
  int get hashCode =>
      maGiaoVien.hashCode +
      hoTen.hashCode +
      (toChuyenMon == null ? 0 : toChuyenMon.hashCode) +
      (email == null ? 0 : email.hashCode) +
      (dienThoai == null ? 0 : dienThoai.hashCode);

  factory TeachersInput.fromJson(Map<String, dynamic> json) =>
      _$TeachersInputFromJson(json);

  Map<String, dynamic> toJson() => _$TeachersInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
