//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/review_decision_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'review_approval_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReviewApprovalInput {
  /// Returns a new [ReviewApprovalInput] instance.
  ReviewApprovalInput({
    required this.expectedTicketVersion,

    required this.expectedGradebookVersion,

    required this.decisions,
  });

  // minimum: 0
  @JsonKey(name: r'expectedTicketVersion', required: true, includeIfNull: false)
  final num expectedTicketVersion;

  // minimum: 0
  @JsonKey(
    name: r'expectedGradebookVersion',
    required: true,
    includeIfNull: false,
  )
  final num expectedGradebookVersion;

  @JsonKey(name: r'decisions', required: true, includeIfNull: false)
  final List<ReviewDecisionInput> decisions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewApprovalInput &&
          other.expectedTicketVersion == expectedTicketVersion &&
          other.expectedGradebookVersion == expectedGradebookVersion &&
          other.decisions == decisions;

  @override
  int get hashCode =>
      expectedTicketVersion.hashCode +
      expectedGradebookVersion.hashCode +
      decisions.hashCode;

  factory ReviewApprovalInput.fromJson(Map<String, dynamic> json) =>
      _$ReviewApprovalInputFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewApprovalInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
