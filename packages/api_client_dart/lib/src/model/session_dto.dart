//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SessionDto {
  /// Returns a new [SessionDto] instance.
  SessionDto({
    required this.id,

    required this.username,

    required this.role,

    required this.active,

    required this.token,

    required this.csrf,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final num id;

  @JsonKey(name: r'username', required: true, includeIfNull: false)
  final String username;

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final SessionDtoRoleEnum role;

  @JsonKey(name: r'active', required: true, includeIfNull: false)
  final bool active;

  @JsonKey(name: r'token', required: true, includeIfNull: true)
  final String? token;

  @JsonKey(name: r'csrf', required: true, includeIfNull: false)
  final String csrf;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionDto &&
          other.id == id &&
          other.username == username &&
          other.role == role &&
          other.active == active &&
          other.token == token &&
          other.csrf == csrf;

  @override
  int get hashCode =>
      id.hashCode +
      username.hashCode +
      role.hashCode +
      active.hashCode +
      (token == null ? 0 : token.hashCode) +
      csrf.hashCode;

  factory SessionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SessionDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum SessionDtoRoleEnum {
  @JsonValue(r'QUAN_TRI_VIEN')
  QUAN_TRI_VIEN(r'QUAN_TRI_VIEN'),
  @JsonValue(r'GIAO_VIEN')
  GIAO_VIEN(r'GIAO_VIEN'),
  @JsonValue(r'HOC_SINH')
  HOC_SINH(r'HOC_SINH');

  const SessionDtoRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
