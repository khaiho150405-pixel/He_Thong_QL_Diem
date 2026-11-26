//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'year_closing_issue_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class YearClosingIssueDto {
  /// Returns a new [YearClosingIssueDto] instance.
  YearClosingIssueDto({
    required this.code,

    required this.severity,

    required this.label,

    required this.count,
  });

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  /// BLOCKING hoặc WARNING
  @JsonKey(name: r'severity', required: true, includeIfNull: false)
  final String severity;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'count', required: true, includeIfNull: false)
  final num count;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearClosingIssueDto &&
          other.code == code &&
          other.severity == severity &&
          other.label == label &&
          other.count == count;

  @override
  int get hashCode =>
      code.hashCode + severity.hashCode + label.hashCode + count.hashCode;

  factory YearClosingIssueDto.fromJson(Map<String, dynamic> json) =>
      _$YearClosingIssueDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YearClosingIssueDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
