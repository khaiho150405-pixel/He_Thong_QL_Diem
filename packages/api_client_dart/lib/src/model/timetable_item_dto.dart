//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'timetable_item_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TimetableItemDto {
  /// Returns a new [TimetableItemDto] instance.
  TimetableItemDto({
    required this.maTietHoc,

    required this.maLop,

    required this.tenLop,

    required this.maMon,

    required this.tenMon,

    required this.maGiaoVien,

    required this.tenGiaoVien,

    required this.maHocKy,

    required this.tenHocKy,

    required this.thu,

    required this.tiet,

    required this.phongHoc,

    required this.ghiChu,
  });

  @JsonKey(name: r'ma_tiet_hoc', required: true, includeIfNull: false)
  final num maTietHoc;

  @JsonKey(name: r'ma_lop', required: true, includeIfNull: false)
  final num maLop;

  @JsonKey(name: r'ten_lop', required: true, includeIfNull: false)
  final String tenLop;

  @JsonKey(name: r'ma_mon', required: true, includeIfNull: false)
  final num maMon;

  @JsonKey(name: r'ten_mon', required: true, includeIfNull: false)
  final String tenMon;

  @JsonKey(name: r'ma_giao_vien', required: true, includeIfNull: false)
  final num maGiaoVien;

  @JsonKey(name: r'ten_giao_vien', required: true, includeIfNull: false)
  final String tenGiaoVien;

  @JsonKey(name: r'ma_hoc_ky', required: true, includeIfNull: false)
  final num maHocKy;

  @JsonKey(name: r'ten_hoc_ky', required: true, includeIfNull: false)
  final String tenHocKy;

  /// Ngày trong tuần (2 - 8, gồm Chủ nhật)
  @JsonKey(name: r'thu', required: true, includeIfNull: false)
  final num thu;

  /// Tiết học (1 - 10)
  @JsonKey(name: r'tiet', required: true, includeIfNull: false)
  final num tiet;

  @JsonKey(name: r'phong_hoc', required: true, includeIfNull: true)
  final String? phongHoc;

  @JsonKey(name: r'ghi_chu', required: true, includeIfNull: true)
  final String? ghiChu;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableItemDto &&
          other.maTietHoc == maTietHoc &&
          other.maLop == maLop &&
          other.tenLop == tenLop &&
          other.maMon == maMon &&
          other.tenMon == tenMon &&
          other.maGiaoVien == maGiaoVien &&
          other.tenGiaoVien == tenGiaoVien &&
          other.maHocKy == maHocKy &&
          other.tenHocKy == tenHocKy &&
          other.thu == thu &&
          other.tiet == tiet &&
          other.phongHoc == phongHoc &&
          other.ghiChu == ghiChu;

  @override
  int get hashCode =>
      maTietHoc.hashCode +
      maLop.hashCode +
      tenLop.hashCode +
      maMon.hashCode +
      tenMon.hashCode +
      maGiaoVien.hashCode +
      tenGiaoVien.hashCode +
      maHocKy.hashCode +
      tenHocKy.hashCode +
      thu.hashCode +
      tiet.hashCode +
      (phongHoc == null ? 0 : phongHoc.hashCode) +
      (ghiChu == null ? 0 : ghiChu.hashCode);

  factory TimetableItemDto.fromJson(Map<String, dynamic> json) =>
      _$TimetableItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TimetableItemDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
