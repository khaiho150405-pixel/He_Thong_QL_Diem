//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/grade_change_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'batch_update_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BatchUpdateInput {
  /// Returns a new [BatchUpdateInput] instance.
  BatchUpdateInput({required this.expectedVersion, required this.changes});

  // minimum: 0
  @JsonKey(name: r'expectedVersion', required: true, includeIfNull: false)
  final num expectedVersion;

  @JsonKey(name: r'changes', required: true, includeIfNull: false)
  final List<GradeChangeInput> changes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchUpdateInput &&
          other.expectedVersion == expectedVersion &&
          other.changes == changes;

  @override
  int get hashCode => expectedVersion.hashCode + changes.hashCode;

  factory BatchUpdateInput.fromJson(Map<String, dynamic> json) =>
      _$BatchUpdateInputFromJson(json);

  Map<String, dynamic> toJson() => _$BatchUpdateInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
