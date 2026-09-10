//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'years_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class YearsInput {
  /// Returns a new [YearsInput] instance.
  YearsInput({
    required this.ten,

    required this.ngayBatDau,

    required this.ngayKetThuc,

    required this.hienHanh,
  });

  @JsonKey(name: r'ten', required: true, includeIfNull: false)
  final String ten;

  @JsonKey(name: r'ngay_bat_dau', required: true, includeIfNull: false)
  final String ngayBatDau;

  @JsonKey(name: r'ngay_ket_thuc', required: true, includeIfNull: false)
  final String ngayKetThuc;

  @JsonKey(name: r'hien_hanh', required: true, includeIfNull: false)
  final bool hienHanh;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearsInput &&
          other.ten == ten &&
          other.ngayBatDau == ngayBatDau &&
          other.ngayKetThuc == ngayKetThuc &&
          other.hienHanh == hienHanh;

  @override
  int get hashCode =>
      ten.hashCode +
      ngayBatDau.hashCode +
      ngayKetThuc.hashCode +
      hienHanh.hashCode;

  factory YearsInput.fromJson(Map<String, dynamic> json) =>
      _$YearsInputFromJson(json);

  Map<String, dynamic> toJson() => _$YearsInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
