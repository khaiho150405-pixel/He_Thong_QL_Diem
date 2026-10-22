//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/promotion_item_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'promotion_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PromotionInput {
  /// Returns a new [PromotionInput] instance.
  PromotionInput({required this.targetYearId, required this.items});

  @JsonKey(name: r'targetYearId', required: true, includeIfNull: false)
  final num targetYearId;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<PromotionItemInput> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromotionInput &&
          other.targetYearId == targetYearId &&
          other.items == items;

  @override
  int get hashCode => targetYearId.hashCode + items.hashCode;

  factory PromotionInput.fromJson(Map<String, dynamic> json) =>
      _$PromotionInputFromJson(json);

  Map<String, dynamic> toJson() => _$PromotionInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
