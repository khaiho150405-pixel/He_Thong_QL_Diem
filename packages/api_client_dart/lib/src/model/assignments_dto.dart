//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'assignments_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AssignmentsDto {
  /// Returns a new [AssignmentsDto] instance.
  AssignmentsDto({
    required this.maGiaoVien,

    required this.maLop,

    required this.maMon,

    required this.maHocKy,

    required this.ngayPhanCong,

    required this.label,

    required this.maPhanCong,
  });

  @JsonKey(name: r'ma_giao_vien', required: true, includeIfNull: false)
  final num maGiaoVien;

  @JsonKey(name: r'ma_lop', required: true, includeIfNull: false)
  final num maLop;

  @JsonKey(name: r'ma_mon', required: true, includeIfNull: false)
  final num maMon;

  @JsonKey(name: r'ma_hoc_ky', required: true, includeIfNull: false)
  final num maHocKy;

  @JsonKey(name: r'ngay_phan_cong', required: true, includeIfNull: false)
  final String ngayPhanCong;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'ma_phan_cong', required: true, includeIfNull: false)
  final num maPhanCong;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssignmentsDto &&
          other.maGiaoVien == maGiaoVien &&
          other.maLop == maLop &&
          other.maMon == maMon &&
          other.maHocKy == maHocKy &&
          other.ngayPhanCong == ngayPhanCong &&
          other.label == label &&
          other.maPhanCong == maPhanCong;

  @override
  int get hashCode =>
      maGiaoVien.hashCode +
      maLop.hashCode +
      maMon.hashCode +
      maHocKy.hashCode +
      ngayPhanCong.hashCode +
      label.hashCode +
      maPhanCong.hashCode;

  factory AssignmentsDto.fromJson(Map<String, dynamic> json) =>
      _$AssignmentsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AssignmentsDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
