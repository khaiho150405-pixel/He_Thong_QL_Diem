//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_timetable_item_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateTimetableItemInput {
  /// Returns a new [CreateTimetableItemInput] instance.
  CreateTimetableItemInput({
    required this.maLop,

    required this.maMon,

    required this.maGiaoVien,

    required this.maHocKy,

    required this.thu,

    required this.tiet,

    this.phongHoc,

    this.ghiChu,
  });

  @JsonKey(name: r'ma_lop', required: true, includeIfNull: false)
  final num maLop;

  @JsonKey(name: r'ma_mon', required: true, includeIfNull: false)
  final num maMon;

  @JsonKey(name: r'ma_giao_vien', required: true, includeIfNull: false)
  final num maGiaoVien;

  @JsonKey(name: r'ma_hoc_ky', required: true, includeIfNull: false)
  final num maHocKy;

  @JsonKey(name: r'thu', required: true, includeIfNull: false)
  final num thu;

  @JsonKey(name: r'tiet', required: true, includeIfNull: false)
  final num tiet;

  @JsonKey(name: r'phong_hoc', required: false, includeIfNull: false)
  final String? phongHoc;

  @JsonKey(name: r'ghi_chu', required: false, includeIfNull: false)
  final String? ghiChu;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateTimetableItemInput &&
          other.maLop == maLop &&
          other.maMon == maMon &&
          other.maGiaoVien == maGiaoVien &&
          other.maHocKy == maHocKy &&
          other.thu == thu &&
          other.tiet == tiet &&
          other.phongHoc == phongHoc &&
          other.ghiChu == ghiChu;

  @override
  int get hashCode =>
      maLop.hashCode +
      maMon.hashCode +
      maGiaoVien.hashCode +
      maHocKy.hashCode +
      thu.hashCode +
      tiet.hashCode +
      (phongHoc == null ? 0 : phongHoc.hashCode) +
      (ghiChu == null ? 0 : ghiChu.hashCode);

  factory CreateTimetableItemInput.fromJson(Map<String, dynamic> json) =>
      _$CreateTimetableItemInputFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTimetableItemInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
