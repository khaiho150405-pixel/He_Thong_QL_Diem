//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/try_grade_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'try_row_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TryRowDto {
  /// Returns a new [TryRowDto] instance.
  TryRowDto({
    required this.rowIndex,

    required this.struck,

    required this.sttRead,

    required this.nameRead,

    required this.grades,
  });

  @JsonKey(name: r'rowIndex', required: true, includeIfNull: false)
  final num rowIndex;

  @JsonKey(name: r'struck', required: true, includeIfNull: false)
  final bool struck;

  /// STT đọc được
  @JsonKey(name: r'sttRead', required: true, includeIfNull: true)
  final num? sttRead;

  /// Họ tên máy đọc được (không ghép với học sinh hệ thống)
  @JsonKey(name: r'nameRead', required: true, includeIfNull: true)
  final String? nameRead;

  @JsonKey(name: r'grades', required: true, includeIfNull: false)
  final List<TryGradeDto> grades;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TryRowDto &&
          other.rowIndex == rowIndex &&
          other.struck == struck &&
          other.sttRead == sttRead &&
          other.nameRead == nameRead &&
          other.grades == grades;

  @override
  int get hashCode =>
      rowIndex.hashCode +
      struck.hashCode +
      (sttRead == null ? 0 : sttRead.hashCode) +
      (nameRead == null ? 0 : nameRead.hashCode) +
      grades.hashCode;

  factory TryRowDto.fromJson(Map<String, dynamic> json) =>
      _$TryRowDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TryRowDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
