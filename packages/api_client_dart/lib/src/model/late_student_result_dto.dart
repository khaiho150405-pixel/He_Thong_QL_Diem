//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'late_student_result_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LateStudentResultDto {
  /// Returns a new [LateStudentResultDto] instance.
  LateStudentResultDto({
    required this.bookId,

    required this.version,

    required this.createdCells,

    required this.exemptedCells,
  });

  @JsonKey(name: r'bookId', required: true, includeIfNull: false)
  final num bookId;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final num version;

  /// Tổng số ô được tạo (gồm cả ô MIEN)
  @JsonKey(name: r'createdCells', required: true, includeIfNull: false)
  final num createdCells;

  /// Số ô MIEN trong các ô vừa tạo (cột đã chốt)
  @JsonKey(name: r'exemptedCells', required: true, includeIfNull: false)
  final num exemptedCells;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LateStudentResultDto &&
          other.bookId == bookId &&
          other.version == version &&
          other.createdCells == createdCells &&
          other.exemptedCells == exemptedCells;

  @override
  int get hashCode =>
      bookId.hashCode +
      version.hashCode +
      createdCells.hashCode +
      exemptedCells.hashCode;

  factory LateStudentResultDto.fromJson(Map<String, dynamic> json) =>
      _$LateStudentResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LateStudentResultDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
