//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'account_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AccountInput {
  /// Returns a new [AccountInput] instance.
  AccountInput({
    required this.username,

    required this.password,

    required this.role,
  });

  @JsonKey(name: r'username', required: true, includeIfNull: false)
  final String username;

  @JsonKey(name: r'password', required: true, includeIfNull: false)
  final String password;

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final AccountInputRoleEnum role;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountInput &&
          other.username == username &&
          other.password == password &&
          other.role == role;

  @override
  int get hashCode => username.hashCode + password.hashCode + role.hashCode;

  factory AccountInput.fromJson(Map<String, dynamic> json) =>
      _$AccountInputFromJson(json);

  Map<String, dynamic> toJson() => _$AccountInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AccountInputRoleEnum {
  @JsonValue(r'QUAN_TRI_VIEN')
  QUAN_TRI_VIEN(r'QUAN_TRI_VIEN'),
  @JsonValue(r'GIAO_VIEN')
  GIAO_VIEN(r'GIAO_VIEN'),
  @JsonValue(r'HOC_SINH')
  HOC_SINH(r'HOC_SINH');

  const AccountInputRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
