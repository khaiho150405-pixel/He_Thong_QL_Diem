//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/account_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'accounts_import_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AccountsImportInput {
  /// Returns a new [AccountsImportInput] instance.
  AccountsImportInput({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<AccountInput> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountsImportInput && other.items == items;

  @override
  int get hashCode => items.hashCode;

  factory AccountsImportInput.fromJson(Map<String, dynamic> json) =>
      _$AccountsImportInputFromJson(json);

  Map<String, dynamic> toJson() => _$AccountsImportInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
