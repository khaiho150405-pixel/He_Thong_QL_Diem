//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/semester_weights_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'semester_weights_page.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SemesterWeightsPage {
  /// Returns a new [SemesterWeightsPage] instance.
  SemesterWeightsPage({required this.items, required this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<SemesterWeightsDto> items;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemesterWeightsPage &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory SemesterWeightsPage.fromJson(Map<String, dynamic> json) =>
      _$SemesterWeightsPageFromJson(json);

  Map<String, dynamic> toJson() => _$SemesterWeightsPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
