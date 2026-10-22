//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/exempted_student_dto.dart';
import 'package:api_client_dart/src/model/skipped_student_dto.dart';
import 'package:api_client_dart/src/model/final_result_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'final_result_list_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FinalResultListDto {
  /// Returns a new [FinalResultListDto] instance.
  FinalResultListDto({
    required this.items,

    required this.nextCursor,

    required this.exemptedStudents,

    required this.exempted,

    required this.skippedStudents,

    required this.skipped,
  });

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<FinalResultDto> items;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final String? nextCursor;

  /// Số học sinh được miễn mọi ô của bảng (tính theo dữ liệu hiện tại, không theo cursor)
  @JsonKey(name: r'exemptedStudents', required: true, includeIfNull: false)
  final num exemptedStudents;

  @JsonKey(name: r'exempted', required: true, includeIfNull: false)
  final List<ExemptedStudentDto> exempted;

  /// Số học sinh còn thiếu cột bắt buộc (tính theo dữ liệu hiện tại, không theo cursor)
  @JsonKey(name: r'skippedStudents', required: true, includeIfNull: false)
  final num skippedStudents;

  @JsonKey(name: r'skipped', required: true, includeIfNull: false)
  final List<SkippedStudentDto> skipped;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinalResultListDto &&
          other.items == items &&
          other.nextCursor == nextCursor &&
          other.exemptedStudents == exemptedStudents &&
          other.exempted == exempted &&
          other.skippedStudents == skippedStudents &&
          other.skipped == skipped;

  @override
  int get hashCode =>
      items.hashCode +
      (nextCursor == null ? 0 : nextCursor.hashCode) +
      exemptedStudents.hashCode +
      exempted.hashCode +
      skippedStudents.hashCode +
      skipped.hashCode;

  factory FinalResultListDto.fromJson(Map<String, dynamic> json) =>
      _$FinalResultListDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FinalResultListDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
