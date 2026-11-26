//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'year_closing_event_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class YearClosingEventDto {
  /// Returns a new [YearClosingEventDto] instance.
  YearClosingEventDto({
    required this.action,

    required this.reason,

    required this.actor,

    required this.at,
  });

  /// DONG hoặc MO_LAI
  @JsonKey(name: r'action', required: true, includeIfNull: false)
  final String action;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @JsonKey(name: r'actor', required: true, includeIfNull: false)
  final String actor;

  @JsonKey(name: r'at', required: true, includeIfNull: false)
  final String at;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearClosingEventDto &&
          other.action == action &&
          other.reason == reason &&
          other.actor == actor &&
          other.at == at;

  @override
  int get hashCode =>
      action.hashCode + reason.hashCode + actor.hashCode + at.hashCode;

  factory YearClosingEventDto.fromJson(Map<String, dynamic> json) =>
      _$YearClosingEventDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YearClosingEventDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
