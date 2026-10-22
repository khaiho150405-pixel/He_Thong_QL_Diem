//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/adjustment_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'adjustment_list_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdjustmentListDto {
  /// Returns a new [AdjustmentListDto] instance.
  AdjustmentListDto({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<AdjustmentDto> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdjustmentListDto && other.items == items;

  @override
  int get hashCode => items.hashCode;

  factory AdjustmentListDto.fromJson(Map<String, dynamic> json) =>
      _$AdjustmentListDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AdjustmentListDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
