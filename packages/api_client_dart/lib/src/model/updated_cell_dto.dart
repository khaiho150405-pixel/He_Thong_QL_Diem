//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'updated_cell_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdatedCellDto {
  /// Returns a new [UpdatedCellDto] instance.
  UpdatedCellDto({
    required this.id,

    required this.value,

    required this.status,

    required this.source_,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'value', required: true, includeIfNull: true)
  final String? value;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final UpdatedCellDtoStatusEnum status;

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final UpdatedCellDtoSource_Enum source_;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdatedCellDto &&
          other.id == id &&
          other.value == value &&
          other.status == status &&
          other.source_ == source_;

  @override
  int get hashCode =>
      id.hashCode +
      (value == null ? 0 : value.hashCode) +
      status.hashCode +
      source_.hashCode;

  factory UpdatedCellDto.fromJson(Map<String, dynamic> json) =>
      _$UpdatedCellDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatedCellDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum UpdatedCellDtoStatusEnum {
  @JsonValue(r'CHUA_CO')
  CHUA_CO(r'CHUA_CO'),
  @JsonValue(r'CHO_DOI_CHIEU')
  CHO_DOI_CHIEU(r'CHO_DOI_CHIEU'),
  @JsonValue(r'DA_DUYET')
  DA_DUYET(r'DA_DUYET');

  const UpdatedCellDtoStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum UpdatedCellDtoSource_Enum {
  @JsonValue(r'NHAP_TAY')
  NHAP_TAY(r'NHAP_TAY'),
  @JsonValue(r'NHAN_DIEN')
  NHAN_DIEN(r'NHAN_DIEN');

  const UpdatedCellDtoSource_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}
