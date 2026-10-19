//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recognition_batch_page_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecognitionBatchPageDto {
  /// Returns a new [RecognitionBatchPageDto] instance.
  RecognitionBatchPageDto({required this.page, required this.imageUrl});

  /// Số trang, từ 1
  @JsonKey(name: r'page', required: true, includeIfNull: false)
  final num page;

  /// URL ký 300 giây của ảnh trang; chuỗi rỗng khi lô đã hủy (ảnh đã bị xóa khỏi kho lưu trữ)
  @JsonKey(name: r'imageUrl', required: true, includeIfNull: false)
  final String imageUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecognitionBatchPageDto &&
          other.page == page &&
          other.imageUrl == imageUrl;

  @override
  int get hashCode => page.hashCode + imageUrl.hashCode;

  factory RecognitionBatchPageDto.fromJson(Map<String, dynamic> json) =>
      _$RecognitionBatchPageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RecognitionBatchPageDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
