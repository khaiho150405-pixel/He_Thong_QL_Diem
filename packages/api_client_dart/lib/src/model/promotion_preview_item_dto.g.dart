// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_preview_item_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PromotionPreviewItemDtoCWProxy {
  PromotionPreviewItemDto studentId(num studentId);

  PromotionPreviewItemDto studentName(String studentName);

  PromotionPreviewItemDto order(num order);

  PromotionPreviewItemDto suggestedAction(
    PromotionPreviewItemDtoSuggestedActionEnum suggestedAction,
  );

  PromotionPreviewItemDto suggestedTargetClassId(num? suggestedTargetClassId);

  PromotionPreviewItemDto alreadyEnrolledInTargetYear(
    bool alreadyEnrolledInTargetYear,
  );

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PromotionPreviewItemDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PromotionPreviewItemDto(...).copyWith(id: 12, name: "My name")
  /// ````
  PromotionPreviewItemDto call({
    num studentId,
    String studentName,
    num order,
    PromotionPreviewItemDtoSuggestedActionEnum suggestedAction,
    num? suggestedTargetClassId,
    bool alreadyEnrolledInTargetYear,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPromotionPreviewItemDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPromotionPreviewItemDto.copyWith.fieldName(...)`
class _$PromotionPreviewItemDtoCWProxyImpl
    implements _$PromotionPreviewItemDtoCWProxy {
  const _$PromotionPreviewItemDtoCWProxyImpl(this._value);

  final PromotionPreviewItemDto _value;

  @override
  PromotionPreviewItemDto studentId(num studentId) =>
      this(studentId: studentId);

  @override
  PromotionPreviewItemDto studentName(String studentName) =>
      this(studentName: studentName);

  @override
  PromotionPreviewItemDto order(num order) => this(order: order);

  @override
  PromotionPreviewItemDto suggestedAction(
    PromotionPreviewItemDtoSuggestedActionEnum suggestedAction,
  ) => this(suggestedAction: suggestedAction);

  @override
  PromotionPreviewItemDto suggestedTargetClassId(num? suggestedTargetClassId) =>
      this(suggestedTargetClassId: suggestedTargetClassId);

  @override
  PromotionPreviewItemDto alreadyEnrolledInTargetYear(
    bool alreadyEnrolledInTargetYear,
  ) => this(alreadyEnrolledInTargetYear: alreadyEnrolledInTargetYear);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PromotionPreviewItemDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PromotionPreviewItemDto(...).copyWith(id: 12, name: "My name")
  /// ````
  PromotionPreviewItemDto call({
    Object? studentId = const $CopyWithPlaceholder(),
    Object? studentName = const $CopyWithPlaceholder(),
    Object? order = const $CopyWithPlaceholder(),
    Object? suggestedAction = const $CopyWithPlaceholder(),
    Object? suggestedTargetClassId = const $CopyWithPlaceholder(),
    Object? alreadyEnrolledInTargetYear = const $CopyWithPlaceholder(),
  }) {
    return PromotionPreviewItemDto(
      studentId: studentId == const $CopyWithPlaceholder()
          ? _value.studentId
          // ignore: cast_nullable_to_non_nullable
          : studentId as num,
      studentName: studentName == const $CopyWithPlaceholder()
          ? _value.studentName
          // ignore: cast_nullable_to_non_nullable
          : studentName as String,
      order: order == const $CopyWithPlaceholder()
          ? _value.order
          // ignore: cast_nullable_to_non_nullable
          : order as num,
      suggestedAction: suggestedAction == const $CopyWithPlaceholder()
          ? _value.suggestedAction
          // ignore: cast_nullable_to_non_nullable
          : suggestedAction as PromotionPreviewItemDtoSuggestedActionEnum,
      suggestedTargetClassId:
          suggestedTargetClassId == const $CopyWithPlaceholder()
          ? _value.suggestedTargetClassId
          // ignore: cast_nullable_to_non_nullable
          : suggestedTargetClassId as num?,
      alreadyEnrolledInTargetYear:
          alreadyEnrolledInTargetYear == const $CopyWithPlaceholder()
          ? _value.alreadyEnrolledInTargetYear
          // ignore: cast_nullable_to_non_nullable
          : alreadyEnrolledInTargetYear as bool,
    );
  }
}

extension $PromotionPreviewItemDtoCopyWith on PromotionPreviewItemDto {
  /// Returns a callable class that can be used as follows: `instanceOfPromotionPreviewItemDto.copyWith(...)` or like so:`instanceOfPromotionPreviewItemDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PromotionPreviewItemDtoCWProxy get copyWith =>
      _$PromotionPreviewItemDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromotionPreviewItemDto _$PromotionPreviewItemDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PromotionPreviewItemDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'studentId',
      'studentName',
      'order',
      'suggestedAction',
      'suggestedTargetClassId',
      'alreadyEnrolledInTargetYear',
    ],
  );
  final val = PromotionPreviewItemDto(
    studentId: $checkedConvert('studentId', (v) => v as num),
    studentName: $checkedConvert('studentName', (v) => v as String),
    order: $checkedConvert('order', (v) => v as num),
    suggestedAction: $checkedConvert(
      'suggestedAction',
      (v) =>
          $enumDecode(_$PromotionPreviewItemDtoSuggestedActionEnumEnumMap, v),
    ),
    suggestedTargetClassId: $checkedConvert(
      'suggestedTargetClassId',
      (v) => v as num?,
    ),
    alreadyEnrolledInTargetYear: $checkedConvert(
      'alreadyEnrolledInTargetYear',
      (v) => v as bool,
    ),
  );
  return val;
});

Map<String, dynamic> _$PromotionPreviewItemDtoToJson(
  PromotionPreviewItemDto instance,
) => <String, dynamic>{
  'studentId': instance.studentId,
  'studentName': instance.studentName,
  'order': instance.order,
  'suggestedAction':
      _$PromotionPreviewItemDtoSuggestedActionEnumEnumMap[instance
          .suggestedAction]!,
  'suggestedTargetClassId': instance.suggestedTargetClassId,
  'alreadyEnrolledInTargetYear': instance.alreadyEnrolledInTargetYear,
};

const _$PromotionPreviewItemDtoSuggestedActionEnumEnumMap = {
  PromotionPreviewItemDtoSuggestedActionEnum.LEN_LOP: 'LEN_LOP',
  PromotionPreviewItemDtoSuggestedActionEnum.TOT_NGHIEP: 'TOT_NGHIEP',
};
