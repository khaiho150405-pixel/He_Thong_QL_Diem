//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'password_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PasswordInput {
  /// Returns a new [PasswordInput] instance.
  PasswordInput({required this.currentPassword, required this.newPassword});

  @JsonKey(name: r'currentPassword', required: true, includeIfNull: false)
  final String currentPassword;

  @JsonKey(name: r'newPassword', required: true, includeIfNull: false)
  final String newPassword;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasswordInput &&
          other.currentPassword == currentPassword &&
          other.newPassword == newPassword;

  @override
  int get hashCode => currentPassword.hashCode + newPassword.hashCode;

  factory PasswordInput.fromJson(Map<String, dynamic> json) =>
      _$PasswordInputFromJson(json);

  Map<String, dynamic> toJson() => _$PasswordInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
