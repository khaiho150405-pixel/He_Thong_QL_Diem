//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/account_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'accounts_import_result.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AccountsImportResult {
  /// Returns a new [AccountsImportResult] instance.
  AccountsImportResult({required this.imported, required this.items});

  @JsonKey(name: r'imported', required: true, includeIfNull: false)
  final num imported;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<AccountDto> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountsImportResult &&
          other.imported == imported &&
          other.items == items;

  @override
  int get hashCode => imported.hashCode + items.hashCode;

  factory AccountsImportResult.fromJson(Map<String, dynamic> json) =>
      _$AccountsImportResultFromJson(json);

  Map<String, dynamic> toJson() => _$AccountsImportResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
