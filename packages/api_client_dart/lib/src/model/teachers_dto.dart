//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'teachers_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TeachersDto {
  /// Returns a new [TeachersDto] instance.
  TeachersDto({
    required this.maGiaoVien,

    required this.hoTen,

    required this.toChuyenMon,

    required this.email,

    required this.dienThoai,

    required this.label,
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

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeachersDto &&
          other.maGiaoVien == maGiaoVien &&
          other.hoTen == hoTen &&
          other.toChuyenMon == toChuyenMon &&
          other.email == email &&
          other.dienThoai == dienThoai &&
          other.label == label;

  @override
  int get hashCode =>
      maGiaoVien.hashCode +
      hoTen.hashCode +
      (toChuyenMon == null ? 0 : toChuyenMon.hashCode) +
      (email == null ? 0 : email.hashCode) +
      (dienThoai == null ? 0 : dienThoai.hashCode) +
      label.hashCode;

  factory TeachersDto.fromJson(Map<String, dynamic> json) =>
      _$TeachersDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TeachersDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
