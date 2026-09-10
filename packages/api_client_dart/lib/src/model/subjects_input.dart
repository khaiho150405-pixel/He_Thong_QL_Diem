//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subjects_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubjectsInput {
  /// Returns a new [SubjectsInput] instance.
  SubjectsInput({required this.tenMon, required this.soTietTuan});

  @JsonKey(name: r'ten_mon', required: true, includeIfNull: false)
  final String tenMon;

  @JsonKey(name: r'so_tiet_tuan', required: true, includeIfNull: false)
  final num soTietTuan;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectsInput &&
          other.tenMon == tenMon &&
          other.soTietTuan == soTietTuan;

  @override
  int get hashCode => tenMon.hashCode + soTietTuan.hashCode;

  factory SubjectsInput.fromJson(Map<String, dynamic> json) =>
      _$SubjectsInputFromJson(json);

  Map<String, dynamic> toJson() => _$SubjectsInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
