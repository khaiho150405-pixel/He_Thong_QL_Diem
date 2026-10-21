//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/publish_issue_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'publish_readiness_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublishReadinessDto {
  /// Returns a new [PublishReadinessDto] instance.
  PublishReadinessDto({required this.ready, required this.issues});

  @JsonKey(name: r'ready', required: true, includeIfNull: false)
  final bool ready;

  @JsonKey(name: r'issues', required: true, includeIfNull: false)
  final List<PublishIssueDto> issues;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublishReadinessDto &&
          other.ready == ready &&
          other.issues == issues;

  @override
  int get hashCode => ready.hashCode + issues.hashCode;

  factory PublishReadinessDto.fromJson(Map<String, dynamic> json) =>
      _$PublishReadinessDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PublishReadinessDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
