// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analyze_result_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AnalyzeResultDtoCWProxy {
  AnalyzeResultDto columnCount(num columnCount);

  AnalyzeResultDto columns(List<AnalyzedColumnDto> columns);

  AnalyzeResultDto previewPngBase64(String previewPngBase64);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AnalyzeResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AnalyzeResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AnalyzeResultDto call({
    num columnCount,
    List<AnalyzedColumnDto> columns,
    String previewPngBase64,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAnalyzeResultDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAnalyzeResultDto.copyWith.fieldName(...)`
class _$AnalyzeResultDtoCWProxyImpl implements _$AnalyzeResultDtoCWProxy {
  const _$AnalyzeResultDtoCWProxyImpl(this._value);

  final AnalyzeResultDto _value;

  @override
  AnalyzeResultDto columnCount(num columnCount) =>
      this(columnCount: columnCount);

  @override
  AnalyzeResultDto columns(List<AnalyzedColumnDto> columns) =>
      this(columns: columns);

  @override
  AnalyzeResultDto previewPngBase64(String previewPngBase64) =>
      this(previewPngBase64: previewPngBase64);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AnalyzeResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AnalyzeResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AnalyzeResultDto call({
    Object? columnCount = const $CopyWithPlaceholder(),
    Object? columns = const $CopyWithPlaceholder(),
    Object? previewPngBase64 = const $CopyWithPlaceholder(),
  }) {
    return AnalyzeResultDto(
      columnCount: columnCount == const $CopyWithPlaceholder()
          ? _value.columnCount
          // ignore: cast_nullable_to_non_nullable
          : columnCount as num,
      columns: columns == const $CopyWithPlaceholder()
          ? _value.columns
          // ignore: cast_nullable_to_non_nullable
          : columns as List<AnalyzedColumnDto>,
      previewPngBase64: previewPngBase64 == const $CopyWithPlaceholder()
          ? _value.previewPngBase64
          // ignore: cast_nullable_to_non_nullable
          : previewPngBase64 as String,
    );
  }
}

extension $AnalyzeResultDtoCopyWith on AnalyzeResultDto {
  /// Returns a callable class that can be used as follows: `instanceOfAnalyzeResultDto.copyWith(...)` or like so:`instanceOfAnalyzeResultDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AnalyzeResultDtoCWProxy get copyWith => _$AnalyzeResultDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalyzeResultDto _$AnalyzeResultDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AnalyzeResultDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['columnCount', 'columns', 'previewPngBase64'],
      );
      final val = AnalyzeResultDto(
        columnCount: $checkedConvert('columnCount', (v) => v as num),
        columns: $checkedConvert(
          'columns',
          (v) => (v as List<dynamic>)
              .map((e) => AnalyzedColumnDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        previewPngBase64: $checkedConvert(
          'previewPngBase64',
          (v) => v as String,
        ),
      );
      return val;
    });

Map<String, dynamic> _$AnalyzeResultDtoToJson(AnalyzeResultDto instance) =>
    <String, dynamic>{
      'columnCount': instance.columnCount,
      'columns': instance.columns.map((e) => e.toJson()).toList(),
      'previewPngBase64': instance.previewPngBase64,
    };
