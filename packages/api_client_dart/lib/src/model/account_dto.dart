//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'account_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AccountDto {
  /// Returns a new [AccountDto] instance.
  AccountDto({
    required this.id,

    required this.username,

    required this.role,

    required this.active,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final num id;

  @JsonKey(name: r'username', required: true, includeIfNull: false)
  final String username;

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final AccountDtoRoleEnum role;

  @JsonKey(name: r'active', required: true, includeIfNull: false)
  final bool active;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountDto &&
          other.id == id &&
          other.username == username &&
          other.role == role &&
          other.active == active;

  @override
  int get hashCode =>
      id.hashCode + username.hashCode + role.hashCode + active.hashCode;

  factory AccountDto.fromJson(Map<String, dynamic> json) =>
      _$AccountDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AccountDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AccountDtoRoleEnum {
  @JsonValue(r'QUAN_TRI_VIEN')
  QUAN_TRI_VIEN(r'QUAN_TRI_VIEN'),
  @JsonValue(r'GIAO_VIEN')
  GIAO_VIEN(r'GIAO_VIEN'),
  @JsonValue(r'HOC_SINH')
  HOC_SINH(r'HOC_SINH');

  const AccountDtoRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
