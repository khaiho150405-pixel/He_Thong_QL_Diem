// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_approval_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReviewApprovalInputCWProxy {
  ReviewApprovalInput expectedTicketVersion(num expectedTicketVersion);

  ReviewApprovalInput expectedGradebookVersion(num expectedGradebookVersion);

  ReviewApprovalInput decisions(List<ReviewDecisionInput> decisions);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReviewApprovalInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReviewApprovalInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ReviewApprovalInput call({
    num expectedTicketVersion,
    num expectedGradebookVersion,
    List<ReviewDecisionInput> decisions,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReviewApprovalInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReviewApprovalInput.copyWith.fieldName(...)`
class _$ReviewApprovalInputCWProxyImpl implements _$ReviewApprovalInputCWProxy {
  const _$ReviewApprovalInputCWProxyImpl(this._value);

  final ReviewApprovalInput _value;

  @override
  ReviewApprovalInput expectedTicketVersion(num expectedTicketVersion) =>
      this(expectedTicketVersion: expectedTicketVersion);

  @override
  ReviewApprovalInput expectedGradebookVersion(num expectedGradebookVersion) =>
      this(expectedGradebookVersion: expectedGradebookVersion);

  @override
  ReviewApprovalInput decisions(List<ReviewDecisionInput> decisions) =>
      this(decisions: decisions);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReviewApprovalInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReviewApprovalInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ReviewApprovalInput call({
    Object? expectedTicketVersion = const $CopyWithPlaceholder(),
    Object? expectedGradebookVersion = const $CopyWithPlaceholder(),
    Object? decisions = const $CopyWithPlaceholder(),
  }) {
    return ReviewApprovalInput(
      expectedTicketVersion:
          expectedTicketVersion == const $CopyWithPlaceholder()
          ? _value.expectedTicketVersion
          // ignore: cast_nullable_to_non_nullable
          : expectedTicketVersion as num,
      expectedGradebookVersion:
          expectedGradebookVersion == const $CopyWithPlaceholder()
          ? _value.expectedGradebookVersion
          // ignore: cast_nullable_to_non_nullable
          : expectedGradebookVersion as num,
      decisions: decisions == const $CopyWithPlaceholder()
          ? _value.decisions
          // ignore: cast_nullable_to_non_nullable
          : decisions as List<ReviewDecisionInput>,
    );
  }
}

extension $ReviewApprovalInputCopyWith on ReviewApprovalInput {
  /// Returns a callable class that can be used as follows: `instanceOfReviewApprovalInput.copyWith(...)` or like so:`instanceOfReviewApprovalInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReviewApprovalInputCWProxy get copyWith =>
      _$ReviewApprovalInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewApprovalInput _$ReviewApprovalInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReviewApprovalInput', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'expectedTicketVersion',
          'expectedGradebookVersion',
          'decisions',
        ],
      );
      final val = ReviewApprovalInput(
        expectedTicketVersion: $checkedConvert(
          'expectedTicketVersion',
          (v) => v as num,
        ),
        expectedGradebookVersion: $checkedConvert(
          'expectedGradebookVersion',
          (v) => v as num,
        ),
        decisions: $checkedConvert(
          'decisions',
          (v) => (v as List<dynamic>)
              .map(
                (e) => ReviewDecisionInput.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ReviewApprovalInputToJson(
  ReviewApprovalInput instance,
) => <String, dynamic>{
  'expectedTicketVersion': instance.expectedTicketVersion,
  'expectedGradebookVersion': instance.expectedGradebookVersion,
  'decisions': instance.decisions.map((e) => e.toJson()).toList(),
};
