// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'year_pending_summary_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$YearPendingSummaryDtoCWProxy {
  YearPendingSummaryDto openGradebooks(num openGradebooks);

  YearPendingSummaryDto pendingRecognitionTickets(
    num pendingRecognitionTickets,
  );

  YearPendingSummaryDto unpublishedSemesters(num unpublishedSemesters);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearPendingSummaryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearPendingSummaryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  YearPendingSummaryDto call({
    num openGradebooks,
    num pendingRecognitionTickets,
    num unpublishedSemesters,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfYearPendingSummaryDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfYearPendingSummaryDto.copyWith.fieldName(...)`
class _$YearPendingSummaryDtoCWProxyImpl
    implements _$YearPendingSummaryDtoCWProxy {
  const _$YearPendingSummaryDtoCWProxyImpl(this._value);

  final YearPendingSummaryDto _value;

  @override
  YearPendingSummaryDto openGradebooks(num openGradebooks) =>
      this(openGradebooks: openGradebooks);

  @override
  YearPendingSummaryDto pendingRecognitionTickets(
    num pendingRecognitionTickets,
  ) => this(pendingRecognitionTickets: pendingRecognitionTickets);

  @override
  YearPendingSummaryDto unpublishedSemesters(num unpublishedSemesters) =>
      this(unpublishedSemesters: unpublishedSemesters);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearPendingSummaryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearPendingSummaryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  YearPendingSummaryDto call({
    Object? openGradebooks = const $CopyWithPlaceholder(),
    Object? pendingRecognitionTickets = const $CopyWithPlaceholder(),
    Object? unpublishedSemesters = const $CopyWithPlaceholder(),
  }) {
    return YearPendingSummaryDto(
      openGradebooks: openGradebooks == const $CopyWithPlaceholder()
          ? _value.openGradebooks
          // ignore: cast_nullable_to_non_nullable
          : openGradebooks as num,
      pendingRecognitionTickets:
          pendingRecognitionTickets == const $CopyWithPlaceholder()
          ? _value.pendingRecognitionTickets
          // ignore: cast_nullable_to_non_nullable
          : pendingRecognitionTickets as num,
      unpublishedSemesters: unpublishedSemesters == const $CopyWithPlaceholder()
          ? _value.unpublishedSemesters
          // ignore: cast_nullable_to_non_nullable
          : unpublishedSemesters as num,
    );
  }
}

extension $YearPendingSummaryDtoCopyWith on YearPendingSummaryDto {
  /// Returns a callable class that can be used as follows: `instanceOfYearPendingSummaryDto.copyWith(...)` or like so:`instanceOfYearPendingSummaryDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$YearPendingSummaryDtoCWProxy get copyWith =>
      _$YearPendingSummaryDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YearPendingSummaryDto _$YearPendingSummaryDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('YearPendingSummaryDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'openGradebooks',
      'pendingRecognitionTickets',
      'unpublishedSemesters',
    ],
  );
  final val = YearPendingSummaryDto(
    openGradebooks: $checkedConvert('openGradebooks', (v) => v as num),
    pendingRecognitionTickets: $checkedConvert(
      'pendingRecognitionTickets',
      (v) => v as num,
    ),
    unpublishedSemesters: $checkedConvert(
      'unpublishedSemesters',
      (v) => v as num,
    ),
  );
  return val;
});

Map<String, dynamic> _$YearPendingSummaryDtoToJson(
  YearPendingSummaryDto instance,
) => <String, dynamic>{
  'openGradebooks': instance.openGradebooks,
  'pendingRecognitionTickets': instance.pendingRecognitionTickets,
  'unpublishedSemesters': instance.unpublishedSemesters,
};
