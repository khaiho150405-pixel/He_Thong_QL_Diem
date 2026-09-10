//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'classes_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClassesInput {
  /// Returns a new [ClassesInput] instance.
  ClassesInput({
    required this.maNamHoc,

    required this.maGvChuNhiem,

    required this.tenLop,

    required this.khoi,
  });

  @JsonKey(name: r'ma_nam_hoc', required: true, includeIfNull: false)
  final num maNamHoc;

  @JsonKey(name: r'ma_gv_chu_nhiem', required: true, includeIfNull: false)
  final num maGvChuNhiem;

  @JsonKey(name: r'ten_lop', required: true, includeIfNull: false)
  final String tenLop;

  @JsonKey(name: r'khoi', required: true, includeIfNull: false)
  final num khoi;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassesInput &&
          other.maNamHoc == maNamHoc &&
          other.maGvChuNhiem == maGvChuNhiem &&
          other.tenLop == tenLop &&
          other.khoi == khoi;

  @override
  int get hashCode =>
      maNamHoc.hashCode +
      maGvChuNhiem.hashCode +
      tenLop.hashCode +
      khoi.hashCode;

  factory ClassesInput.fromJson(Map<String, dynamic> json) =>
      _$ClassesInputFromJson(json);

  Map<String, dynamic> toJson() => _$ClassesInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
