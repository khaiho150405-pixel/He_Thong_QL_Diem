//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/years_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'years_page.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class YearsPage {
  /// Returns a new [YearsPage] instance.
  YearsPage({required this.items, required this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<YearsDto> items;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearsPage &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory YearsPage.fromJson(Map<String, dynamic> json) =>
      _$YearsPageFromJson(json);

  Map<String, dynamic> toJson() => _$YearsPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
