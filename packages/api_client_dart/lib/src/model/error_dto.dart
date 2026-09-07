//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'error_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ErrorDto {
  /// Returns a new [ErrorDto] instance.
  ErrorDto({
    required this.code,

    required this.message,

    required this.details,

    required this.requestId,
  });

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'message', required: true, includeIfNull: false)
  final String message;

  @JsonKey(name: r'details', required: true, includeIfNull: true)
  final Object? details;

  @JsonKey(name: r'requestId', required: true, includeIfNull: false)
  final String requestId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorDto &&
          other.code == code &&
          other.message == message &&
          other.details == details &&
          other.requestId == requestId;

  @override
  int get hashCode =>
      code.hashCode +
      message.hashCode +
      (details == null ? 0 : details.hashCode) +
      requestId.hashCode;

  factory ErrorDto.fromJson(Map<String, dynamic> json) =>
      _$ErrorDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
