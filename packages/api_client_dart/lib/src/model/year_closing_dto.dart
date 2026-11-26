//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/year_closing_event_dto.dart';
import 'package:api_client_dart/src/model/year_closing_issue_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'year_closing_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class YearClosingDto {
  /// Returns a new [YearClosingDto] instance.
  YearClosingDto({
    required this.yearId,

    required this.closedAt,

    required this.ready,

    required this.issues,

    required this.history,
  });

  @JsonKey(name: r'yearId', required: true, includeIfNull: false)
  final num yearId;

  @JsonKey(name: r'closedAt', required: true, includeIfNull: true)
  final String? closedAt;

  @JsonKey(name: r'ready', required: true, includeIfNull: false)
  final bool ready;

  @JsonKey(name: r'issues', required: true, includeIfNull: false)
  final List<YearClosingIssueDto> issues;

  @JsonKey(name: r'history', required: true, includeIfNull: false)
  final List<YearClosingEventDto> history;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearClosingDto &&
          other.yearId == yearId &&
          other.closedAt == closedAt &&
          other.ready == ready &&
          other.issues == issues &&
          other.history == history;

  @override
  int get hashCode =>
      yearId.hashCode +
      (closedAt == null ? 0 : closedAt.hashCode) +
      ready.hashCode +
      issues.hashCode +
      history.hashCode;

  factory YearClosingDto.fromJson(Map<String, dynamic> json) =>
      _$YearClosingDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YearClosingDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
