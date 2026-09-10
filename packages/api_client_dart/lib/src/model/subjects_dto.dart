//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subjects_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubjectsDto {
  /// Returns a new [SubjectsDto] instance.
  SubjectsDto({
    required this.tenMon,

    required this.soTietTuan,

    required this.label,

    required this.maMon,
  });

  @JsonKey(name: r'ten_mon', required: true, includeIfNull: false)
  final String tenMon;

  @JsonKey(name: r'so_tiet_tuan', required: true, includeIfNull: false)
  final num soTietTuan;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'ma_mon', required: true, includeIfNull: false)
  final num maMon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectsDto &&
          other.tenMon == tenMon &&
          other.soTietTuan == soTietTuan &&
          other.label == label &&
          other.maMon == maMon;

  @override
  int get hashCode =>
      tenMon.hashCode + soTietTuan.hashCode + label.hashCode + maMon.hashCode;

  factory SubjectsDto.fromJson(Map<String, dynamic> json) =>
      _$SubjectsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SubjectsDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
