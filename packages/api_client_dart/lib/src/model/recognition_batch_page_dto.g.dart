// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recognition_batch_page_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecognitionBatchPageDtoCWProxy {
  RecognitionBatchPageDto page(num page);

  RecognitionBatchPageDto imageUrl(String imageUrl);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecognitionBatchPageDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecognitionBatchPageDto(...).copyWith(id: 12, name: "My name")
  /// ````
  RecognitionBatchPageDto call({num page, String imageUrl});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecognitionBatchPageDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecognitionBatchPageDto.copyWith.fieldName(...)`
class _$RecognitionBatchPageDtoCWProxyImpl
    implements _$RecognitionBatchPageDtoCWProxy {
  const _$RecognitionBatchPageDtoCWProxyImpl(this._value);

  final RecognitionBatchPageDto _value;

  @override
  RecognitionBatchPageDto page(num page) => this(page: page);

  @override
  RecognitionBatchPageDto imageUrl(String imageUrl) => this(imageUrl: imageUrl);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecognitionBatchPageDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecognitionBatchPageDto(...).copyWith(id: 12, name: "My name")
  /// ````
  RecognitionBatchPageDto call({
    Object? page = const $CopyWithPlaceholder(),
    Object? imageUrl = const $CopyWithPlaceholder(),
  }) {
    return RecognitionBatchPageDto(
      page: page == const $CopyWithPlaceholder()
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as num,
      imageUrl: imageUrl == const $CopyWithPlaceholder()
          ? _value.imageUrl
          // ignore: cast_nullable_to_non_nullable
          : imageUrl as String,
    );
  }
}

extension $RecognitionBatchPageDtoCopyWith on RecognitionBatchPageDto {
  /// Returns a callable class that can be used as follows: `instanceOfRecognitionBatchPageDto.copyWith(...)` or like so:`instanceOfRecognitionBatchPageDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecognitionBatchPageDtoCWProxy get copyWith =>
      _$RecognitionBatchPageDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecognitionBatchPageDto _$RecognitionBatchPageDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecognitionBatchPageDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['page', 'imageUrl']);
  final val = RecognitionBatchPageDto(
    page: $checkedConvert('page', (v) => v as num),
    imageUrl: $checkedConvert('imageUrl', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$RecognitionBatchPageDtoToJson(
  RecognitionBatchPageDto instance,
) => <String, dynamic>{'page': instance.page, 'imageUrl': instance.imageUrl};
