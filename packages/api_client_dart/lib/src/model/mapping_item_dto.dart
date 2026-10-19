//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mapping_item_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MappingItemDto {
  /// Returns a new [MappingItemDto] instance.
  MappingItemDto({
    required this.templateColumnIndex,

    required this.key,

    required this.group,

    required this.order,

    required this.channels,

    required this.componentId,

    required this.componentName,

    required this.locked,

    required this.pending,
  });

  /// Chỉ số cột điểm trong mẫu
  @JsonKey(name: r'templateColumnIndex', required: true, includeIfNull: false)
  final num templateColumnIndex;

  /// Định danh cột điểm, ví dụ TX1
  @JsonKey(name: r'key', required: true, includeIfNull: false)
  final String key;

  @JsonKey(name: r'group', required: true, includeIfNull: false)
  final MappingItemDtoGroupEnum group;

  /// Thứ tự trong nhóm, từ 1
  @JsonKey(name: r'order', required: true, includeIfNull: false)
  final num order;

  /// SO = chỉ điểm số (tối đa Vàng); SO_CHU = đọc cả điểm số lẫn điểm chữ
  @JsonKey(name: r'channels', required: true, includeIfNull: false)
  final MappingItemDtoChannelsEnum channels;

  /// Thành phần điểm của môn khớp (nhóm, thứ tự); null khi môn không có thành phần tương ứng
  @JsonKey(name: r'componentId', required: true, includeIfNull: true)
  final num? componentId;

  @JsonKey(name: r'componentName', required: true, includeIfNull: true)
  final String? componentName;

  /// Cột đã chốt, ngoài thời gian nhập, bảng đã chốt hoặc môn Đạt/Không đạt: không chọn được
  @JsonKey(name: r'locked', required: true, includeIfNull: false)
  final bool locked;

  /// Đang có phiếu chờ xử lý/đối chiếu: không chọn được
  @JsonKey(name: r'pending', required: true, includeIfNull: false)
  final bool pending;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MappingItemDto &&
          other.templateColumnIndex == templateColumnIndex &&
          other.key == key &&
          other.group == group &&
          other.order == order &&
          other.channels == channels &&
          other.componentId == componentId &&
          other.componentName == componentName &&
          other.locked == locked &&
          other.pending == pending;

  @override
  int get hashCode =>
      templateColumnIndex.hashCode +
      key.hashCode +
      group.hashCode +
      order.hashCode +
      channels.hashCode +
      (componentId == null ? 0 : componentId.hashCode) +
      (componentName == null ? 0 : componentName.hashCode) +
      locked.hashCode +
      pending.hashCode;

  factory MappingItemDto.fromJson(Map<String, dynamic> json) =>
      _$MappingItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MappingItemDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum MappingItemDtoGroupEnum {
  @JsonValue(r'TX')
  TX(r'TX'),
  @JsonValue(r'GK')
  GK(r'GK'),
  @JsonValue(r'CK')
  CK(r'CK');

  const MappingItemDtoGroupEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

/// SO = chỉ điểm số (tối đa Vàng); SO_CHU = đọc cả điểm số lẫn điểm chữ
enum MappingItemDtoChannelsEnum {
  /// SO = chỉ điểm số (tối đa Vàng); SO_CHU = đọc cả điểm số lẫn điểm chữ
  @JsonValue(r'SO')
  SO(r'SO'),

  /// SO = chỉ điểm số (tối đa Vàng); SO_CHU = đọc cả điểm số lẫn điểm chữ
  @JsonValue(r'SO_CHU')
  SO_CHU(r'SO_CHU');

  const MappingItemDtoChannelsEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
