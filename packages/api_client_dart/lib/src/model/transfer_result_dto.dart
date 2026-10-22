//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/affected_gradebook_dto.dart';
import 'package:api_client_dart/src/model/enrollment_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transfer_result_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TransferResultDto {
  /// Returns a new [TransferResultDto] instance.
  TransferResultDto({
    required this.enrollment,

    required this.affectedGradebooks,
  });

  @JsonKey(name: r'enrollment', required: true, includeIfNull: false)
  final EnrollmentDto enrollment;

  /// Bảng điểm của lớp mới thuộc các học kỳ từ ngày hiệu lực; ô điểm không được tự tạo
  @JsonKey(name: r'affectedGradebooks', required: true, includeIfNull: false)
  final List<AffectedGradebookDto> affectedGradebooks;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferResultDto &&
          other.enrollment == enrollment &&
          other.affectedGradebooks == affectedGradebooks;

  @override
  int get hashCode => enrollment.hashCode + affectedGradebooks.hashCode;

  factory TransferResultDto.fromJson(Map<String, dynamic> json) =>
      _$TransferResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TransferResultDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
