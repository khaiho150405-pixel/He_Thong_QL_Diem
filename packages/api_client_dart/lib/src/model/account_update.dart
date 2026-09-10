//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'account_update.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AccountUpdate {
  /// Returns a new [AccountUpdate] instance.
  AccountUpdate({required this.role, required this.active, this.password});

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final AccountUpdateRoleEnum role;

  @JsonKey(name: r'active', required: true, includeIfNull: false)
  final bool active;

  @JsonKey(name: r'password', required: false, includeIfNull: false)
  final String? password;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountUpdate &&
          other.role == role &&
          other.active == active &&
          other.password == password;

  @override
  int get hashCode => role.hashCode + active.hashCode + password.hashCode;

  factory AccountUpdate.fromJson(Map<String, dynamic> json) =>
      _$AccountUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$AccountUpdateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AccountUpdateRoleEnum {
  @JsonValue(r'QUAN_TRI_VIEN')
  QUAN_TRI_VIEN(r'QUAN_TRI_VIEN'),
  @JsonValue(r'GIAO_VIEN')
  GIAO_VIEN(r'GIAO_VIEN'),
  @JsonValue(r'HOC_SINH')
  HOC_SINH(r'HOC_SINH');

  const AccountUpdateRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
