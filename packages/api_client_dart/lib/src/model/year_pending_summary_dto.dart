//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'year_pending_summary_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class YearPendingSummaryDto {
  /// Returns a new [YearPendingSummaryDto] instance.
  YearPendingSummaryDto({
    required this.openGradebooks,

    required this.pendingRecognitionTickets,

    required this.unpublishedSemesters,
  });

  /// Bảng điểm chưa chốt
  @JsonKey(name: r'openGradebooks', required: true, includeIfNull: false)
  final num openGradebooks;

  /// Phiếu nhận dạng đang xử lý hoặc chờ đối chiếu
  @JsonKey(
    name: r'pendingRecognitionTickets',
    required: true,
    includeIfNull: false,
  )
  final num pendingRecognitionTickets;

  /// Học kỳ chưa công bố
  @JsonKey(name: r'unpublishedSemesters', required: true, includeIfNull: false)
  final num unpublishedSemesters;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearPendingSummaryDto &&
          other.openGradebooks == openGradebooks &&
          other.pendingRecognitionTickets == pendingRecognitionTickets &&
          other.unpublishedSemesters == unpublishedSemesters;

  @override
  int get hashCode =>
      openGradebooks.hashCode +
      pendingRecognitionTickets.hashCode +
      unpublishedSemesters.hashCode;

  factory YearPendingSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$YearPendingSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YearPendingSummaryDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
