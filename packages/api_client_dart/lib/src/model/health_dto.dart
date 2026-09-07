//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'health_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HealthDto {
  /// Returns a new [HealthDto] instance.
  HealthDto({required this.status});

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final HealthDtoStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HealthDto && other.status == status;

  @override
  int get hashCode => status.hashCode;

  factory HealthDto.fromJson(Map<String, dynamic> json) =>
      _$HealthDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HealthDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum HealthDtoStatusEnum {
  @JsonValue(r'ok')
  ok(r'ok');

  const HealthDtoStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
